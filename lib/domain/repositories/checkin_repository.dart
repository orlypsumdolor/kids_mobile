import '../entities/child.dart';
import '../entities/checkin_session.dart';

abstract class CheckinRepository {
  Future<Child?> getChildByQrCode(String qrCode);
  Future<Child?> getChildByRfidCode(String rfidCode);
  Future<CheckInSession> checkInChild(
      String childId, String volunteerId, String serviceSession);
  Future<CheckInSession> checkOutChild(String sessionId, String volunteerId);
  Future<bool> verifyPickupCode(String pickupCode, String childId);
  Future<List<CheckInSession>> getActiveCheckins();
  Future<List<CheckInSession>> getAttendanceSummary(DateTime date);
}
