import '../../domain/entities/service_attendance_stat.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/remote/api_service.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final ApiService _apiService;

  DashboardRepositoryImpl({required ApiService apiService})
      : _apiService = apiService;

  @override
  Future<List<ServiceAttendanceStat>> getServiceStats() async {
    try {
      final response = await _apiService.getDashboardData();

      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'];
        final List<dynamic> serviceStats = data['serviceStats'] ?? [];

        return serviceStats.map((json) {
          final id = json['_id'];
          return ServiceAttendanceStat(
            serviceId: id?.toString() ?? '',
            totalToday: (json['count'] as num?)?.toInt() ?? 0,
            stillHere: (json['checkedIn'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch dashboard data: $e');
    }
  }
}
