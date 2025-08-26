import '../../domain/entities/attendance_record.dart';

class AttendanceRecordModel {
  final String id;
  final String childId;
  final String guardianId; // Added guardian ID
  final String serviceId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String pickupCode;
  final bool stickerPrinted;
  final AttendanceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceRecordModel({
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

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    // Handle nested objects for childId, guardianId, and serviceId
    String extractId(dynamic idField) {
      if (idField is Map<String, dynamic>) {
        final extractedId = idField['_id'] ?? idField['id'] ?? '';
        print('🔍 Extracted ID from object: $extractedId (from: $idField)');
        return extractedId;
      } else if (idField is String) {
        print('🔍 Using string ID directly: $idField');
        return idField;
      }
      print('⚠️ Unknown ID field type: ${idField.runtimeType}');
      return '';
    }

    return AttendanceRecordModel(
      id: json['_id'] ?? json['id'] ?? '',
      childId: extractId(json['childId']),
      guardianId: extractId(json['guardianId']),
      serviceId: extractId(json['serviceId']),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : DateTime.now(),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
          : null,
      pickupCode: json['pickupCode'] ?? '',
      stickerPrinted: json['stickerPrinted'] ?? false,
      status: json['status'] == 'checked-out'
          ? AttendanceStatus.checkedOut
          : AttendanceStatus.checkedIn,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'guardianId': guardianId, // Added
      'serviceId': serviceId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'pickupCode': pickupCode,
      'stickerPrinted': stickerPrinted,
      'status':
          status == AttendanceStatus.checkedOut ? 'checked-out' : 'checked-in',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AttendanceRecord toEntity() {
    return AttendanceRecord(
      id: id,
      childId: childId,
      guardianId: guardianId, // Added
      serviceId: serviceId,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      pickupCode: pickupCode,
      stickerPrinted: stickerPrinted,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
