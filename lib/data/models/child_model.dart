import '../../domain/entities/child.dart';

class ChildModel {
  final String id;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String ageGroup;
  final String guardianId;
  final EmergencyContactModel? emergencyContact;
  final String? specialNotes;
  final String? qrCode;
  final String? rfidTag;
  final bool isActive;
  final bool currentlyCheckedIn;
  final DateTime? lastCheckIn;
  final DateTime? lastCheckOut;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChildModel({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.ageGroup,
    required this.guardianId,
    this.emergencyContact,
    this.specialNotes,
    this.qrCode,
    this.rfidTag,
    required this.isActive,
    required this.currentlyCheckedIn,
    this.lastCheckIn,
    this.lastCheckOut,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    try {
      print('ChildModel.fromJson called with: $json');

      // Extract guardian ID safely
      String? guardianId;
      if (json['guardian'] != null) {
        if (json['guardian'] is String) {
          guardianId = json['guardian'];
        } else if (json['guardian'] is Map) {
          guardianId = json['guardian']['_id'];
        }
      }

      // Extract createdBy safely
      String? createdBy;
      if (json['createdBy'] != null) {
        if (json['createdBy'] is String) {
          createdBy = json['createdBy'];
        } else if (json['createdBy'] is Map) {
          createdBy = json['createdBy']['_id'];
        }
      }

      // Extract updatedBy safely
      String? updatedBy;
      if (json['updatedBy'] != null) {
        if (json['updatedBy'] is String) {
          updatedBy = json['updatedBy'];
        } else if (json['updatedBy'] is Map) {
          updatedBy = json['updatedBy']['_id'];
        }
      }

      final childModel = ChildModel(
        id: json['_id'] ?? json['id'] ?? '',
        fullName: json['fullName'] ?? '',
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.parse(json['dateOfBirth'])
            : DateTime.now(),
        gender: json['gender'] ?? '',
        ageGroup: json['ageGroup'] ?? '',
        guardianId: guardianId ?? '',
        emergencyContact: json['emergencyContact'] != null
            ? EmergencyContactModel.fromJson(json['emergencyContact'])
            : null,
        specialNotes: json['specialNotes'] ?? '',
        qrCode: json['qrCode'] ?? '',
        rfidTag: json['rfidTag'] ?? '',
        isActive: json['isActive'] ?? true,
        currentlyCheckedIn: json['currentlyCheckedIn'] ?? false,
        lastCheckIn: json['lastCheckIn'] != null
            ? DateTime.parse(json['lastCheckIn'])
            : null,
        lastCheckOut: json['lastCheckOut'] != null
            ? DateTime.parse(json['lastCheckOut'])
            : null,
        createdBy: createdBy ?? '',
        updatedBy: updatedBy,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );

      print('ChildModel created successfully: $childModel');
      return childModel;
    } catch (e, stackTrace) {
      print('Error in ChildModel.fromJson: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'age_group': ageGroup,
      'guardian_id': guardianId,
      'emergency_contact': emergencyContact?.toJson().toString(),
      'special_notes': specialNotes,
      'qr_code': qrCode,
      'rfid_tag': rfidTag,
      'is_active': isActive ? 1 : 0,
      'currently_checked_in': currentlyCheckedIn ? 1 : 0,
      'last_check_in': lastCheckIn?.toIso8601String(),
      'last_check_out': lastCheckOut?.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Child toEntity() {
    return Child(
      id: id,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      ageGroup: ageGroup,
      guardianId: guardianId,
      emergencyContact: emergencyContact?.toEntity(),
      specialNotes: specialNotes,
      qrCode: qrCode,
      rfidTag: rfidTag,
      isActive: isActive,
      currentlyCheckedIn: currentlyCheckedIn,
      lastCheckIn: lastCheckIn,
      lastCheckOut: lastCheckOut,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helper getters for backward compatibility
  String get firstName {
    if (fullName.isEmpty) return '';
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  String get lastName {
    if (fullName.isEmpty) return '';
    final parts = fullName.split(' ');
    return parts.length > 1 ? parts.skip(1).join(' ') : '';
  }

  String get rfidCode => rfidTag ?? '';
}

class EmergencyContactModel {
  final String name;
  final String relationship;
  final String phone;

  EmergencyContactModel({
    required this.name,
    required this.relationship,
    required this.phone,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      name: json['name'],
      relationship: json['relationship'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
    };
  }

  EmergencyContact toEntity() {
    return EmergencyContact(
      name: name,
      relationship: relationship,
      phone: phone,
    );
  }
}
