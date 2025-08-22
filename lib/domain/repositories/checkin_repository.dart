import '../entities/child.dart';
import '../entities/checkin_session.dart';
import '../entities/attendance_record.dart';

abstract class CheckinRepository {
  Future<Child?> getChildByQrCode(String qrCode);
  Future<Child?> getChildByRfidCode(String rfidCode);
  Future<AttendanceRecord> checkInChild(
      String childId, String volunteerId, String serviceSession);
  Future<CheckInSession> checkOutChild(String sessionId, String volunteerId);
  Future<bool> verifyPickupCode(String pickupCode, String childId);
  Future<List<CheckInSession>> getActiveCheckins();
  Future<List<CheckInSession>> getAttendanceSummary(DateTime date);
}
