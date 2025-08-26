import 'package:equatable/equatable.dart';

class Guardian extends Equatable {
  final String id;
  final String guardianId;
  final String firstName;
  final String lastName;
  final String contactNumber;
  final String email;
  final String relationship;
  final String? qrCode;
  final String? rfidTag;
  final List<String> linkedChildren;
  final bool isActive;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Guardian({
    required this.id,
    required this.guardianId,
    required this.firstName,
    required this.lastName,
    required this.contactNumber,
    required this.email,
    required this.relationship,
    this.qrCode,
    this.rfidTag,
    required this.linkedChildren,
    this.isActive = true,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get hasQrCode => qrCode != null && qrCode!.isNotEmpty;
  bool get hasRfidTag => rfidTag != null && rfidTag!.isNotEmpty;
  bool get hasLinkedChildren => linkedChildren.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        guardianId,
        firstName,
        lastName,
        contactNumber,
        email,
        relationship,
        qrCode,
        rfidTag,
        linkedChildren,
        isActive,
        createdBy,
        updatedBy,
        createdAt,
        updatedAt,
      ];
}
