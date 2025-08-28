import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_response_handler.dart';
import '../../../data/models/api_error_model.dart';
import '../../../domain/entities/guardian.dart';

/// Enhanced API Service with comprehensive error handling for all endpoints
class EnhancedApiService {
  late final Dio _dio;
  String? _authToken;

  EnhancedApiService() {
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

  // ============================================================================
  // AUTHENTICATION ENDPOINTS
  // ============================================================================

  /// Enhanced login with error handling
  Future<Map<String, dynamic>?> loginEnhanced(
      String username, String password) async {
    try {
      final response = await _dio.post(ApiConstants.login, data: {
        'username': username,
        'password': password,
      });

      if (ApiResponseHandler.isSuccessResponse(response)) {
        final data = ApiResponseHandler.handleSuccessResponse(response);
        if (data != null && data['token'] != null) {
          setAuthToken(data['token']);
        }
        return data;
      } else {
        throw Exception(
            'Login failed: ${ApiResponseHandler.getSuccessMessage(response)}');
      }
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isAuthenticationError) {
        throw Exception(
            'Invalid credentials. Please check your username and password.');
      }
      rethrow;
    }
  }

  /// Original login method for backward compatibility
  Future<Response> login(String username, String password) async {
    return await _dio.post(ApiConstants.login, data: {
      'username': username,
      'password': password,
    });
  }

