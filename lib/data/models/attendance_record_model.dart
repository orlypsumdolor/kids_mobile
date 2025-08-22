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
    try {
      print('AttendanceRecordModel.fromJson called with: $json');

      // Helper function to safely extract ID from object or string
      String extractId(dynamic value, String fieldName) {
        if (value == null) {
          print('Warning: $fieldName is null');
          return 'unknown_${fieldName}_id';
        }
        if (value is String) {
          return value;
        }
        if (value is Map<String, dynamic>) {
          return value['_id'] ?? 'unknown_${fieldName}_id';
        }
        print('Warning: $fieldName has unexpected type: ${value.runtimeType}');
        return 'unknown_${fieldName}_id';
      }

      // Helper function to safely parse DateTime
      DateTime parseDateTime(dynamic value, String fieldName) {
        if (value == null) {
          print('Warning: $fieldName is null, using current time');
          return DateTime.now();
        }
        try {
          return DateTime.parse(value.toString());
        } catch (e) {
          print(
              'Error parsing $fieldName: $value, error: $e, using current time');
          return DateTime.now();
        }
      }

      // Handle different API response structures
      final id = json['_id'] ?? json['id'] ?? 'unknown_id';
      final childId = extractId(json['child'], 'child');
      final serviceSessionId =
          extractId(json['serviceSession'], 'serviceSession');
      final serviceDate = parseDateTime(json['serviceDate'], 'serviceDate');
      final checkInTime = parseDateTime(json['checkInTime'], 'checkInTime');
      final checkOutTime = json['checkOutTime'] != null
          ? parseDateTime(json['checkOutTime'], 'checkOutTime')
          : null;
      final checkedInBy = extractId(json['checkedInBy'], 'checkedInBy');
      final checkedOutBy = json['checkedOutBy'] != null
          ? extractId(json['checkedOutBy'], 'checkedOutBy')
          : null;

      // Handle optional fields that might not be present in the API response
      final pickupCode = json['pickupCode'] ?? json['pickup_code'];
      final notes = json['notes'] ?? json['note'];

      final createdAt = parseDateTime(json['createdAt'], 'createdAt');
      final updatedAt = parseDateTime(json['updatedAt'], 'updatedAt');

      final model = AttendanceRecordModel(
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

      print('Successfully created AttendanceRecordModel: $model');
      return model;
    } catch (e, stackTrace) {
      print('Error in AttendanceRecordModel.fromJson: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
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
