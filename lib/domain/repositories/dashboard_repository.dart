import '../entities/service_attendance_stat.dart';

abstract class DashboardRepository {
  Future<List<ServiceAttendanceStat>> getServiceStats();
}
