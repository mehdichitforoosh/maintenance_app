import 'package:sqflite/sqflite.dart';

import '../tables/asset_reading_table.dart';

class DatabaseMigrations {
  const DatabaseMigrations._();

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await _addColumnIfMissing(
        db,
        AssetReadingTable.tableName,
        AssetReadingTable.supersededByReadingId,
        'TEXT REFERENCES ${AssetReadingTable.tableName}(${AssetReadingTable.id})',
      );
      await _addColumnIfMissing(
        db,
        AssetReadingTable.tableName,
        AssetReadingTable.correctionReason,
        'TEXT',
      );
    }
  }

  static Future<void> _addColumnIfMissing(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.any((row) => row['name'] == column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }
}
