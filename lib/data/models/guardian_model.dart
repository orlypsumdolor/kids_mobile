import '../../domain/entities/guardian.dart';

class GuardianModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? address;
  final String? emergencyContact;
  final String pickupCode;
  final DateTime? pickupCodeExpiry;
  final bool isActive;
  final List<String> children;
  final String createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  GuardianModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.address,
    this.emergencyContact,
    required this.pickupCode,
    this.pickupCodeExpiry,
    required this.isActive,
    required this.children,
    required this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GuardianModel.fromJson(Map<String, dynamic> json) {
    return GuardianModel(
      id: json['_id'] ?? json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      emergencyContact: json['emergencyContact'],
      pickupCode: json['pickupCode'],
      pickupCodeExpiry: json['pickupCodeExpiry'] != null
          ? DateTime.parse(json['pickupCodeExpiry'])
          : null,
      isActive: json['isActive'] ?? true,
      children: List<String>.from(json['children'] ?? []),
      createdBy: json['createdBy'] is String
          ? json['createdBy']
          : json['createdBy']['_id'],
      updatedBy: json['updatedBy'] is String
          ? json['updatedBy']
          : json['updatedBy']['_id'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'emergencyContact': emergencyContact,
      'pickupCode': pickupCode,
      'pickupCodeExpiry': pickupCodeExpiry?.toIso8601String(),
      'isActive': isActive,
      'children': children,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Guardian toEntity() {
    return Guardian(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      address: address,
      emergencyContact: emergencyContact,
      pickupCode: pickupCode,
      pickupCodeExpiry: pickupCodeExpiry,
      isActive: isActive,
      children: children,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helper getters
  String get firstName => fullName.split(' ').first;
  String get lastName => fullName.split(' ').length > 1
      ? fullName.split(' ').skip(1).join(' ')
      : '';

  bool get isPickupCodeValid {
    if (pickupCodeExpiry == null) return true;
    return DateTime.now().isBefore(pickupCodeExpiry!);
  }
}
