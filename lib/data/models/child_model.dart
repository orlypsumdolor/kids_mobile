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
  final String qrCode;
  final String? rfidTag;
  final bool isActive;
  final bool currentlyCheckedIn;
  final DateTime? lastCheckIn;
  final DateTime? lastCheckOut;
  final String createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChildModel({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.ageGroup,
    required this.guardianId,
    this.emergencyContact,
    this.specialNotes,
    required this.qrCode,
    this.rfidTag,
    required this.isActive,
    required this.currentlyCheckedIn,
    this.lastCheckIn,
    this.lastCheckOut,
    required this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['_id'] ?? json['id'],
      fullName: json['fullName'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      gender: json['gender'],
      ageGroup: json['ageGroup'],
      guardianId: json['guardian'] is String ? json['guardian'] : json['guardian']['_id'],
      emergencyContact: json['emergencyContact'] != null 
          ? EmergencyContactModel.fromJson(json['emergencyContact'])
          : null,
      specialNotes: json['specialNotes'],
      qrCode: json['qrCode'],
      rfidTag: json['rfidTag'],
      isActive: json['isActive'] ?? true,
      currentlyCheckedIn: json['currentlyCheckedIn'] ?? false,
      lastCheckIn: json['lastCheckIn'] != null ? DateTime.parse(json['lastCheckIn']) : null,
      lastCheckOut: json['lastCheckOut'] != null ? DateTime.parse(json['lastCheckOut']) : null,
      createdBy: json['createdBy'] is String ? json['createdBy'] : json['createdBy']['_id'],
      updatedBy: json['updatedBy'] is String ? json['updatedBy'] : json['updatedBy']['_id'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'ageGroup': ageGroup,
      'guardian': guardianId,
      'emergencyContact': emergencyContact?.toJson(),
      'specialNotes': specialNotes,
      'qrCode': qrCode,
      'rfidTag': rfidTag,
      'isActive': isActive,
      'currentlyCheckedIn': currentlyCheckedIn,
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'lastCheckOut': lastCheckOut?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
  String get firstName => fullName.split(' ').first;
  String get lastName => fullName.split(' ').length > 1 ? fullName.split(' ').skip(1).join(' ') : '';
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