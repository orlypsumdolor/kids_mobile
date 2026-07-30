import 'package:flutter/foundation.dart';
import '../../domain/entities/service_attendance_stat.dart';
import '../../domain/usecases/dashboard_usecases.dart';

class DashboardProvider extends ChangeNotifier {
  final GetServiceStatsUseCase _getServiceStatsUseCase;

  DashboardProvider({
    required GetServiceStatsUseCase getServiceStatsUseCase,
  }) : _getServiceStatsUseCase = getServiceStatsUseCase;

  List<ServiceAttendanceStat> _serviceStats = [];
  String? _error;

  List<ServiceAttendanceStat> get serviceStats => _serviceStats;
  String? get error => _error;

  ServiceAttendanceStat? statsFor(String serviceId) {
    for (final stat in _serviceStats) {
      if (stat.serviceId == serviceId) return stat;
    }
    return null;
  }

  Future<void> loadServiceStats() async {
    try {
      _serviceStats = await _getServiceStatsUseCase();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }
}
