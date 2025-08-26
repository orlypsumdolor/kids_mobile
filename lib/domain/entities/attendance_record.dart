import 'package:equatable/equatable.dart';

enum AttendanceStatus { checkedIn, checkedOut }

class AttendanceRecord extends Equatable {
  final String id;
  final String childId;
  final String guardianId; // Added guardian ID for guardian-based check-in
  final String serviceId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String pickupCode; // Unique pickup code per child & service
  final bool stickerPrinted;
  final AttendanceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.childId,
    required this.guardianId, // Added
    required this.serviceId,
    required this.checkInTime,
    this.checkOutTime,
    required this.pickupCode,
    required this.stickerPrinted,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration? get duration {
    if (checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime);
  }

  bool get isActive => status == AttendanceStatus.checkedIn;

  // Helper getters for backward compatibility
  String get serviceSessionId => serviceId;
  String get serviceDate => checkInTime.toIso8601String();
  String get checkedInBy => guardianId;
  String? get checkedOutBy => checkOutTime != null ? guardianId : null;
  String? get notes => null;

  @override
  List<Object?> get props => [
        id,
        childId,
        guardianId, // Added
        serviceId,
        checkInTime,
        checkOutTime,
        pickupCode,
        stickerPrinted,
        status,
        createdAt,
        updatedAt,
      ];
}
