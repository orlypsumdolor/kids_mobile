import '../../domain/entities/service_session.dart';
import '../../domain/repositories/service_repository.dart';
import '../datasources/remote/api_service.dart';
import '../models/service_session_model.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ApiService _apiService;

  ServiceRepositoryImpl({
    required ApiService apiService,
  }) : _apiService = apiService;

  @override
  Future<List<ServiceSession>> getServiceSessions() async {
    try {
      final response = await _apiService.getServices();

      print('API Response status: ${response.statusCode}');
      print('API Response data type: ${response.data.runtimeType}');
      print('API Response data: ${response.data}');

      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'];
        if (data['services'] == null) {
          print('Error: services field is null in response data');
          throw Exception('Invalid data structure: services field is missing');
        }

        final List<dynamic> servicesData = data['services'];

        // Add logging to debug the response structure
        print('Services data received: ${servicesData.length} services');
        if (servicesData.isNotEmpty) {
          print('First service data: ${servicesData.first}');
        }

        return servicesData.map((json) {
          try {
            // Validate that each item is a Map
            if (json is! Map<String, dynamic>) {
              print('Error: service item is not a Map: ${json.runtimeType}');
              throw Exception('Invalid service data structure');
            }
            return ServiceSessionModel.fromJson(json).toEntity();
          } catch (e) {
            print('Error parsing service: $e');
            print('Service JSON: $json');
            rethrow;
          }
        }).toList();
      }

      return [];
    } catch (e) {
      print('Repository error: $e');
      throw Exception('Failed to fetch service sessions: $e');
    }
  }

  @override
  Future<ServiceSession?> getServiceSessionById(String id) async {
    try {
      final response = await _apiService.getServiceById(id);

      if (response.data['success'] == true && response.data['data'] != null) {
        final serviceData = response.data['data']['service'];
        return ServiceSessionModel.fromJson(serviceData).toEntity();
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch service session: $e');
    }
  }
}
