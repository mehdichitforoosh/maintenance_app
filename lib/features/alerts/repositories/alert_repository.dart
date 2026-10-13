import '../../../core/enums/app_enums.dart';
import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/alert_event_table.dart';
import '../../../core/utils/date_utils.dart';
import '../models/alert_event.dart';

class AlertRepository {
  static const String _tableName = AlertEventTable.tableName;
  final DatabaseHelper _dbHelper;

  AlertRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<AlertEvent>> getAlerts(String facilityId, {AlertStatus? status, AlertSeverity? severity}) async {
    final db = await _dbHelper.db;
    var where = '${AlertEventTable.facilityId} = ? AND ${AlertEventTable.deletedAt} IS NULL';
    var args = <dynamic>[facilityId];

    if (status != null) {
      where += ' AND ${AlertEventTable.status} = ?';
      args.add(status.toDbString());
    }
    if (severity != null) {
      where += ' AND ${AlertEventTable.severity} = ?';
      args.add(severity.toDbString());
    }

    final results = await db.query(_tableName, where: where, whereArgs: args, orderBy: '${AlertEventTable.triggeredAt} DESC');
    return results.map((m) => AlertEvent.fromMap(m)).toList();
  }

  Future<void> updateAlertStatus(String alertId, AlertStatus newStatus) async {
    final db = await _dbHelper.db;
    final nowIso = AppDateUtils.nowUtcIso();
    final updates = <String, dynamic>{
      AlertEventTable.status: newStatus.toDbString(),
      AlertEventTable.updatedAt: nowIso,
    };
    if (newStatus == AlertStatus.acknowledged) {
      updates[AlertEventTable.acknowledgedAt] = nowIso;
    } else if (newStatus == AlertStatus.resolved) {
      updates[AlertEventTable.resolvedAt] = nowIso;
    }

    await db.update(_tableName, updates, where: '${AlertEventTable.id} = ?', whereArgs: [alertId]);
  }
}
