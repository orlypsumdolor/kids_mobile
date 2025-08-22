import '../../domain/repositories/sync_repository.dart';
import '../datasources/remote/api_service.dart';
import '../datasources/local/database_helper.dart';
import '../datasources/local/preferences_helper.dart';

class SyncRepositoryImpl implements SyncRepository {
  final ApiService _apiService;
  final DatabaseHelper _databaseHelper;
  final PreferencesHelper _preferencesHelper;

  SyncRepositoryImpl({
    required ApiService apiService,
    required DatabaseHelper databaseHelper,
    required PreferencesHelper preferencesHelper,
  })  : _apiService = apiService,
        _databaseHelper = databaseHelper,
        _preferencesHelper = preferencesHelper;

  @override
  Future<void> syncPendingData() async {
    if (!await _apiService.isOnline()) {
      throw Exception('No internet connection available');
    }

    try {
      // Get all unsynced checkin sessions
      final unsyncedSessions = await _databaseHelper.query(
        'checkin_sessions',
        where: 'is_synced = 0',
      );

      // Sync each session
      for (final sessionData in unsyncedSessions) {
        try {
          if (sessionData['status'] == 'checkedIn') {
            // Sync check-in
            await _apiService.checkInChild(
              childId: sessionData['child_id'],
              serviceSessionId: sessionData['service_session'],
            );
          } else if (sessionData['status'] == 'checkedOut') {
            // Sync check-out
            await _apiService.checkOutChild(
              recordId: sessionData['id'],
              pickupCode: sessionData['pickup_code'],
            );
          }

          // Mark as synced
          await _databaseHelper.update(
            'checkin_sessions',
            {'is_synced': 1},
            where: 'id = ?',
            whereArgs: [sessionData['id']],
          );
        } catch (e) {
          // Continue with other sessions if one fails
          continue;
        }
      }

      // Update last sync time
      await _preferencesHelper.setLastSyncTime(DateTime.now());
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }

  @override
  Future<bool> hasPendingSync() async {
    final count = await getPendingSyncCount();
    return count > 0;
  }

  @override
  Future<int> getPendingSyncCount() async {
    try {
      final results = await _databaseHelper.query(
        'checkin_sessions',
        where: 'is_synced = 0',
      );
      return results.length;
    } catch (e) {
      return 0;
    }
  }
}
