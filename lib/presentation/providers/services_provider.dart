import 'package:flutter/foundation.dart';
import '../../domain/entities/service_session.dart';
import '../../domain/usecases/service_usecases.dart';

class ServicesProvider extends ChangeNotifier {
  final GetServiceSessionsUseCase _getServiceSessionsUseCase;

  ServicesProvider({
    required GetServiceSessionsUseCase getServiceSessionsUseCase,
  }) : _getServiceSessionsUseCase = getServiceSessionsUseCase;

  List<ServiceSession> _services = [];
  bool _isLoading = false;
  String? _error;

  List<ServiceSession> get services => _services;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadServices() async {
    _setLoading(true);
    try {
      print('Loading services...');
      _services = await _getServiceSessionsUseCase();
      print('Services loaded successfully: ${_services.length} services');
      _clearError();
    } catch (e, stackTrace) {
      print('Error in ServicesProvider: $e');
      print('Stack trace: $stackTrace');
      _setError(e.toString());
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
}
