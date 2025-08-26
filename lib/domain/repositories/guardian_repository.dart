import '../entities/guardian.dart';
import '../entities/child.dart';

abstract class GuardianRepository {
  /// Get guardian by QR code
  Future<Guardian?> getGuardianByQrCode(String qrCode);

  /// Get guardian by RFID tag
  Future<Guardian?> getGuardianByRfidTag(String rfidTag);

  /// Get guardian with linked children
  Future<Map<String, dynamic>?> getGuardianWithChildren(String guardianId);

  /// Get guardian by ID
  Future<Guardian?> getGuardianById(String guardianId);

  /// Link child to guardian
  Future<bool> linkChildToGuardian(String guardianId, String childId);

  /// Unlink child from guardian
  Future<bool> unlinkChildFromGuardian(String guardianId, String childId);

  /// Create new guardian
  Future<Guardian?> createGuardian(Guardian guardian);

  /// Update guardian
  Future<bool> updateGuardian(Guardian guardian);

  /// Get all guardians
  Future<List<Guardian>> getAllGuardians();
}
