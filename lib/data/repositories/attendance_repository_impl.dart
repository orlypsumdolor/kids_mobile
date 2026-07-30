import '../../domain/entities/attendance_record_entry.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/remote/api_service.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final ApiService _apiService;

  AttendanceRepositoryImpl({required ApiService apiService})
      : _apiService = apiService;

  @override
  Future<AttendanceSummary> getAttendanceReport({required DateTime date}) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay =
          DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      final response = await _apiService.getAttendanceReport(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'];
        final summary = data['summary'] ?? {};
        final List<dynamic> rawRecords = data['records'] ?? [];

        final records = rawRecords.map((json) {
          final child = json['childId'];
          final service = json['serviceId'];
          final guardians =
              child is Map && child['guardianIds'] is List
                  ? child['guardianIds'] as List
                  : const [];
          final guardian = guardians.isNotEmpty ? guardians.first : null;
          return AttendanceRecordEntry(
            id: json['_id']?.toString() ?? '',
            childName:
                (child is Map ? child['fullName'] : null)?.toString() ??
                    'Unknown child',
            ageGroup: (child is Map ? child['ageGroup'] : null)?.toString() ?? '',
            guardianName:
                (guardian is Map ? guardian['fullName'] : null)?.toString() ??
                    'Guardian',
            serviceName:
                (service is Map ? service['name'] : null)?.toString() ?? '',
            checkInTime: DateTime.parse(json['checkInTime']),
            checkOutTime: json['checkOutTime'] != null
                ? DateTime.parse(json['checkOutTime'])
                : null,
          );
        }).toList();

        return AttendanceSummary(
          totalSessions: (summary['totalSessions'] as num?)?.toInt() ?? 0,
          activeSessions: (summary['activeSessions'] as num?)?.toInt() ?? 0,
          completedSessions:
              (summary['completedSessions'] as num?)?.toInt() ?? 0,
          records: records,
        );
      }

      return AttendanceSummary.empty;
    } catch (e) {
      throw Exception('Failed to fetch attendance report: $e');
    }
  }
}
