import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'tables/business_table.dart';
import 'tables/category_table.dart';
import 'tables/expense_table.dart';
import 'tables/material_table.dart';
import 'tables/product_table.dart';
import 'tables/purchase_item_table.dart';
import 'tables/purchase_table.dart';
import 'tables/recipe_item_table.dart';
import 'tables/sale_item_table.dart';
import 'tables/sale_table.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._instance();
  DatabaseHelper._instance();

  static const String _databaseName = 'accounting_shop.db';
  static const int _databaseVersion = 1;

  static Database? _database;

  Future<Database> get db async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> initialize({bool inMemory = false}) async {
    if (!inMemory) {
      return await db;
    }

    _configureDatabaseFactory();
    await _closeDatabase();
    _database = await _openDatabase(inMemoryDatabasePath);
    return _database!;
  }

  Future<Database> _initDatabase() async {
    _configureDatabaseFactory();

    var databasePath = await getDatabasesPath();
    var path = join(databasePath, _databaseName);
    return await _openDatabase(path);
  }

  void _configureDatabaseFactory() {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<void> _closeDatabase() async {
    if (_database == null || !_database!.isOpen) {
      return;
    }

    await _database!.close();
    _database = null;
  }

  Future<Database> _openDatabase(String path) async {
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: _onCreate,
        onConfigure: _onConfigure,
      ),
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(BusinessTable.createTable);
    await db.execute(CategoryTable.createTable);
    await db.execute(CategoryTable.createNameTypeIndex);
    await db.execute(ProductTable.createTable);
    await db.execute(ProductTable.createCategoryIndex);
    await db.execute(SaleTable.createTable);
    await db.execute(SaleItemTable.createTable);
    await db.execute(SaleItemTable.createSaleIndex);
    await db.execute(PurchaseTable.createTable);
    await db.execute(PurchaseItemTable.createTable);
    await db.execute(PurchaseItemTable.createPurchaseIndex);
    await db.execute(ExpenseTable.createTable);
    await db.execute(ExpenseTable.createCategoryIndex);
    await db.execute(MaterialTable.createTable);
    await db.execute(RecipeItemTable.createTable);
    await db.execute(RecipeItemTable.createProductIndex);
  }
}
