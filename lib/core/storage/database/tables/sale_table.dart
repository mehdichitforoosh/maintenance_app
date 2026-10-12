class SaleTable {
  static const String tableName = 'sales';

  // Columns
  static const String id = 'id';
  static const String date = 'date';
  static const String totalAmount = 'total_amount';
  static const String discount = 'discount';
  static const String finalAmount = 'final_amount';
  static const String paymentMethod = 'payment_method';
  static const String note = 'note';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // SQL
  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $date TEXT NOT NULL,
      $totalAmount INTEGER NOT NULL DEFAULT 0,
      $discount INTEGER NOT NULL DEFAULT 0,
      $finalAmount INTEGER NOT NULL DEFAULT 0,
      $paymentMethod TEXT NOT NULL,
      $note TEXT,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT
    )
  ''';
}
