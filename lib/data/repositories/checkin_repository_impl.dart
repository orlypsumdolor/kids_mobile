import '../../domain/entities/child.dart';
import '../../domain/entities/checkin_session.dart';
import '../../domain/repositories/checkin_repository.dart';
import '../datasources/remote/api_service.dart';
import '../datasources/local/database_helper.dart';
import '../models/child_model.dart';
import '../models/checkin_session_model.dart';
import 'package:uuid/uuid.dart';

class CheckinRepositoryImpl implements CheckinRepository {
  final ApiService _apiService;
  final DatabaseHelper _databaseHelper;
  final Uuid _uuid = const Uuid();

  CheckinRepositoryImpl({
    required ApiService apiService,
    required DatabaseHelper databaseHelper,
  })  : _apiService = apiService,
        _databaseHelper = databaseHelper;

  @override
  Future<Child?> getChildByQrCode(String qrCode) async {
    try {
      // Try local database first
      final localResults = await _databaseHelper.query(
        'children',
        where: 'qr_code = ? AND is_active = 1',
        whereArgs: [qrCode],
      );

      if (localResults.isNotEmpty) {
        final childModel = ChildModel.fromJson(localResults.first);
        return childModel.toEntity();
      }

      // If not found locally and online, try API
      if (await _apiService.isOnline()) {
        final response = await _apiService.getChildByQrCode(qrCode);
        if (response.data['success'] == true &&
            response.data['data'].isNotEmpty) {
          final childModel = ChildModel.fromJson(response.data['data'][0]);

          // Cache in local database
          await _databaseHelper.insert('children', childModel.toJson());

          return childModel.toEntity();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Child?> getChildByRfidCode(String rfidCode) async {
    try {
      // Try local database first
      final localResults = await _databaseHelper.query(
        'children',
        where: 'rfid_code = ? AND is_active = 1',
        whereArgs: [rfidCode],
      );

      if (localResults.isNotEmpty) {
        final childModel = ChildModel.fromJson(localResults.first);
        return childModel.toEntity();
      }

      // If not found locally and online, try API
      if (await _apiService.isOnline()) {
        final response = await _apiService.getChildByRfidCode(rfidCode);
        if (response.data['success'] == true &&
            response.data['data'].isNotEmpty) {
          final childModel = ChildModel.fromJson(response.data['data'][0]);

          // Cache in local database
          await _databaseHelper.insert('children', childModel.toJson());

          return childModel.toEntity();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<CheckInSession> checkInChild(
      String childId, String volunteerId, String serviceSession) async {
    final sessionId = _uuid.v4();
    final pickupCode = _generatePickupCode();
    final now = DateTime.now();

    final sessionModel = CheckInSessionModel(
      id: sessionId,
      serviceSessionId: serviceSession,
      date: now,
      createdBy: volunteerId,
      checkedInChildren: [childId],
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    // Save locally first
    await _databaseHelper.insert('checkin_sessions', sessionModel.toJson());

    // Try to sync with server
    if (await _apiService.isOnline()) {
      try {
        final response = await _apiService.checkInChild(
          childId: childId,
          serviceSessionId: serviceSession,
        );

        if (response.data['success'] == true) {
          // Update with server response data if needed
          final serverData = response.data['data'];
          await _databaseHelper.update(
            'checkin_sessions',
            {
              'is_synced': 1,
              'pickup_code': serverData['pickupCode'] ?? pickupCode,
            },
            where: 'id = ?',
            whereArgs: [sessionId],
          );
        }
      } catch (e) {
        // Continue with offline operation
      }
    }

    return sessionModel.toEntity();
  }

  @override
  Future<CheckInSession> checkOutChild(
      String sessionId, String volunteerId) async {
    final now = DateTime.now();

    // Get the session first
    final sessionResults = await _databaseHelper.query(
      'checkin_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (sessionResults.isEmpty) {
      throw Exception('Session not found');
    }

    final sessionData = sessionResults.first;

    // Update local database
    await _databaseHelper.update(
      'checkin_sessions',
      {
        'checkout_time': now.toIso8601String(),
        'status': 'checkedOut',
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    // Try to sync with server
    if (await _apiService.isOnline()) {
      try {
        final response = await _apiService.checkOutChild(
          recordId: sessionId,
          pickupCode: sessionData['pickup_code'],
        );

        if (response.data['success'] == true) {
          // Update sync status
          await _databaseHelper.update(
            'checkin_sessions',
            {'is_synced': 1},
            where: 'id = ?',
            whereArgs: [sessionId],
          );
        }
      } catch (e) {
        // Continue with offline operation
      }
    }

    // Return updated session
    final results = await _databaseHelper.query(
      'checkin_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    final sessionModel = CheckInSessionModel.fromJson(results.first);
    return sessionModel.toEntity();
  }

  @override
  Future<bool> verifyPickupCode(String pickupCode, String childId) async {
    try {
      // Note: verifyPickupCode API method was removed, using local verification only
      // TODO: Implement proper pickup code verification through attendance records

      // Local verification
      final results = await _databaseHelper.query(
        'checkin_sessions',
        where: 'pickup_code = ? AND child_id = ? AND status = ?',
        whereArgs: [pickupCode, childId, 'checkedIn'],
      );

      return results.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<CheckInSession>> getActiveCheckins() async {
    try {
      final results = await _databaseHelper.query(
        'checkin_sessions',
        where: 'status = ?',
        whereArgs: ['checkedIn'],
        orderBy: 'checkin_time DESC',
      );

      return results
          .map((json) => CheckInSessionModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<CheckInSession>> getAttendanceSummary(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final results = await _databaseHelper.query(
        'checkin_sessions',
        where: 'checkin_time >= ? AND checkin_time <= ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
        orderBy: 'checkin_time DESC',
      );

      return results
          .map((json) => CheckInSessionModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      return [];
    }
  }

  String _generatePickupCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';

    for (int i = 0; i < 6; i++) {
      code += chars[(random + i) % chars.length];
    }

    return code;
  }
}
