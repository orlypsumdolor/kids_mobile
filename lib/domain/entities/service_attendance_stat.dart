import 'package:equatable/equatable.dart';

/// Today's attendance count for one service, as reported by the
/// dashboard endpoint: how many children have checked in today for
/// this service in total, and how many are still checked in right now.
class ServiceAttendanceStat extends Equatable {
  final String serviceId;
  final int totalToday;
  final int stillHere;

  const ServiceAttendanceStat({
    required this.serviceId,
    required this.totalToday,
    required this.stillHere,
  });

  @override
  List<Object?> get props => [serviceId, totalToday, stillHere];
}
