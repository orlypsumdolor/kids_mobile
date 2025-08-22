import 'package:flutter/foundation.dart';
import '../../domain/entities/child.dart';
import '../../domain/entities/checkin_session.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/usecases/checkin_usecases.dart';
import '../../core/services/camera_service.dart';
// import '../../core/services/nfc_service.dart'; // Temporarily disabled
import '../../core/services/printer_service.dart';

class CheckinProvider extends ChangeNotifier {
  final CheckInChildUseCase _checkInChildUseCase;
  final GetChildByCodeUseCase _getChildByCodeUseCase;
  final GeneratePickupCodeUseCase _generatePickupCodeUseCase;
  final CameraService _cameraService;
  // final NfcService _nfcService; // Temporarily disabled
  final PrinterService _printerService;

  CheckinProvider({
    required CheckInChildUseCase checkInChildUseCase,
    required GetChildByCodeUseCase getChildByCodeUseCase,
    required GeneratePickupCodeUseCase generatePickupCodeUseCase,
    required CameraService cameraService,
    required PrinterService printerService,
  })  : _checkInChildUseCase = checkInChildUseCase,
        _getChildByCodeUseCase = getChildByCodeUseCase,
        _generatePickupCodeUseCase = generatePickupCodeUseCase,
        _cameraService = cameraService,
        _printerService = printerService;

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
          date: _currentAttendanceRecord!.serviceDate,
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
            date: session.serviceDate,
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