  /// Enhanced get current user with error handling
  Future<Map<String, dynamic>?> getCurrentUserEnhanced() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isAuthenticationError) {
        throw Exception('Please log in to continue');
      }
      rethrow;
    }
  }

  /// Original get current user method
  Future<Response> getCurrentUser() async {
    return await _dio.get(ApiConstants.me);
  }

  /// Enhanced refresh token with error handling
  Future<Map<String, dynamic>?> refreshTokenEnhanced() async {
    try {
      final response = await _dio.post(ApiConstants.refresh);
      final data = ApiResponseHandler.handleSuccessResponse(response);
      if (data != null && data['token'] != null) {
        setAuthToken(data['token']);
      }
      return data;
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isAuthenticationError) {
        clearAuthToken();
        throw Exception('Session expired. Please log in again.');
      }
      rethrow;
    }
  }

  /// Original refresh token method
  Future<Response> refreshToken() async {
    return await _dio.post(ApiConstants.refresh);
  }

  // ============================================================================
  // CHILDREN ENDPOINTS
  // ============================================================================

  /// Enhanced get children with error handling and pagination
  Future<Map<String, dynamic>?> getChildrenEnhanced({
    int page = 1,
    int limit = 50,
    String? search,
    bool? isActive,
    String? ageGroup,
    String? guardianId,
  }) async {
    try {
      final response = await _dio.get(ApiConstants.children, queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null) 'search': search,
        if (isActive != null) 'isActive': isActive,
        if (ageGroup != null) 'ageGroup': ageGroup,
        if (guardianId != null) 'guardian': guardianId,
      });

      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('No children found with the specified criteria.');
      }
      rethrow;
    }
  }

  /// Original get children method
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

  /// Enhanced get child by ID with error handling
  Future<Map<String, dynamic>?> getChildByIdEnhanced(String id) async {
    try {
      final response = await _dio.get(ApiConstants.childById(id));
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('Child not found. Please check the ID.');
      }
      rethrow;
    }
  }

  /// Original get child by ID method
  Future<Response> getChildById(String id) async {
    return await _dio.get(ApiConstants.childById(id));
  }

  /// Enhanced get child by QR code with error handling
  Future<Map<String, dynamic>?> getChildByQrCodeEnhanced(String qrCode) async {
    try {
      final response = await _dio.get(ApiConstants.searchChildrenByQr(qrCode));
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('No child found with this QR code.');
      }
      rethrow;
    }
  }

  /// Original get child by QR code method
  Future<Response> getChildByQrCode(String qrCode) async {
    return await _dio.get(ApiConstants.searchChildrenByQr(qrCode));
  }

  /// Enhanced get child by RFID code with error handling
  Future<Map<String, dynamic>?> getChildByRfidCodeEnhanced(
      String rfidCode) async {
    try {
      final response =
          await _dio.get(ApiConstants.searchChildrenByRfid(rfidCode));
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('No child found with this RFID code.');
      }
      rethrow;
    }
  }

  /// Original get child by RFID code method
  Future<Response> getChildByRfidCode(String rfidCode) async {
    return await _dio.get(ApiConstants.searchChildrenByRfid(rfidCode));
  }

  // ============================================================================
  // ATTENDANCE ENDPOINTS
  // ============================================================================

  /// Enhanced check-in child with error handling
  Future<Map<String, dynamic>?> checkInChildEnhanced({
    required String childId,
    required String serviceSessionId,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.checkin, data: {
        'childId': childId,
        'serviceSessionId': serviceSessionId,
        if (notes != null) 'notes': notes,
      });

      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isValidationError) {
        throw Exception('Please check the child ID and service session ID.');
      }
      if (errorResponse.isDuplicateError) {
        throw Exception('Child is already checked in for this service.');
      }
      rethrow;
    }
  }

  /// Original check-in child method
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

  /// Enhanced check-out child with error handling
  Future<Map<String, dynamic>?> checkOutChildEnhanced({
    required String recordId,
    String? pickupCode,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.checkout(recordId), data: {
        if (pickupCode != null) 'pickupCode': pickupCode,
        if (notes != null) 'notes': notes,
      });

      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isValidationError) {
        throw Exception('Please check the pickup code and record ID.');
      }
      if (errorResponse.isNotFoundError) {
        throw Exception('Attendance record not found.');
      }
      rethrow;
    }
  }

  /// Original check-out child method
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

  /// Enhanced get active attendance with error handling
  Future<Map<String, dynamic>?> getActiveAttendanceEnhanced() async {
    try {
      final response = await _dio.get(ApiConstants.activeAttendance);
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('No active attendance records found.');
      }
      rethrow;
    }
  }

  /// Original get active attendance method
  Future<Response> getActiveAttendance() async {
    return await _dio.get(ApiConstants.activeAttendance);
  }

  /// Enhanced get attendance stats with error handling
  Future<Map<String, dynamic>?> getAttendanceStatsEnhanced() async {
    try {
      final response = await _dio.get(ApiConstants.attendanceStats);
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('No attendance statistics available.');
      }
      rethrow;
    }
  }

  /// Original get attendance stats method
  Future<Response> getAttendanceStats() async {
    return await _dio.get(ApiConstants.attendanceStats);
  }

  /// Enhanced get child attendance history with error handling
  Future<Map<String, dynamic>?> getChildAttendanceHistoryEnhanced(
    String childId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio
          .get(ApiConstants.childAttendance(childId), queryParameters: {
        'page': page,
        'limit': limit,
      });

      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('Child not found or no attendance history available.');
      }
      rethrow;
    }
  }

  /// Original get child attendance history method
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

  // ============================================================================
  // SERVICE ENDPOINTS
  // ============================================================================

  /// Enhanced get services with error handling
  Future<Map<String, dynamic>?> getServicesEnhanced({
    int page = 1,
    int limit = 50,
    bool? isActive,
    String? dayOfWeek,
  }) async {
    try {
      final response = await _dio.get(ApiConstants.services, queryParameters: {
        'page': page,
        'limit': limit,
        if (isActive != null) 'isActive': isActive,
        if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
      });

      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('No services found with the specified criteria.');
      }
      rethrow;
    }
  }

  /// Original get services method
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

  /// Enhanced get service by ID with error handling
  Future<Map<String, dynamic>?> getServiceByIdEnhanced(String id) async {
    try {
      final response = await _dio.get(ApiConstants.serviceById(id));
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('Service not found. Please check the ID.');
      }
      rethrow;
    }
  }

  /// Original get service by ID method
  Future<Response> getServiceById(String id) async {
    return await _dio.get(ApiConstants.serviceById(id));
  }

  // ============================================================================
  // REPORTS ENDPOINTS
  // ============================================================================

  /// Enhanced get attendance report with error handling
  Future<Map<String, dynamic>?> getAttendanceReportEnhanced({
    DateTime? startDate,
    DateTime? endDate,
    String? serviceId,
    String? childId,
    String? status,
  }) async {
    try {
      final response =
          await _dio.get(ApiConstants.reportsAttendance, queryParameters: {
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (serviceId != null) 'serviceSessionId': serviceId,
        if (childId != null) 'childId': childId,
        if (status != null) 'status': status,
      });

      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isValidationError) {
        throw Exception('Please check the date range and parameters.');
      }
      if (errorResponse.isNotFoundError) {
        throw Exception('No attendance data found for the specified criteria.');
      }
      rethrow;
    }
  }

  /// Original get attendance report method
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

  /// Enhanced get dashboard data with error handling
  Future<Map<String, dynamic>?> getDashboardDataEnhanced() async {
    try {
      final response = await _dio.get(ApiConstants.reportsDashboard);
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('Dashboard data not available.');
      }
      rethrow;
    }
  }

  /// Original get dashboard data method
  Future<Response> getDashboardData() async {
    return await _dio.get(ApiConstants.reportsDashboard);
  }

  // ============================================================================
  // HEALTH CHECK ENDPOINTS
  // ============================================================================

  /// Enhanced health check with error handling
  Future<Map<String, dynamic>?> healthCheckEnhanced() async {
    try {
      final response = await _dio.get(ApiConstants.health);
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isServerError) {
        throw Exception(
            'Service is currently unavailable. Please try again later.');
      }
      rethrow;
    }
  }

  /// Original health check method
  Future<Response> healthCheck() async {
    return await _dio.get(ApiConstants.health);
  }

  // ============================================================================
  // GUARDIAN ENDPOINTS
  // ============================================================================

  /// Enhanced get guardian by QR code with error handling
  Future<Map<String, dynamic>?> getGuardianByQrCodeEnhanced(
      String qrCode) async {
    try {
      final response = await _dio.get(ApiConstants.searchGuardiansByQr(qrCode));
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('No guardian found with this QR code.');
      }
      rethrow;
    }
  }

  /// Original get guardian by QR code method
  Future<Response> getGuardianByQrCode(String qrCode) async {
    return await _dio.get(ApiConstants.searchGuardiansByQr(qrCode));
  }

  /// Enhanced get guardian by RFID tag with error handling
  Future<Map<String, dynamic>?> getGuardianByRfidTagEnhanced(
      String rfidTag) async {
    try {
      final response =
          await _dio.get(ApiConstants.searchGuardiansByRfid(rfidTag));
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('No guardian found with this RFID tag.');
      }
      rethrow;
    }
  }

  /// Original get guardian by RFID tag method
  Future<Response> getGuardianByRfidTag(String rfidTag) async {
    return await _dio.get(ApiConstants.searchGuardiansByRfid(rfidTag));
  }

  /// Enhanced get guardian with children with error handling
  Future<Map<String, dynamic>?> getGuardianWithChildrenEnhanced(
      String guardianId) async {
    try {
      final response =
          await _dio.get(ApiConstants.guardianChildren(guardianId));
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('Guardian not found or no children linked.');
      }
      rethrow;
    }
  }

  /// Original get guardian with children method
  Future<Response> getGuardianWithChildren(String guardianId) async {
    return await _dio.get(ApiConstants.guardianChildren(guardianId));
  }

  /// Enhanced get guardian by ID with error handling
  Future<Map<String, dynamic>?> getGuardianByIdEnhanced(
      String guardianId) async {
    try {
      final response = await _dio.get(ApiConstants.guardianById(guardianId));
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('Guardian not found. Please check the ID.');
      }
      rethrow;
    }
  }

  /// Original get guardian by ID method
  Future<Response> getGuardianById(String guardianId) async {
    return await _dio.get(ApiConstants.guardianById(guardianId));
  }

  /// Enhanced link child to guardian with error handling
  Future<Map<String, dynamic>?> linkChildToGuardianEnhanced(
      String guardianId, String childId) async {
    try {
      final response =
          await _dio.post(ApiConstants.linkChildToGuardian(guardianId), data: {
        'childId': childId,
      });

      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isValidationError) {
        throw Exception('Please check the guardian ID and child ID.');
      }
      if (errorResponse.isDuplicateError) {
        throw Exception('Child is already linked to this guardian.');
      }
      rethrow;
    }
  }

  /// Original link child to guardian method
  Future<Response> linkChildToGuardian(
      String guardianId, String childId) async {
    return await _dio.post(ApiConstants.linkChildToGuardian(guardianId), data: {
      'childId': childId,
    });
  }

  /// Enhanced unlink child from guardian with error handling
  Future<Map<String, dynamic>?> unlinkChildFromGuardianEnhanced(
      String guardianId, String childId) async {
    try {
      final response = await _dio
          .delete(ApiConstants.unlinkChildFromGuardian(guardianId, childId));

      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('Link not found or already removed.');
      }
      rethrow;
    }
  }

  /// Original unlink child from guardian method
  Future<Response> unlinkChildFromGuardian(
      String guardianId, String childId) async {
    return await _dio
        .delete(ApiConstants.unlinkChildFromGuardian(guardianId, childId));
  }

  /// Enhanced create guardian with error handling
  Future<Map<String, dynamic>?> createGuardianEnhanced(
      Guardian guardian) async {
    try {
      final response = await _dio.post(ApiConstants.guardians, data: guardian);
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isValidationError) {
        throw Exception('Please check the guardian information and try again.');
      }
      if (errorResponse.isDuplicateError) {
        throw Exception('Guardian already exists with this information.');
      }
      rethrow;
    }
  }

  /// Original create guardian method
  Future<Response> createGuardian(Guardian guardian) async {
    return await _dio.post(ApiConstants.guardians, data: guardian);
  }

  /// Enhanced update guardian with error handling
  Future<Map<String, dynamic>?> updateGuardianEnhanced(
      Guardian guardian) async {
    try {
      final response = await _dio.put(ApiConstants.guardianById(guardian.id),
          data: guardian);

      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isValidationError) {
        throw Exception('Please check the guardian information and try again.');
      }
      if (errorResponse.isNotFoundError) {
        throw Exception('Guardian not found. Please check the ID.');
      }
      rethrow;
    }
  }

  /// Original update guardian method
  Future<Response> updateGuardian(Guardian guardian) async {
    return await _dio.put(ApiConstants.guardianById(guardian.id),
        data: guardian);
  }

  /// Enhanced get all guardians with error handling
  Future<Map<String, dynamic>?> getAllGuardiansEnhanced() async {
    try {
      final response = await _dio.get(ApiConstants.guardians);
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('No guardians found.');
      }
      rethrow;
    }
  }

  /// Original get all guardians method
  Future<Response> getAllGuardians() async {
    return await _dio.get(ApiConstants.guardians);
  }

  // ============================================================================
  // GUARDIAN-BASED ATTENDANCE ENDPOINTS
  // ============================================================================

  /// Enhanced check-in children with error handling
  Future<Map<String, dynamic>?> checkInChildrenEnhanced({
    required String guardianId,
    required String serviceId,
    required List<String> childIds,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.guardianCheckin, data: {
        'guardianId': guardianId,
        'serviceId': serviceId,
        'childIds': childIds,
      });

      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isValidationError) {
        throw Exception(
            'Please check the guardian ID, service ID, and child IDs.');
      }
      if (errorResponse.isNotFoundError) {
        throw Exception('Guardian or service not found.');
      }
      rethrow;
    }
  }

  /// Original check-in children method
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

  /// Enhanced check-out children with error handling
  Future<Map<String, dynamic>?> checkOutChildrenEnhanced({
    required String guardianId,
    required List<String> childIds,
    required List<String> pickupCodes,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.guardianCheckout, data: {
        'guardianId': guardianId,
        'childIds': childIds,
        'pickupCodes': pickupCodes,
      });

      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isValidationError) {
        throw Exception('Please check the pickup codes and child IDs.');
      }
      if (errorResponse.isNotFoundError) {
        throw Exception('Guardian or children not found.');
      }
      rethrow;
    }
  }

  /// Original check-out children method
  Future<Response> checkOutChildren({
    required String guardianId,
    required List<String> childIds,
    required List<String> pickupCodes,
  }) async {
    return await _dio.post(ApiConstants.guardianCheckout, data: {
      'guardianId': guardianId,
      'childIds': childIds,
      'pickupCodes': pickupCodes,
    });
  }

  /// Enhanced get guardian current check-ins with error handling
  Future<Map<String, dynamic>?> getGuardianCurrentCheckinsEnhanced(
      String guardianId) async {
    try {
      final response =
          await _dio.get(ApiConstants.guardianCurrentCheckins(guardianId));
      return ApiResponseHandler.handleSuccessResponse(response);
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      if (errorResponse.isNotFoundError) {
        throw Exception('Guardian not found or no current check-ins.');
      }
      rethrow;
    }
  }

  /// Original get guardian current check-ins method
  Future<Response> getGuardianCurrentCheckins(String guardianId) async {
    return await _dio.get(ApiConstants.guardianCurrentCheckins(guardianId));
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Helper method to extract data from API response
  Map<String, dynamic>? extractData(Response response) {
    return ApiResponseHandler.handleSuccessResponse(response);
  }

  /// Helper method to extract success status from API response
  bool isSuccess(Response response) {
    return ApiResponseHandler.isSuccessResponse(response);
  }

  /// Helper method to extract message from API response
  String? getMessage(Response response) {
    return ApiResponseHandler.getSuccessMessage(response);
  }

  /// Helper method to extract pagination data from API response
  Map<String, dynamic>? getPaginationData(Response response) {
    return ApiResponseHandler.getPaginationData(response);
  }

  /// Helper method to handle API errors
  ApiErrorResponse handleError(dynamic error) {
    return ApiResponseHandler.handleErrorResponse(error);
  }

  /// Check if the service is online
  Future<bool> checkConnectivity() async {
    try {
      return await isOnline();
    } catch (e) {
      return false;
    }
  }

  /// Get detailed error information for debugging
  String getDetailedErrorInfo(dynamic error) {
    final errorResponse = ApiResponseHandler.handleErrorResponse(error);
    return '''
Error Details:
- Message: ${errorResponse.message}
- Code: ${errorResponse.error?.code ?? 'N/A'}
- Details: ${errorResponse.error?.details ?? 'N/A'}
- Timestamp: ${errorResponse.timestamp ?? 'N/A'}
- Path: ${errorResponse.path ?? 'N/A'}
- Method: ${errorResponse.method ?? 'N/A'}
''';
  }
}
