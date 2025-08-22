import 'package:flutter/foundation.dart';
import '../../domain/entities/checkin_session.dart';
import '../../domain/usecases/checkout_usecases.dart';
import '../../core/services/camera_service.dart';
// import '../../core/services/nfc_service.dart'; // Temporarily disabled

class CheckoutProvider extends ChangeNotifier {
  final CheckOutChildUseCase _checkOutChildUseCase;
  final VerifyPickupCodeUseCase _verifyPickupCodeUseCase;
  final CameraService _cameraService;
  // final NfcService _nfcService; // Temporarily disabled

  CheckoutProvider({
    required CheckOutChildUseCase checkOutChildUseCase,
    required VerifyPickupCodeUseCase verifyPickupCodeUseCase,
    required CameraService cameraService,
  })  : _checkOutChildUseCase = checkOutChildUseCase,
        _verifyPickupCodeUseCase = verifyPickupCodeUseCase,
        _cameraService = cameraService;

  CheckInSession? _verifiedSession;
  bool _isLoading = false;
  bool _isScanning = false;
  String? _error;
  String? _successMessage;

  CheckInSession? get verifiedSession => _verifiedSession;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  String? get error => _error;
  String? get successMessage => _successMessage;

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
