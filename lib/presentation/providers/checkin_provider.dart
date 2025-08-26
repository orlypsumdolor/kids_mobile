import 'package:flutter/foundation.dart';
import '../../domain/entities/child.dart';
import '../../domain/entities/checkin_session.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/guardian.dart';
import '../../domain/usecases/checkin_usecases.dart';
import '../../core/services/camera_service.dart';
// import '../../core/services/nfc_service.dart'; // Temporarily disabled
import '../../core/services/printer_service.dart';
import '../../data/datasources/remote/api_service.dart';
import '../../data/models/guardian_model.dart';
import '../../data/models/attendance_record_model.dart';

class CheckinProvider extends ChangeNotifier {
  final CheckInChildUseCase _checkInChildUseCase;
  final GetChildByCodeUseCase _getChildByCodeUseCase;
  final GeneratePickupCodeUseCase _generatePickupCodeUseCase;
  final CameraService _cameraService;
  // final NfcService _nfcService; // Temporarily disabled
  final PrinterService _printerService;
  final ApiService _apiService;

  CheckinProvider({
    required CheckInChildUseCase checkInChildUseCase,
    required GetChildByCodeUseCase getChildByCodeUseCase,
    required GeneratePickupCodeUseCase generatePickupCodeUseCase,
    required CameraService cameraService,
    required PrinterService printerService,
    required ApiService apiService,
  })  : _checkInChildUseCase = checkInChildUseCase,
        _getChildByCodeUseCase = getChildByCodeUseCase,
        _generatePickupCodeUseCase = generatePickupCodeUseCase,
        _cameraService = cameraService,
        _printerService = printerService,
        _apiService = apiService;

  Child? _scannedChild;
  AttendanceRecord? _currentAttendanceRecord;
  bool _isLoading = false;
  bool _isScanning = false;
  String? _error;
  String? _successMessage;

  Child? get scannedChild => _scannedChild;
  AttendanceRecord? get currentAttendanceRecord => _currentAttendanceRecord;
  CheckInSession? get currentSession => _currentAttendanceRecord != null
      ? CheckInSession(
          id: _currentAttendanceRecord!.id,
          serviceSessionId: _currentAttendanceRecord!.serviceSessionId,
          date: _currentAttendanceRecord!.checkInTime,
          createdBy: _currentAttendanceRecord!.checkedInBy,
          checkedInChildren: [_currentAttendanceRecord!.childId],
          isActive: _currentAttendanceRecord!.isActive,
          createdAt: _currentAttendanceRecord!.createdAt,
          updatedAt: _currentAttendanceRecord!.updatedAt,
        )
      : null;
  String? get currentPickupCode => _currentAttendanceRecord?.pickupCode;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  String? get error => _error;
  String? get successMessage => _successMessage;

  // Guardian-based check-in methods
  Future<Guardian?> getGuardianByQrCode(String qrCode) async {
    try {
      // Call the API service to get guardian by QR code
      final response = await _apiService.getGuardianByQrCode(qrCode);

      if (_apiService.isSuccess(response)) {
        final data = _apiService.extractData(response);
        if (data != null &&
            data['guardians'] != null &&
            (data['guardians'] as List).isNotEmpty) {
          // Get the first guardian from the search results
          final guardianData =
              (data['guardians'] as List).first as Map<String, dynamic>;

          // Parse using GuardianModel
          final guardianModel = GuardianModel.fromJson(guardianData);
          print(
              '✅ Guardian found by QR code: ${guardianModel.toEntity().fullName}');
          return guardianModel.toEntity();
        }
      }

      print(
          '❌ Guardian not found with QR code: ${_apiService.getMessage(response)}');
      return null;
    } catch (e) {
      print('💥 Error getting guardian by QR code: $e');
      throw Exception('Failed to get guardian by QR code: $e');
    }
  }

