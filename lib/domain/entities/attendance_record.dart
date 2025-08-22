import 'package:equatable/equatable.dart';

enum AttendanceStatus { active, completed }

class AttendanceRecord extends Equatable {
  final String id;
  final String childId;
  final String serviceSessionId;
  final DateTime serviceDate;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String checkedInBy;
  final String? checkedOutBy;
  final String? pickupCode;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.childId,
    required this.serviceSessionId,
    required this.serviceDate,
    required this.checkInTime,
    this.checkOutTime,
    required this.checkedInBy,
    this.checkedOutBy,
    this.pickupCode,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration? get duration {
    if (checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime);
  }

  bool get isActive => checkOutTime == null;
  
  AttendanceStatus get status => isActive ? AttendanceStatus.active : AttendanceStatus.completed;

  // Helper getters for backward compatibility
  String get serviceId => serviceSessionId;
  String get volunteerId => checkedInBy;
  DateTime get checkinTime => checkInTime;
  DateTime? get checkoutTime => checkOutTime;


  @override
  List<Object?> get props => [
        id,
        childId,
        serviceSessionId,
        serviceDate,
        checkInTime,
        checkOutTime,
        checkedInBy,
        checkedOutBy,
        pickupCode,
        notes,
        createdAt,
        updatedAt,
      ];
}