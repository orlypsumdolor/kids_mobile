import '../entities/attendance_record_entry.dart';

abstract class AttendanceRepository {
  Future<AttendanceSummary> getAttendanceReport({required DateTime date});
}
