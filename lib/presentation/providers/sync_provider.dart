import 'package:flutter/foundation.dart';
import '../../domain/usecases/sync_usecases.dart';

class SyncProvider extends ChangeNotifier {
  final SyncDataUseCase _syncDataUseCase;
  final GetPendingSyncDataUseCase _getPendingSyncDataUseCase;

  SyncProvider({
    required SyncDataUseCase syncDataUseCase,
    required GetPendingSyncDataUseCase getPendingSyncDataUseCase,
  })  : _syncDataUseCase = syncDataUseCase,
        _getPendingSyncDataUseCase = getPendingSyncDataUseCase;

  bool _isSyncing = false;
  int _pendingCount = 0;
  String? _error;
  DateTime? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  String? get error => _error;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get hasPendingData => _pendingCount > 0;

  Future<void> initialize() async {
    await checkPendingData();
  }

  Future<void> checkPendingData() async {
    try {
      _pendingCount = await _getPendingSyncDataUseCase();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    }
    notifyListeners();
  }

  Future<void> syncData() async {
    _isSyncing = true;
    notifyListeners();

    try {
      await _syncDataUseCase();
      _lastSyncTime = DateTime.now();
      await checkPendingData(); // Refresh pending count
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
  }

  void _clearError() {
    _error = null;
  }
}