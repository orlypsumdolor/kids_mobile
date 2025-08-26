import '../entities/child.dart';
import '../entities/checkin_session.dart';
import '../entities/attendance_record.dart';
import '../entities/guardian.dart';

abstract class CheckinRepository {
  // Guardian-based operations
  Future<Guardian?> getGuardianByQrCode(String qrCode);
  Future<Guardian?> getGuardianByRfidTag(String rfidTag);
  Future<Map<String, dynamic>?> getGuardianWithChildren(String guardianId);

  // Guardian-based check-in
  Future<List<AttendanceRecord>> checkInChildren({
    required String guardianId,
    required String serviceId,
    required List<String> childIds,
  });

  // Guardian-based check-out
  Future<List<AttendanceRecord>> checkOutChildren({
    required String guardianId,
    required List<String> childIds,
  });

  // Get current checked-in children for a guardian
  Future<List<AttendanceRecord>> getGuardianCurrentCheckins(String guardianId);

  // Legacy methods for backward compatibility
  Future<Child?> getChildByQrCode(String qrCode);
  Future<Child?> getChildByRfidCode(String rfidCode);
  Future<AttendanceRecord> checkInChild(
      String childId, String volunteerId, String serviceSession);
  Future<CheckInSession> checkOutChild(String sessionId, String volunteerId);
  Future<bool> verifyPickupCode(String pickupCode, String childId);
  Future<List<CheckInSession>> getActiveCheckins();
  Future<List<CheckInSession>> getAttendanceSummary(DateTime date);
}
