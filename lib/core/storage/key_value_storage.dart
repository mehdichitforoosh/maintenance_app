import 'package:sqflite/sqflite.dart';
import 'database/database_helper.dart';

class KeyValueStorage {
  static final KeyValueStorage instance = KeyValueStorage._instance();

  KeyValueStorage._instance();

  static const String _tableName = 'app_settings';
  static final Map<String, String> _cache = {};

  static Future<void> initialize() async {
    final db = await DatabaseHelper.instance.db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    final List<Map<String, dynamic>> records = await db.query(_tableName);
    for (var r in records) {
      _cache[r['key'] as String] = r['value'] as String;
    }
  }

  bool getBool(String key, {bool defaultValue = false}) {
    final val = _cache[key];
    if (val == null) return defaultValue;
    return val == 'true';
  }

  Future<void> setBool(String key, bool value) async {
    _cache[key] = value.toString();
    final db = await DatabaseHelper.instance.db;
    await db.insert(
      _tableName,
      {'key': key, 'value': value.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String? getString(String key) => _cache[key];

  Future<void> setString(String key, String value) async {
    _cache[key] = value;
    final db = await DatabaseHelper.instance.db;
    await db.insert(
      _tableName,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // App Specific Keys
  static const String _keyIsFirstRun = 'is_first_run';
  static const String _keyThemeMode = 'theme_mode';

  bool get isFirstRun => getBool(_keyIsFirstRun, defaultValue: true);
  Future<void> setOnboardingCompleted() async =>
      setBool(_keyIsFirstRun, false);

  String get themeModeName => getString(_keyThemeMode) ?? 'system';
  Future<void> setThemeModeName(String name) async =>
      setString(_keyThemeMode, name);
}
