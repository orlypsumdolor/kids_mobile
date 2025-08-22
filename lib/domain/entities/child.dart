import 'package:equatable/equatable.dart';

class Child extends Equatable {
  final String id;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String ageGroup;
  final String guardianId;
  final EmergencyContact? emergencyContact;
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

  const Child({
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

  // Helper getters for backward compatibility
  String get firstName => fullName.split(' ').first;
  String get lastName => fullName.split(' ').length > 1 ? fullName.split(' ').skip(1).join(' ') : '';
  String get rfidCode => rfidTag ?? '';
  
  int get ageInYears {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  bool get hasSpecialNotes => specialNotes != null && specialNotes!.isNotEmpty;
  bool get hasEmergencyContact => emergencyContact != null;

  @override
  List<Object?> get props => [
        id,
        fullName,
        dateOfBirth,
        gender,
        ageGroup,
        guardianId,
        emergencyContact,
        specialNotes,
        qrCode,
        rfidTag,
        isActive,
        currentlyCheckedIn,
        lastCheckIn,
        lastCheckOut,
        createdBy,
        updatedBy,
        createdAt,
        updatedAt,
      ];
}

class EmergencyContact extends Equatable {
  final String name;
  final String relationship;
  final String phone;

  const EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
  });

  @override
  List<Object?> get props => [name, relationship, phone];
}