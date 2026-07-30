import 'package:flutter/foundation.dart';
import '../../domain/entities/attendance_record_entry.dart';
import '../../domain/usecases/attendance_usecases.dart';

class AttendanceProvider extends ChangeNotifier {
  final GetAttendanceReportUseCase _getAttendanceReportUseCase;

  AttendanceProvider({
    required GetAttendanceReportUseCase getAttendanceReportUseCase,
  }) : _getAttendanceReportUseCase = getAttendanceReportUseCase;

  AttendanceSummary _summary = AttendanceSummary.empty;
  bool _isLoading = false;
  String? _error;

  AttendanceSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAttendance(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      _summary = await _getAttendanceReportUseCase(date: date);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
