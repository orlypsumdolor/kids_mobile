import '../../domain/entities/child.dart';
import '../../domain/entities/checkin_session.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/guardian.dart';
import '../../domain/repositories/checkin_repository.dart';
import '../datasources/remote/api_service.dart';
import '../datasources/local/database_helper.dart';
import '../models/child_model.dart';
import '../models/checkin_session_model.dart';
import '../models/attendance_record_model.dart';
import '../models/guardian_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class CheckinRepositoryImpl implements CheckinRepository {
  final ApiService _apiService;
  final DatabaseHelper _databaseHelper;
  final Uuid _uuid = const Uuid();

  CheckinRepositoryImpl({
    required ApiService apiService,
    required DatabaseHelper databaseHelper,
  })  : _apiService = apiService,
        _databaseHelper = databaseHelper;

  // Guardian-based operations
  @override
  Future<Guardian?> getGuardianByQrCode(String qrCode) async {
    try {
      final response = await _apiService.getGuardianByQrCode(qrCode);

      if (response.data['success'] == true && response.data['data'] != null) {
        final guardianData = response.data['data']['guardian'];
        if (guardianData != null) {
          final guardianModel = GuardianModel.fromJson(guardianData);
          return guardianModel.toEntity();
        }
      }

      return null;
    } catch (e) {
      print('Error getting guardian by QR code: $e');
      return null;
    }
  }

  @override
  Future<Guardian?> getGuardianByRfidTag(String rfidTag) async {
    try {
      final response = await _apiService.getGuardianByRfidTag(rfidTag);

      if (response.data['success'] == true && response.data['data'] != null) {
        final guardianData = response.data['data']['guardian'];
        if (guardianData != null) {
          final guardianModel = GuardianModel.fromJson(guardianData);
          return guardianModel.toEntity();
        }
      }

      return null;
    } catch (e) {
      print('Error getting guardian by RFID tag: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getGuardianWithChildren(
      String guardianId) async {
    try {
      final response = await _apiService.getGuardianWithChildren(guardianId);

      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'];
        final guardianData = data['guardian'];
        final childrenData = data['children'] as List<dynamic>?;

        if (guardianData != null) {
          final guardian = GuardianModel.fromJson(guardianData).toEntity();
          final children = childrenData?.map((childJson) {
                return ChildModel.fromJson(childJson).toEntity();
              }).toList() ??
              [];

          return {
            'guardian': guardian,
            'children': children,
          };
        }
      }

      return null;
    } catch (e) {
      print('Error getting guardian with children: $e');
      return null;
    }
  }

  @override
  Future<List<AttendanceRecord>> checkInChildren({
    required String guardianId,
    required String serviceId,
    required List<String> childIds,
  }) async {
    try {
      print('=== GUARDIAN CHECK-IN PROCESS START ===');
      print('Guardian ID: $guardianId');
      print('Service ID: $serviceId');
      print('Child IDs: $childIds');

      final response = await _apiService.checkInChildren(
        guardianId: guardianId,
        serviceId: serviceId,
        childIds: childIds,
      );

      print('=== API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');

      if (response.data['success'] == true && response.data['data'] != null) {
        final serverData = response.data['data'];
        final recordsData = serverData['records'] as List<dynamic>?;

        if (recordsData != null) {
          final attendanceRecords = recordsData.map((recordJson) {
            return AttendanceRecordModel.fromJson(recordJson).toEntity();
          }).toList();

          print('=== CHECK-IN COMPLETE ===');
          print('Created ${attendanceRecords.length} attendance records');
          return attendanceRecords;
        } else {
          throw Exception('No attendance records data in server response');
        }
      } else {
        final errorMessage = response.data['message'] ?? 'Check-in failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('=== GUARDIAN CHECK-IN ERROR ===');
      print('Error: $e');
      rethrow;
    }
  }

  @override
  Future<List<AttendanceRecord>> checkOutChildren({
    required String guardianId,
    required List<String> childIds,
  }) async {
    try {
      print('=== GUARDIAN CHECK-OUT PROCESS START ===');
      print('Guardian ID: $guardianId');
      print('Child IDs: $childIds');

      final response = await _apiService.checkOutChildren(
        guardianId: guardianId,
        childIds: childIds,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final serverData = response.data['data'];
        final recordsData = serverData['records'] as List<dynamic>?;

        if (recordsData != null) {
          final attendanceRecords = recordsData.map((recordJson) {
            return AttendanceRecordModel.fromJson(recordJson).toEntity();
          }).toList();

          print('=== CHECK-OUT COMPLETE ===');
          print('Updated ${attendanceRecords.length} attendance records');
          return attendanceRecords;
        } else {
          throw Exception('No attendance records data in server response');
        }
      } else {
        final errorMessage = response.data['message'] ?? 'Check-out failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('=== GUARDIAN CHECK-OUT ERROR ===');
      print('Error: $e');
      rethrow;
    }
  }

  @override
  Future<List<AttendanceRecord>> getGuardianCurrentCheckins(
      String guardianId) async {
    try {
      final response = await _apiService.getGuardianCurrentCheckins(guardianId);

      if (response.data['success'] == true && response.data['data'] != null) {
        final recordsData = response.data['data']['records'] as List<dynamic>?;
        if (recordsData != null) {
          return recordsData.map((recordJson) {
            return AttendanceRecordModel.fromJson(recordJson).toEntity();
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error getting guardian current check-ins: $e');
      return [];
    }
  }

  @override
  Future<Child?> getChildByQrCode(String qrCode) async {
    try {
      String childId = qrCode;

      // Check if QR code contains JSON data
      if (qrCode.startsWith('{') && qrCode.contains('"childId"')) {
        try {
          final qrData = jsonDecode(qrCode);
          childId = qrData['childId'] ?? qrCode;
        } catch (e) {
          // If JSON parsing fails, use original QR code
          childId = qrCode;
        }
      }

      // Try local database first
      // final localResults = await _databaseHelper.query(
      //   'children',
      //   where: 'id = ? AND is_active = 1',
      //   whereArgs: [childId],
      // );

      // if (localResults.isNotEmpty) {
      //   final childModel = ChildModel.fromJson(localResults.first);
      //   // log the child model
      //   print('Local Child model: $childModel');
      //   return childModel.toEntity();
      // }

      // Try API - use childId directly instead of QR code search
      final response = await _apiService.getChildById(childId);
      print('API Response: ${response.data}');
      print('Response success: ${response.data['success']}');
      print('Response data: ${response.data['data']}');

      if (response.data['success'] == true && response.data['data'] != null) {
        // Handle nested child data structure
        final childData = response.data['data']['child'];
        print('Child data extracted: $childData');

        if (childData == null) {
          print('Child data is null in response: ${response.data}');
          return null;
        }
        final childModel = ChildModel.fromJson(childData);

        // Cache in local database
        //await _databaseHelper.insert('children', childModel.toJson());
        // log the child model
        print('Child model: $childModel');
        return childModel.toEntity();
      }

      // log the response
      print('Response: $response');
      print('child is nulllll');
      return null;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  @override
  Future<Child?> getChildByRfidCode(String rfidCode) async {
    try {
      String childId = rfidCode;

      // Check if RFID contains JSON data
      if (rfidCode.startsWith('{') && rfidCode.contains('"childId"')) {
        try {
          final rfidData = jsonDecode(rfidCode);
          childId = rfidData['childId'] ?? rfidCode;
        } catch (e) {
          // If JSON parsing fails, use original RFID code
          childId = rfidCode;
        }
      }

      // Try local database first
      final localResults = await _databaseHelper.query(
        'children',
        where: 'id = ? AND is_active = 1',
        whereArgs: [childId],
      );

      if (localResults.isNotEmpty) {
        final childModel = ChildModel.fromJson(localResults.first);
        return childModel.toEntity();
      }

      // Try API - use childId directly instead of RFID search
      final response = await _apiService.getChildById(childId);
      print('API Response (RFID): ${response.data}');
      print('Response success (RFID): ${response.data['success']}');
      print('Response data (RFID): ${response.data['data']}');

      if (response.data['success'] == true && response.data['data'] != null) {
        // Handle nested child data structure
        final childData = response.data['data']['child'];
        print('Child data extracted (RFID): $childData');

        if (childData == null) {
          print('Child data is null in response: ${response.data}');
          return null;
        }
        final childModel = ChildModel.fromJson(childData);

        // Cache in local database
        await _databaseHelper.insert('children', childModel.toJson());

        return childModel.toEntity();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<AttendanceRecord> checkInChild(
      String childId, String volunteerId, String serviceSession) async {
    try {
      print('=== CHECK-IN PROCESS START ===');
      print('Child ID: $childId');
      print('Volunteer ID: $volunteerId');
      print('Service Session: $serviceSession');

      // API call for check-in
      final response = await _apiService.checkInChild(
        childId: childId,
        serviceSessionId: serviceSession,
      );

      print('=== API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');

      if (response.data['success'] == true && response.data['data'] != null) {
        final serverData = response.data['data'];
        final recordData = serverData['record'];

        print('=== PARSING RESPONSE ===');
        print('Server Data: $serverData');
        print('Record Data: $recordData');

        if (recordData != null) {
          print('=== CREATING ATTENDANCE MODEL ===');
          print('Record data type: ${recordData.runtimeType}');
          print(
              'Record data keys: ${recordData is Map ? recordData.keys.toList() : 'Not a Map'}');

          // Parse the server response into AttendanceRecordModel
          final attendanceModel = AttendanceRecordModel.fromJson(recordData);
          print('Parsed attendance model: $attendanceModel');

          // Convert to entity and return
          final attendanceRecord = attendanceModel.toEntity();
          print('=== FINAL ATTENDANCE RECORD ===');
          print('ID: ${attendanceRecord.id}');
          print('Child ID: ${attendanceRecord.childId}');
          print('Service Session: ${attendanceRecord.serviceSessionId}');
          print('Pickup Code: ${attendanceRecord.pickupCode}');
          print('Check-in Time: ${attendanceRecord.checkInTime}');
          print('=== CHECK-IN PROCESS COMPLETE ===');

          return attendanceRecord;
        } else {
          print('ERROR: No attendance record data in server response');
          throw Exception('No attendance record data in server response');
        }
      } else {
        final errorMessage = response.data['message'] ?? 'Check-in failed';
        print('ERROR: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('=== CHECK-IN ERROR ===');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');

      // Handle DioException to extract server error messages
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          print('Response data in error: $responseData');

          if (responseData is Map<String, dynamic>) {
            final errorMessage = responseData['message'] ?? 'Check-in failed';
            print('Extracted error message: $errorMessage');
            throw Exception(errorMessage);
          } else {
            throw Exception('Check-in failed: ${e.message}');
          }
        } else {
          throw Exception('Network error: ${e.message}');
        }
      } else {
        // Handle other types of exceptions
        throw Exception('Check-in failed: ${e.toString()}');
      }
    }
  }

  @override
  Future<CheckInSession> checkOutChild(
      String sessionId, String volunteerId) async {
    final now = DateTime.now();

    // Get the session first
    final sessionResults = await _databaseHelper.query(
      'checkin_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (sessionResults.isEmpty) {
      throw Exception('Session not found');
    }

    final sessionData = sessionResults.first;

    // Update local database
    await _databaseHelper.update(
      'checkin_sessions',
      {
        'checkout_time': now.toIso8601String(),
        'status': 'checkedOut',
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    // API call for check-out
    try {
      final response = await _apiService.checkOutChild(
        recordId: sessionId,
        pickupCode: sessionData['pickup_code'],
      );

      if (response.data['success'] == true) {
        // API call successful
        print('Check-out synced with server');
      }
    } catch (e) {
      // Continue with local operation
    }

    // Return updated session
    final results = await _databaseHelper.query(
      'checkin_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (results.isEmpty) {
      throw Exception('Updated session not found');
    }

    final sessionModel = CheckInSessionModel.fromJson(results.first);
    return sessionModel.toEntity();
  }

  @override
  Future<bool> verifyPickupCode(String pickupCode, String childId) async {
    try {
      // Note: verifyPickupCode API method was removed, using local verification only
      // TODO: Implement proper pickup code verification through attendance records

      // Local verification
      final results = await _databaseHelper.query(
        'checkin_sessions',
        where: 'pickup_code = ? AND child_id = ? AND status = ?',
        whereArgs: [pickupCode, childId, 'checkedIn'],
      );

      return results.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<CheckInSession>> getActiveCheckins() async {
    try {
      final results = await _databaseHelper.query(
        'checkin_sessions',
        where: 'status = ?',
        whereArgs: ['checkedIn'],
        orderBy: 'checkin_time DESC',
      );

      return results
          .map((json) => CheckInSessionModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<CheckInSession>> getAttendanceSummary(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final results = await _databaseHelper.query(
        'checkin_sessions',
        where: 'checkin_time >= ? AND checkin_time <= ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
        orderBy: 'checkin_time DESC',
      );

      return results
          .map((json) => CheckInSessionModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      return [];
    }
  }

  String _generatePickupCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';

    for (int i = 0; i < 6; i++) {
      code += chars[(random + i) % chars.length];
    }

    return code;
  }
}
