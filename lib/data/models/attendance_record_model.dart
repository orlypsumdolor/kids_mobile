import '../../domain/entities/attendance_record.dart';

class AttendanceRecordModel {
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

  AttendanceRecordModel({
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

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['_id'] ?? json['id'],
      childId: json['child'] is String ? json['child'] : json['child']['_id'],
      serviceSessionId: json['serviceSession'] is String ? json['serviceSession'] : json['serviceSession']['_id'],
      serviceDate: DateTime.parse(json['serviceDate']),
      checkInTime: DateTime.parse(json['checkInTime']),
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      checkedInBy: json['checkedInBy'] is String ? json['checkedInBy'] : json['checkedInBy']['_id'],
      checkedOutBy: json['checkedOutBy'] is String ? json['checkedOutBy'] : json['checkedOutBy']['_id'],
      pickupCode: json['pickupCode'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child': childId,
      'serviceSession': serviceSessionId,
      'serviceDate': serviceDate.toIso8601String(),
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'checkedInBy': checkedInBy,
      'checkedOutBy': checkedOutBy,
      'pickupCode': pickupCode,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AttendanceRecord toEntity() {
    return AttendanceRecord(
      id: id,
      childId: childId,
      serviceSessionId: serviceSessionId,
      serviceDate: serviceDate,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      checkedInBy: checkedInBy,
      checkedOutBy: checkedOutBy,
      pickupCode: pickupCode,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helper getters for backward compatibility
  String get serviceId => serviceSessionId;
  String get volunteerId => checkedInBy;
  String get status => checkOutTime != null ? 'completed' : 'active';
  bool get isSynced => true; // Always synced when coming from API
}