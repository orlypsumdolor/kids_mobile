import '../entities/child.dart';
import '../entities/checkin_session.dart';
import '../repositories/checkin_repository.dart';

class GetChildByCodeUseCase {
  final CheckinRepository _repository;

  GetChildByCodeUseCase(this._repository);

  Future<Child?> byQrCode(String qrCode) {
    return _repository.getChildByQrCode(qrCode);
  }

  Future<Child?> byRfidCode(String rfidCode) {
    return _repository.getChildByRfidCode(rfidCode);
  }
}

class CheckInChildUseCase {
  final CheckinRepository _repository;

  CheckInChildUseCase(this._repository);

  Future<CheckInSession> call(
      String childId, String volunteerId, String serviceSession) {
    return _repository.checkInChild(childId, volunteerId, serviceSession);
  }
}

class GeneratePickupCodeUseCase {
  GeneratePickupCodeUseCase(this._repository);

  final CheckinRepository _repository;

  String call() {
    // Generate a 6-digit alphanumeric code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';

    for (int i = 0; i < 6; i++) {
      code += chars[(random + i) % chars.length];
    }

    return code;
  }
}
