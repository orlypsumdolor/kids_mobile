import '../repositories/sync_repository.dart';

class SyncDataUseCase {
  final SyncRepository _repository;

  SyncDataUseCase(this._repository);

  Future<void> call() {
    return _repository.syncPendingData();
  }
}

class GetPendingSyncDataUseCase {
  final SyncRepository _repository;

  GetPendingSyncDataUseCase(this._repository);

  Future<int> call() {
    return _repository.getPendingSyncCount();
  }
}