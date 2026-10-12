class PurchaseTable {
  static const String tableName = 'purchases';

  // Columns
  static const String id = 'id';
  static const String date = 'date';
  static const String totalAmount = 'total_amount';
  static const String paymentMethod = 'payment_method';
  static const String supplierName = 'supplier_name';
  static const String note = 'note';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // SQL
  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $date TEXT NOT NULL,
      $totalAmount INTEGER NOT NULL DEFAULT 0,
      $paymentMethod TEXT NOT NULL,
      $supplierName TEXT,
      $note TEXT,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT
    )
  ''';
}
