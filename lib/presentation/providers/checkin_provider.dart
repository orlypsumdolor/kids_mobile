import 'package:flutter/foundation.dart';
import '../../domain/entities/child.dart';
import '../../domain/entities/checkin_session.dart';
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
  CheckInSession? _currentSession;
  bool _isLoading = false;
  bool _isScanning = false;
  String? _error;
  String? _successMessage;

  Child? get scannedChild => _scannedChild;
  CheckInSession? get currentSession => _currentSession;
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
      final session = await _checkInChildUseCase(
        _scannedChild!.id,
        volunteerId,
        serviceSession,
      );

      _currentSession = session;

      // Try to print sticker
      if (_printerService.isConnected) {
        try {
          await _printerService.printCheckInSticker(
            child: _scannedChild!,
            session: session,
          );
          _setSuccessMessage('Check-in successful! Sticker printed.');
        } catch (e) {
          _setSuccessMessage('Check-in successful! (Printing failed)');
        }
      } else {
        _setSuccessMessage('Check-in successful! (No printer connected)');
      }

      _clearError();
    } catch (e) {
      _setError(e.toString());
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
    _scannedChild = null;
    _currentSession = null;
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