  Future<Guardian?> getGuardianById(String guardianId) async {
    try {
      // Call the API service to get guardian by ID
      final response = await _apiService.getGuardianById(guardianId);

      if (_apiService.isSuccess(response)) {
        final data = _apiService.extractData(response);
        if (data != null && data['guardian'] != null) {
          // Parse the guardian data and return Guardian entity
          final guardianModel = GuardianModel.fromJson(data['guardian']);
          print(
              '✅ Guardian successfully parsed and returned: ${guardianModel.toEntity().fullName}');
          return guardianModel.toEntity();
        }
      }

      print(
          '❌ Failed to get guardian by ID: ${_apiService.getMessage(response)}');
      return null;
    } catch (e) {
      print('💥 Error getting guardian by ID: $e');
      throw Exception('Failed to get guardian by ID: $e');
    }
  }

  Future<Guardian?> getGuardianByRfidTag(String rfidTag) async {
    try {
      // Call the API service to get guardian by RFID tag
      final response = await _apiService.getGuardianByRfidTag(rfidTag);

      if (_apiService.isSuccess(response)) {
        final data = _apiService.extractData(response);
        if (data != null &&
            data['guardians'] != null &&
            (data['guardians'] as List).isNotEmpty) {
          // Get the first guardian from the search results
          final guardianData =
              (data['guardians'] as List).first as Map<String, dynamic>;

          // Parse using GuardianModel
          final guardianModel = GuardianModel.fromJson(guardianData);
          print(
              '✅ Guardian found by RFID tag: ${guardianModel.toEntity().fullName}');
          return guardianModel.toEntity();
        }
      }

      print(
          '❌ Guardian not found with RFID tag: ${_apiService.getMessage(response)}');
      return null;
    } catch (e) {
      print('💥 Error getting guardian by RFID tag: $e');
      throw Exception('Failed to get guardian by RFID tag: $e');
    }
  }

  Future<Map<String, dynamic>?> getGuardianWithChildren(
      String guardianId) async {
    try {
      // Call the API service to get guardian with linked children
      final response = await _apiService.getGuardianWithChildren(guardianId);

      if (_apiService.isSuccess(response)) {
        final data = _apiService.extractData(response);
        if (data != null) {
          print('✅ Guardian with children data received: $data');
          return data;
        }
      }

      print(
          '❌ Failed to get guardian with children: ${_apiService.getMessage(response)}');
      return null;
    } catch (e) {
      print('💥 Error getting guardian with children: $e');
      throw Exception('Failed to get guardian with children: $e');
    }
  }

  Future<List<AttendanceRecord>> checkInChildren({
    required String guardianId,
    required String serviceId,
    required List<String> childIds,
  }) async {
    try {
      print('🚀 Starting check-in process for ${childIds.length} children');
      print('👤 Guardian ID: $guardianId');
      print('⛪ Service ID: $serviceId');
      print('👶 Child IDs: $childIds');

      // Call the API service to check in multiple children
      final response = await _apiService.checkInChildren(
        guardianId: guardianId,
        serviceId: serviceId,
        childIds: childIds,
      );

      if (_apiService.isSuccess(response)) {
        final data = _apiService.extractData(response);
        if (data != null && data['records'] != null) {
          // Parse attendance records from the API response
          final recordsData = data['records'] as List<dynamic>;
          print('📊 Found ${recordsData.length} attendance records to parse');

          final attendanceRecords = recordsData
              .map((recordJson) {
                try {
                  print('🔄 Parsing record: ${recordJson['_id']}');
                  final recordModel = AttendanceRecordModel.fromJson(
                      recordJson as Map<String, dynamic>);
                  final entity = recordModel.toEntity();
                  print('✅ Successfully parsed record: ${entity.id}');
                  print('   👶 Child ID: ${entity.childId}');
                  print('   👤 Guardian ID: ${entity.guardianId}');
                  print('   ⛪ Service ID: ${entity.serviceId}');
                  print('   🎫 Pickup Code: ${entity.pickupCode}');
                  return entity;
                } catch (parseError) {
                  print('⚠️ Error parsing attendance record: $parseError');
                  print('📄 Record data: $recordJson');
                  return null;
                }
              })
              .whereType<AttendanceRecord>()
              .toList();

          print(
              '✅ Children checked in successfully: ${attendanceRecords.length} records created');
          print(
              '🎫 Pickup codes: ${attendanceRecords.map((r) => r.pickupCode).join(', ')}');

          return attendanceRecords;
        } else {
          print('❌ No attendance records in API response');
          print('📄 Response data: $data');
          return [];
        }
      }

      print(
          '❌ Failed to check in children: ${_apiService.getMessage(response)}');
      return [];
    } catch (e) {
      print('💥 Error checking in children: $e');
      throw Exception('Failed to check in children: $e');
    }
  }

