import '../entities/service_session.dart';

abstract class ServiceRepository {
  Future<List<ServiceSession>> getServiceSessions();
  Future<ServiceSession?> getServiceSessionById(String id);
}
