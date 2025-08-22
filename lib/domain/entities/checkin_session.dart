import 'package:equatable/equatable.dart';

enum SessionStatus { active, completed }

class CheckInSession extends Equatable {
  final String id;
  final String serviceSessionId;
  final DateTime date;
  final String createdBy;
  final List<String> checkedInChildren;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CheckInSession({
    required this.id,
    required this.serviceSessionId,
    required this.date,
    required this.createdBy,
    required this.checkedInChildren,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper getters for backward compatibility
  String get childId {
    if (checkedInChildren.isEmpty) return '';
    return checkedInChildren.first;
  }

  String get volunteerId => createdBy;
  String get serviceSession => serviceSessionId;
  String get pickupCode => ''; // Not applicable for session-level entity
  DateTime get checkinTime => createdAt;
  DateTime? get checkoutTime => isActive ? null : updatedAt;
  SessionStatus get status =>
      isActive ? SessionStatus.active : SessionStatus.completed;

  Duration? get duration {
    if (checkoutTime == null) return null;
    return checkoutTime!.difference(checkinTime);
  }

  bool get isCurrentlyActive => isActive;

  @override
  List<Object?> get props => [
        id,
        serviceSessionId,
        date,
        createdBy,
        checkedInChildren,
        isActive,
        createdAt,
        updatedAt,
      ];
}
