import '../../domain/entities/guardian.dart';

class GuardianModel {
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

  GuardianModel({
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

  factory GuardianModel.fromJson(Map<String, dynamic> json) {
    // Handle linkedChildren - can be either full objects or just IDs
    List<String> childrenIds = [];
    if (json['linkedChildren'] != null) {
      if (json['linkedChildren'] is List) {
        for (var child in json['linkedChildren']) {
          if (child is Map<String, dynamic>) {
            // Full child object - extract the ID
            childrenIds.add(child['_id'] ?? child['id'] ?? '');
          } else if (child is String) {
            // Just the ID
            childrenIds.add(child);
          }
        }
      }
    }

    return GuardianModel(
      id: json['_id'] ?? json['id'] ?? '',
      guardianId: json['guardianId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      email: json['email'] ?? '',
      relationship: json['relationship'] ?? '',
      qrCode: json['qrCode'],
      rfidTag: json['rfidTag'],
      linkedChildren: childrenIds,
      isActive: json['isActive'] ?? true,
      createdBy: json['createdBy'] != null
          ? (json['createdBy'] is Map
              ? json['createdBy']['_id'] ?? json['createdBy']['id']
              : json['createdBy'].toString())
          : null,
      updatedBy: json['updatedBy'] != null
          ? (json['updatedBy'] is Map
              ? json['updatedBy']['_id'] ?? json['updatedBy']['id']
              : json['updatedBy'].toString())
          : null,
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
      'guardianId': guardianId,
      'firstName': firstName,
      'lastName': lastName,
      'contactNumber': contactNumber,
      'email': email,
      'relationship': relationship,
      'qrCode': qrCode,
      'rfidTag': rfidTag,
      'linkedChildren': linkedChildren,
      'isActive': isActive,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Guardian toEntity() {
    return Guardian(
      id: id,
      guardianId: guardianId,
      firstName: firstName,
      lastName: lastName,
      contactNumber: contactNumber,
      email: email,
      relationship: relationship,
      qrCode: qrCode,
      rfidTag: rfidTag,
      linkedChildren: linkedChildren,
      isActive: isActive,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
