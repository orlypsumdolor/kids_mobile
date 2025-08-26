import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../domain/entities/checkin_session.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/usecases/checkout_usecases.dart';
import '../../core/services/camera_service.dart';
import '../../data/datasources/remote/api_service.dart';
import 'checkin_provider.dart';
// import '../../core/services/nfc_service.dart'; // Temporarily disabled

class CheckoutProvider extends ChangeNotifier {
  final CheckOutChildUseCase _checkOutChildUseCase;
  final VerifyPickupCodeUseCase _verifyPickupCodeUseCase;
  final CameraService _cameraService;
  final CheckinProvider _checkinProvider;
  final ApiService _apiService;
  // final NfcService _nfcService; // Temporarily disabled

  CheckoutProvider({
    required CheckOutChildUseCase checkOutChildUseCase,
    required VerifyPickupCodeUseCase verifyPickupCodeUseCase,
    required CameraService cameraService,
    required CheckinProvider checkinProvider,
    required ApiService apiService,
  })  : _checkOutChildUseCase = checkOutChildUseCase,
        _verifyPickupCodeUseCase = verifyPickupCodeUseCase,
        _cameraService = cameraService,
        _checkinProvider = checkinProvider,
        _apiService = apiService;

  CheckInSession? _verifiedSession;
  bool _isLoading = false;
  bool _isScanning = false;
  String? _error;
  String? _successMessage;
  Map<String, dynamic>? _scannedQrData;
  List<Map<String, dynamic>>? _childInfo; // Added for child names

  CheckInSession? get verifiedSession => _verifiedSession;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  String? get error => _error;
  String? get successMessage => _successMessage;
  Map<String, dynamic>? get scannedQrData => _scannedQrData;
  List<Map<String, dynamic>>? get childInfo => _childInfo;

  /// Fetch child names by IDs
  Future<List<Map<String, dynamic>>> _fetchChildNames(
      List<String> childIds) async {
    final List<Map<String, dynamic>> childInfo = [];

    try {
      for (final childId in childIds) {
        final response = await _apiService.getChildById(childId);

        if (response.data['success'] == true && response.data['data'] != null) {
          final childData = response.data['data']['child'];
          if (childData != null) {
            final childName = childData['firstName'] ?? 'Unknown';
            final childLastName = childData['lastName'] ?? '';
            final fullName = childLastName.isNotEmpty
                ? '$childName $childLastName'
                : childName;

            childInfo.add({
              'id': childId,
              'name': fullName,
            });
          }
        }
      }
    } catch (e) {
      print('💥 Error fetching child names: $e');
    }

    return childInfo;
  }

