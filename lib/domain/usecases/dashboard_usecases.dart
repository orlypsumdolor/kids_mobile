import '../entities/service_attendance_stat.dart';
import '../repositories/dashboard_repository.dart';

class GetServiceStatsUseCase {
  final DashboardRepository _repository;

  GetServiceStatsUseCase(this._repository);

  Future<List<ServiceAttendanceStat>> call() async {
    return await _repository.getServiceStats();
  }
}
