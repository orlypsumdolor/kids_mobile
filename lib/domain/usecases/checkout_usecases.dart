import '../entities/checkin_session.dart';
import '../repositories/checkin_repository.dart';

class CheckOutChildUseCase {
  final CheckinRepository _repository;

  CheckOutChildUseCase(this._repository);

  Future<CheckInSession> call(String sessionId, String volunteerId) {
    return _repository.checkOutChild(sessionId, volunteerId);
  }
}

class VerifyPickupCodeUseCase {
  final CheckinRepository _repository;

  VerifyPickupCodeUseCase(this._repository);

  Future<bool> call(String pickupCode, String childId) {
    return _repository.verifyPickupCode(pickupCode, childId);
  }
}
