import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/alert_event_table.dart';
import '../../../core/storage/database/tables/asset_reading_table.dart';
import '../../../core/storage/database/tables/asset_table.dart';
import '../../../core/storage/database/tables/facility_table.dart';
import '../../../core/storage/database/tables/inventory_item_table.dart';
import '../../../core/storage/database/tables/location_table.dart';
import '../../../core/storage/database/tables/maintenance_plan_material_table.dart';
import '../../../core/storage/database/tables/maintenance_plan_table.dart';
import '../../../core/storage/database/tables/purchase_order_item_table.dart';
import '../../../core/storage/database/tables/purchase_order_table.dart';
import '../../../core/storage/database/tables/stock_transaction_table.dart';
import '../../../core/storage/database/tables/work_order_material_table.dart';
import '../../../core/storage/database/tables/work_order_table.dart';
import '../../../core/storage/database/tables/work_order_task_event_table.dart';
import '../../../core/storage/database/tables/work_order_task_table.dart';

class BackupRepository {
  static const String _appName = 'maintenance_app';
  static const int _backupVersion = 1;

  static const List<String> _tableNames = [
    FacilityTable.tableName,
    LocationTable.tableName,
    AssetTable.tableName,
    MaintenancePlanTable.tableName,
    AssetReadingTable.tableName,
    InventoryItemTable.tableName,
    MaintenancePlanMaterialTable.tableName,
    WorkOrderTable.tableName,
    WorkOrderTaskTable.tableName,
    WorkOrderTaskEventTable.tableName,
    WorkOrderMaterialTable.tableName,
    PurchaseOrderTable.tableName,
    PurchaseOrderItemTable.tableName,
    StockTransactionTable.tableName,
    AlertEventTable.tableName,
  ];

  /// Exports all SQLite tables into a formatted JSON string
  Future<String> exportBackupJson() async {
    final db = await DatabaseHelper.instance.db;
    final Map<String, dynamic> backupData = {
      'app': _appName,
      'version': _backupVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'tables': <String, dynamic>{},
    };

    final Map<String, dynamic> tables = {};
    for (var tableName in _tableNames) {
      final rows = await db.query(tableName);
      tables[tableName] = rows;
    }

    backupData['tables'] = tables;
    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  /// Exports backup JSON directly to a .json file on local device storage
  Future<File?> exportBackupToFile() async {
    final jsonStr = await exportBackupJson();

    if (kIsWeb) {
      return null;
    }

    Directory? dir;

    try {
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        dir = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }

    dir ??= await getApplicationDocumentsDirectory();

    final now = DateTime.now();
    final fileName =
        'cmms_backup_${now.year}_${now.month}_${now.day}_${now.hour}${now.minute}.json';
    final file = File('${dir.path}/$fileName');

    return await file.writeAsString(jsonStr);
  }

  /// Shares the generated backup .json file via system share sheet (Telegram, WhatsApp, Email, Drive, Gmail, etc.)
  Future<void> shareBackupFile() async {
    final jsonStr = await exportBackupJson();

    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(
          text: jsonStr,
          subject: 'پشتیبان دیتابیس نرم‌افزار نگهداری و تعمیرات',
        ),
      );
      return;
    }

    final file = await exportBackupToFile();
    if (file != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'فایل پشتیبان داده‌های نرم‌افزار نگهداری و تعمیرات (CMMS)',
          subject: 'پشتیبان دیتابیس CMMS',
        ),
      );
    }
  }

  /// Opens the native system File Picker to select a .json backup file and imports it
  Future<bool> pickAndImportBackupFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (files.isNotEmpty && files.first.path != null) {
        final path = files.first.path!;
        await importBackupFromFile(path);
        return true;
      }
    } catch (_) {
      final files = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (files.isNotEmpty && files.first.path != null) {
        final path = files.first.path!;
        await importBackupFromFile(path);
        return true;
      }
    }
    return false;
  }

  /// Imports and restores database from a JSON file path
  Future<void> importBackupFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FileSystemException('فایل انتخابی در این مسیر یافت نشد.');
    }
    final content = await file.readAsString();
    await importBackupJson(content);
  }

  /// Imports and replaces all SQLite data from a JSON string inside a single atomic transaction
  Future<void> importBackupJson(String jsonString) async {
    final Map<String, dynamic> decoded = json.decode(jsonString);

    final appName = decoded['app'] as String?;
    if (appName != _appName && appName != 'cmms_maintenance') {
      throw const FormatException('فایل انتخابی متعلق به این برنامه نیست.');
    }

    final tablesData = decoded['tables'] as Map<String, dynamic>?;
    if (tablesData == null) {
      throw const FormatException('ساختار فایل پشتیبان معتبر نیست.');
    }

    final db = await DatabaseHelper.instance.db;

    await db.transaction((txn) async {
      // 1. Temporarily disable foreign keys for clean table reset
      await txn.execute('PRAGMA foreign_keys = OFF');

      // 2. Clear existing tables in reverse dependency order
      for (var tableName in _tableNames.reversed) {
        await txn.delete(tableName);
      }

      // 3. Insert rows into tables in forward dependency order
      for (var tableName in _tableNames) {
        final rowsList = tablesData[tableName] as List<dynamic>?;
        if (rowsList != null) {
          for (var row in rowsList) {
            if (row is Map<String, dynamic>) {
              await txn.insert(tableName, row);
            }
          }
        }
      }

      // 4. Re-enable foreign keys
      await txn.execute('PRAGMA foreign_keys = ON');
    });
  }
}
