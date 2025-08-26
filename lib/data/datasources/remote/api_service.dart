import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/constants/api_constants.dart';
import '../../../domain/entities/guardian.dart';

class ApiService {
  late final Dio _dio;
  String? _authToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Handle token refresh or logout
          _authToken = null;
        }
        handler.next(error);
      },
    ));
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Auth endpoints
  Future<Response> login(String username, String password) async {
    return await _dio.post(ApiConstants.login, data: {
      'username': username,
      'password': password,
    });
  }

  Future<Response> getCurrentUser() async {
    return await _dio.get(ApiConstants.me);
  }

  Future<Response> refreshToken() async {
    return await _dio.post(ApiConstants.refresh);
  }

  // Children endpoints
  Future<Response> getChildren({
    int page = 1,
    int limit = 50,
    String? search,
    bool? isActive,
    String? ageGroup,
    String? guardianId,
  }) async {
    return await _dio.get(ApiConstants.children, queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
      if (isActive != null) 'isActive': isActive,
      if (ageGroup != null) 'ageGroup': ageGroup,
      if (guardianId != null) 'guardian': guardianId,
    });
  }

  Future<Response> getChildById(String id) async {
    return await _dio.get(ApiConstants.childById(id));
  }

  Future<Response> getChildByQrCode(String qrCode) async {
    return await _dio.get(ApiConstants.searchChildrenByQr(qrCode));
  }

  Future<Response> getChildByRfidCode(String rfidCode) async {
    return await _dio.get(ApiConstants.searchChildrenByRfid(rfidCode));
  }

  // Attendance endpoints
  Future<Response> checkInChild({
    required String childId,
    required String serviceSessionId,
    String? notes,
  }) async {
    return await _dio.post(ApiConstants.checkin, data: {
      'childId': childId,
      'serviceSessionId': serviceSessionId,
      if (notes != null) 'notes': notes,
    });
  }

  Future<Response> checkOutChild({
    required String recordId,
    String? pickupCode,
    String? notes,
  }) async {
    return await _dio.post(ApiConstants.checkout(recordId), data: {
      if (pickupCode != null) 'pickupCode': pickupCode,
      if (notes != null) 'notes': notes,
    });
  }

  Future<Response> getActiveAttendance() async {
    return await _dio.get(ApiConstants.activeAttendance);
  }

  Future<Response> getAttendanceStats() async {
    return await _dio.get(ApiConstants.attendanceStats);
  }

  Future<Response> getChildAttendanceHistory(
    String childId, {
    int page = 1,
    int limit = 20,
  }) async {
    return await _dio
        .get(ApiConstants.childAttendance(childId), queryParameters: {
      'page': page,
      'limit': limit,
    });
  }

  // Service endpoints
  Future<Response> getServices({
    int page = 1,
    int limit = 50,
    bool? isActive,
    String? dayOfWeek,
  }) async {
    return await _dio.get(ApiConstants.services, queryParameters: {
      'page': page,
      'limit': limit,
      if (isActive != null) 'isActive': isActive,
      if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
    });
  }

  Future<Response> getServiceById(String id) async {
    return await _dio.get(ApiConstants.serviceById(id));
  }

  // Reports endpoints
  Future<Response> getAttendanceReport({
    DateTime? startDate,
    DateTime? endDate,
    String? serviceId,
    String? childId,
    String? status,
  }) async {
    return await _dio.get(ApiConstants.reportsAttendance, queryParameters: {
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
      if (serviceId != null) 'serviceSessionId': serviceId,
      if (childId != null) 'childId': childId,
      if (status != null) 'status': status,
    });
  }

  Future<Response> getDashboardData() async {
    return await _dio.get(ApiConstants.reportsDashboard);
  }

  // Health check
  Future<Response> healthCheck() async {
    return await _dio.get(ApiConstants.health);
  }

  // Guardian endpoints
  Future<Response> getGuardianByQrCode(String qrCode) async {
    return await _dio.get(ApiConstants.searchGuardiansByQr(qrCode));
  }

  Future<Response> getGuardianByRfidTag(String rfidTag) async {
    return await _dio.get(ApiConstants.searchGuardiansByRfid(rfidTag));
  }

  Future<Response> getGuardianWithChildren(String guardianId) async {
    return await _dio.get(ApiConstants.guardianChildren(guardianId));
  }

  Future<Response> getGuardianById(String guardianId) async {
    return await _dio.get(ApiConstants.guardianById(guardianId));
  }

  Future<Response> linkChildToGuardian(
      String guardianId, String childId) async {
    return await _dio.post(ApiConstants.linkChildToGuardian(guardianId), data: {
      'childId': childId,
    });
  }

  Future<Response> unlinkChildFromGuardian(
      String guardianId, String childId) async {
    return await _dio
        .delete(ApiConstants.unlinkChildFromGuardian(guardianId, childId));
  }

  Future<Response> createGuardian(Guardian guardian) async {
    return await _dio.post(ApiConstants.guardians, data: guardian);
  }

  Future<Response> updateGuardian(Guardian guardian) async {
    return await _dio.put(ApiConstants.guardianById(guardian.id),
        data: guardian);
  }

  Future<Response> getAllGuardians() async {
    return await _dio.get(ApiConstants.guardians);
  }

  // Guardian-based attendance endpoints
  Future<Response> checkInChildren({
    required String guardianId,
    required String serviceId,
    required List<String> childIds,
  }) async {
    return await _dio.post(ApiConstants.guardianCheckin, data: {
      'guardianId': guardianId,
      'serviceId': serviceId,
      'childIds': childIds,
    });
  }

  Future<Response> checkOutChildren({
    required String guardianId,
    required List<String> childIds,
  }) async {
    return await _dio.post(ApiConstants.guardianCheckout, data: {
      'guardianId': guardianId,
      'childIds': childIds,
    });
  }

  Future<Response> getGuardianCurrentCheckins(String guardianId) async {
    return await _dio.get(ApiConstants.guardianCurrentCheckins(guardianId));
  }

  // Helper method to extract data from API response
  Map<String, dynamic>? extractData(Response response) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return data['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  // Helper method to extract success status from API response
  bool isSuccess(Response response) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return data['success'] == true;
    }
    return false;
  }

  // Helper method to extract message from API response
  String? getMessage(Response response) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return data['message'] as String?;
    }
    return null;
  }
}
