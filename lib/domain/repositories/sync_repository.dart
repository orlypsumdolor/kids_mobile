abstract class SyncRepository {
  Future<void> syncPendingData();
  Future<bool> hasPendingSync();
  Future<int> getPendingSyncCount();
}