import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/operational_report.dart';
import '../repositories/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(dbHelper: ref.watch(databaseHelperProvider));
});

typedef ReportRequest = ({
  String facilityId,
  DateTime start,
  DateTime endExclusive,
});

final operationalReportProvider =
    FutureProvider.family<OperationalReport, ReportRequest>((ref, request) {
      return ref
          .watch(reportRepositoryProvider)
          .getOperationalReport(
            facilityId: request.facilityId,
            start: request.start,
            endExclusive: request.endExclusive,
          );
    });
