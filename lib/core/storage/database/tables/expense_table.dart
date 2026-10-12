import 'category_table.dart';

class ExpenseTable {
  static const String tableName = 'expenses';

  // Columns
  static const String id = 'id';
  static const String categoryId = 'category_id';
  static const String amount = 'amount';
  static const String date = 'date';
  static const String description = 'description';
  static const String paymentMethod = 'payment_method';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // SQL
  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $categoryId TEXT NOT NULL,
      $amount INTEGER NOT NULL DEFAULT 0,
      $date TEXT NOT NULL,
      $description TEXT,
      $paymentMethod TEXT NOT NULL,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT,
      FOREIGN KEY ($categoryId) REFERENCES ${CategoryTable.tableName}(${CategoryTable.id})
    )
  ''';

  static const String createCategoryIndex = '''
    CREATE INDEX idx_expenses_category ON $tableName($categoryId)
  ''';
}