  /// Process QR code scan for checkout
  Future<bool> processQrCodeScan(String qrCode) async {
    _setLoading(true);
    try {
      print('🔍 Processing QR code for checkout: $qrCode');

      // Try to parse the QR code as JSON (from our check-in stickers)
      try {
        final qrData = jsonDecode(qrCode);
        if (qrData is Map<String, dynamic> &&
            qrData.containsKey('guardianQrCode') &&
            qrData.containsKey('pickupCodes') &&
            qrData.containsKey('childIds')) {
          // Validate that the required fields are not null and are of correct types
          final guardianQrCode = qrData['guardianQrCode'];
          final pickupCodes = qrData['pickupCodes'];
          final childIds = qrData['childIds'];

          if (guardianQrCode == null ||
              pickupCodes == null ||
              childIds == null) {
            throw Exception('QR code data contains null values');
          }

          if (guardianQrCode is! String) {
            throw Exception('Guardian QR code must be a string');
          }

          if (pickupCodes is! List) {
            throw Exception('Pickup codes must be a list');
          }

          if (childIds is! List) {
            throw Exception('Child IDs must be a list');
          }

          _scannedQrData = qrData;

          // Fetch child names for better user experience
          try {
            final childIdsList = childIds.cast<String>();
            _childInfo = await _fetchChildNames(childIdsList);
            print(
                '✅ Child names fetched: ${_childInfo!.map((c) => c['name']).join(', ')}');
          } catch (e) {
            print('⚠️ Could not fetch child names: $e');
            _childInfo = null;
          }

          print('✅ QR code parsed successfully:');
          print('   👤 Guardian ID: $guardianQrCode');
          print('   🎫 Pickup Codes: $pickupCodes');
          print('   👶 ChildrenIds: $childIds');

          _clearError();
          return true;
        } else {
          throw Exception('Invalid QR code format');
        }
      } catch (e) {
        print('❌ Failed to parse QR code as JSON: $e');
        _setError(
            'Invalid QR code format. Please scan a valid check-in sticker.');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check out children using scanned QR data
  Future<bool> checkOutChildrenFromQr() async {
    if (_scannedQrData == null) {
      _setError('No QR data available. Please scan a check-in sticker first.');
      return false;
    }

    _setLoading(true);
    try {
      final qrData = _scannedQrData!;

      // Safely extract and validate the data
      final guardianId = qrData['guardianQrCode'];
      final pickupCodesRaw = qrData['pickupCodes'];
      final childIdsRaw = qrData['childIds'];

      // Validate data types
      if (guardianId is! String) {
        throw Exception('Invalid guardian ID format');
      }

      if (pickupCodesRaw is! List) {
        throw Exception('Invalid pickup codes format');
      }

      if (childIdsRaw is! List) {
        throw Exception('Invalid child IDs format');
      }

      // Convert to proper types with null safety
      final pickupCodes = pickupCodesRaw
          .where((item) => item != null)
          .map((item) => item.toString())
          .toList();

      final childIds = childIdsRaw
          .where((item) => item != null)
          .map((item) => item.toString())
          .toList();

      // Validate that we have data
      if (guardianId.isEmpty) {
        throw Exception('Guardian ID is empty');
      }

      if (pickupCodes.isEmpty) {
        throw Exception('No pickup codes found');
      }

      if (childIds.isEmpty) {
        throw Exception('No child IDs found');
      }

      print('🚀 Starting checkout process:');
      print('   👤 Guardian ID: $guardianId');
      print('   🎫 Pickup Codes: $pickupCodes');
      print('   👶 ChildrenIds: $childIds');

      // Call the checkin provider to check out children
      final attendanceRecords = await _checkinProvider.checkOutChildren(
        guardianId: guardianId,
        childIds: childIds,
        pickupCodes: pickupCodes,
      );

      if (attendanceRecords.isNotEmpty) {
        _setSuccessMessage(
            'Successfully checked out ${attendanceRecords.length} child(ren)!');
        _clearError();
        return true;
      } else {
        _setError(
            'No children were checked out. Please verify the information.');
        return false;
      }
    } catch (e) {
      print('💥 Error during checkout: $e');
      _setError('Checkout failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify pickup code for a specific child
  Future<bool> verifyPickupCode(String pickupCode, String childId) async {
    _setLoading(true);
    try {
      final isValid = await _verifyPickupCodeUseCase(pickupCode, childId);
      if (isValid) {
        _clearError();
        return true;
      } else {
        _setError('Invalid pickup code or child mismatch');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Legacy checkout method for single child
  Future<void> checkOutChild(String sessionId, String volunteerId) async {
    _setLoading(true);
    try {
      final session = await _checkOutChildUseCase(sessionId, volunteerId);
      _verifiedSession = session;
      _setSuccessMessage('Child checked out successfully!');
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void startNFCScanning(Function(String) onRfidRead) {
    _isScanning = true;
    notifyListeners();

    // NFC service temporarily disabled
    // _nfcService.startReading(
    //   onTagRead: (rfidCode) {
    //     _isScanning = false;
    //     onRfidRead(rfidCode);
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

  void clearSession() {
    _verifiedSession = null;
    _scannedQrData = null;
    _childInfo = null;
    _clearError();
    _clearSuccess();
    notifyListeners();
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
    _successMessage = message;
    notifyListeners();
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