  Future<List<AttendanceRecord>> checkOutChildren({
    required String guardianId,
    required List<String> childIds,
  }) async {
    try {
      print('🚀 Starting check-out process for ${childIds.length} children');
      print('👤 Guardian ID: $guardianId');
      print('👶 Child IDs: $childIds');

      // Call the API service to check out multiple children
      final response = await _apiService.checkOutChildren(
        guardianId: guardianId,
        childIds: childIds,
      );

      if (_apiService.isSuccess(response)) {
        final data = _apiService.extractData(response);
        if (data != null && data['records'] != null) {
          // Parse attendance records from the API response
          final recordsData = data['records'] as List<dynamic>;
          print('📊 Found ${recordsData.length} attendance records to parse');

          final attendanceRecords = recordsData
              .map((recordJson) {
                try {
                  print('🔄 Parsing record: ${recordJson['_id']}');
                  final recordModel = AttendanceRecordModel.fromJson(
                      recordJson as Map<String, dynamic>);
                  final entity = recordModel.toEntity();
                  print('✅ Successfully parsed record: ${entity.id}');
                  print('   👶 Child ID: ${entity.childId}');
                  print('   👤 Guardian ID: ${entity.guardianId}');
                  print('   ⛪ Service ID: ${entity.serviceId}');
                  print('   🎫 Pickup Code: ${entity.pickupCode}');
                  return entity;
                } catch (parseError) {
                  print('⚠️ Error parsing attendance record: $parseError');
                  print('📄 Record data: $recordJson');
                  return null;
                }
              })
              .whereType<AttendanceRecord>()
              .toList();

          print(
              '✅ Children checked out successfully: ${attendanceRecords.length} records updated');
          return attendanceRecords;
        } else {
          print('❌ No attendance records in API response');
          print('📄 Response data: $data');
          return [];
        }
      }

      print(
          '❌ Failed to check out children: ${_apiService.getMessage(response)}');
      return [];
    } catch (e) {
      print('💥 Error checking out children: $e');
      throw Exception('Failed to check out children: $e');
    }
  }

  Future<Map<String, dynamic>?> getGuardianCurrentCheckins(
      String guardianId) async {
    try {
      print('🔍 Getting current check-ins for guardian: $guardianId');

      // Call the API service to get current check-ins for a guardian
      final response = await _apiService.getGuardianCurrentCheckins(guardianId);

      if (_apiService.isSuccess(response)) {
        final data = _apiService.extractData(response);
        if (data != null) {
          print('✅ Guardian current check-ins retrieved successfully');
          print('📊 Data: $data');
          return data;
        }
      }

      print(
          '❌ Failed to get guardian current check-ins: ${_apiService.getMessage(response)}');
      return null;
    } catch (e) {
      print('💥 Error getting guardian current check-ins: $e');
      throw Exception('Failed to get guardian current check-ins: $e');
    }
  }

