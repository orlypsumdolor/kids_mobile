import '../entities/attendance_record_entry.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceReportUseCase {
  final AttendanceRepository _repository;

  GetAttendanceReportUseCase(this._repository);

  Future<AttendanceSummary> call({required DateTime date}) async {
    return await _repository.getAttendanceReport(date: date);
  }
}
