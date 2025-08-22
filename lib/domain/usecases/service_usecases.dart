import '../entities/service_session.dart';
import '../repositories/service_repository.dart';

class GetServiceSessionsUseCase {
  final ServiceRepository _repository;

  GetServiceSessionsUseCase(this._repository);

  Future<List<ServiceSession>> call() async {
    return await _repository.getServiceSessions();
  }
}

class GetServiceSessionByIdUseCase {
  final ServiceRepository _repository;

  GetServiceSessionByIdUseCase(this._repository);

  Future<ServiceSession?> call(String id) async {
    return await _repository.getServiceSessionById(id);
  }
}