  Future<void> scanQRCode(String qrCode) async {
    _setLoading(true);
    try {
      final child = await _getChildByCodeUseCase.byQrCode(qrCode);
      if (child != null && child.isActive) {
        _scannedChild = child;
        _clearError();
      } else {
        _setError('Child not found or inactive');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> scanRFID(String rfidCode) async {
    _setLoading(true);
    try {
      final child = await _getChildByCodeUseCase.byRfidCode(rfidCode);
      if (child != null && child.isActive) {
        _scannedChild = child;
        _clearError();
      } else {
        _setError('Child not found or inactive');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkInChild(String volunteerId, String serviceSession) async {
    if (_scannedChild == null) {
      _setError('No child selected for check-in');
      return;
    }

    _setLoading(true);
    try {
      print('Starting check-in process...');
      final session = await _checkInChildUseCase(
        _scannedChild!.id,
        volunteerId,
        serviceSession,
      );

      _currentAttendanceRecord = session;
      print('Check-in successful, attendance record created');

      // Try to print sticker
      if (_printerService.isConnected) {
        try {
          // Convert AttendanceRecord to CheckInSession for printing
          final checkInSession = CheckInSession(
            id: session.id,
            serviceSessionId: session.serviceSessionId,
            date: session.checkInTime, // Use checkInTime instead of serviceDate
            createdBy: session.checkedInBy,
            checkedInChildren: [session.childId],
            isActive: session.isActive,
            createdAt: session.createdAt,
            updatedAt: session.updatedAt,
          );

          await _printerService.printCheckInSticker(
            child: _scannedChild!,
            session: checkInSession,
          );
          final pickupCode = session.pickupCode ?? 'No pickup code';
          _setSuccessMessage(
              '${_scannedChild!.fullName} checked in successfully! Sticker printed. Pickup code: $pickupCode');
        } catch (e) {
          final pickupCode = session.pickupCode ?? 'No pickup code';
          _setSuccessMessage(
              '${_scannedChild!.fullName} checked in successfully! (Printing failed) Pickup code: $pickupCode');
        }
      } else {
        final pickupCode = session.pickupCode ?? 'No pickup code';
        _setSuccessMessage(
            '${_scannedChild!.fullName} checked in successfully! (No printer connected) Pickup code: $pickupCode');
      }

      _clearError();
      print('Success message set: $_successMessage');
    } catch (e) {
      print('Error during check-in: $e');

      // Handle specific error cases
      final errorMessage = e.toString();
      if (errorMessage.contains('already checked in')) {
        _setError('This child is already checked in for this service today.');
      } else if (errorMessage.contains('not found')) {
        _setError(
            'Child or service not found. Please verify the information and try again.');
      } else if (errorMessage.contains('inactive')) {
        _setError(
            'Child is inactive and cannot be checked in. Please contact an administrator.');
      } else if (errorMessage.contains('Network error')) {
        _setError(
            'Network connection error. Please check your internet connection and try again.');
      } else {
        _setError(
            'Check-in failed: ${errorMessage.replaceAll('Exception: ', '')}');
      }
    } finally {
      _setLoading(false);
    }
  }

  void startNFCScanning() {
    _isScanning = true;
    notifyListeners();

    // NFC service temporarily disabled
    // _nfcService.startReading(
    //   onTagRead: (rfidCode) {
    //     _isScanning = false;
    //     scanRFID(rfidCode);
    //   },
    //   onError: (error) {
    //     _isScanning = false;
    //     _setError(error);
    //   },
    // );

    // For now, show error that NFC is disabled
    _isScanning = false;
    _setError('NFC scanning is temporarily disabled');
    notifyListeners();
  }

  void stopNFCScanning() {
    if (_isScanning) {
      // _nfcService.stopReading(); // NFC service temporarily disabled
      _isScanning = false;
      notifyListeners();
    }
  }

  void clearScannedChild() {
    print('Clearing scanned child data');
    _scannedChild = null;
    _currentAttendanceRecord = null;
    _clearError();
    _clearSuccess();
    notifyListeners();
  }

  /// Check the current check-in status of the scanned child
  Future<void> checkChildStatus() async {
    if (_scannedChild == null) {
      _setError('No child selected');
      return;
    }

    _setLoading(true);
    try {
      print('Checking status for child: ${_scannedChild!.fullName}');

      // This would typically call an API endpoint to get current status
      // For now, we'll show the basic info we have
      final status =
          _scannedChild!.currentlyCheckedIn ? 'Checked In' : 'Not Checked In';
      _setSuccessMessage('Child Status: $status');
      _clearError();
    } catch (e) {
      print('Error checking child status: $e');
      _setError('Failed to check child status: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _setSuccessMessage(String message) {
    print('Setting success message: $message');
    _successMessage = message;
    print('Success message set to: $_successMessage');
    notifyListeners();
    print('Notified listeners about success message change');
  }

  void _clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopNFCScanning();
    super.dispose();
  }
}
