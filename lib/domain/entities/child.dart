import 'package:equatable/equatable.dart';

class Child extends Equatable {
  final String id;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String ageGroup;
  final List<String> guardianIds; // Changed from single guardianId to list
  final EmergencyContact? emergencyContact;
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

  const Child({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.ageGroup,
    required this.guardianIds, // Updated parameter
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
  String get qrCodeValue => qrCode ?? '';

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

  // New helper getters for guardian support
  bool get hasGuardians => guardianIds.isNotEmpty;
  String? get primaryGuardianId =>
      guardianIds.isNotEmpty ? guardianIds.first : null;

  @override
  List<Object?> get props => [
        id,
        fullName,
        dateOfBirth,
        gender,
        ageGroup,
        guardianIds, // Updated
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
