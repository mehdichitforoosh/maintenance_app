import '../../../core/enums/app_enums.dart';
import '../../../core/storage/database/database_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../models/alert_event.dart';

class AlertRepository {
  final DatabaseHelper _dbHelper;

  AlertRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<AlertEvent>> getAlerts(String facilityId, {AlertStatus? status, AlertSeverity? severity}) async {
    final db = await _dbHelper.db;
    var where = 'facility_id = ? AND deleted_at IS NULL';
    var args = <dynamic>[facilityId];

    if (status != null) {
      where += ' AND status = ?';
      args.add(status.toDbString());
    }
    if (severity != null) {
      where += ' AND severity = ?';
      args.add(severity.toDbString());
    }

    final results = await db.query('alert_events', where: where, whereArgs: args, orderBy: 'triggered_at DESC');
    return results.map((m) => AlertEvent.fromMap(m)).toList();
  }

  Future<void> updateAlertStatus(String alertId, AlertStatus newStatus) async {
    final db = await _dbHelper.db;
    final nowIso = AppDateUtils.nowUtcIso();
    final updates = <String, dynamic>{
      'status': newStatus.toDbString(),
      'updated_at': nowIso,
    };
    if (newStatus == AlertStatus.acknowledged) {
      updates['acknowledged_at'] = nowIso;
    } else if (newStatus == AlertStatus.resolved) {
      updates['resolved_at'] = nowIso;
    }

    await db.update('alert_events', updates, where: 'id = ?', whereArgs: [alertId]);
  }
}
