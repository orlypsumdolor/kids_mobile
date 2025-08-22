import 'package:equatable/equatable.dart';

class Guardian extends Equatable {
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

  const Guardian({
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

  // Helper getters for backward compatibility
  String get firstName => fullName.split(' ').first;
  String get lastName => fullName.split(' ').length > 1
      ? fullName.split(' ').skip(1).join(' ')
      : '';

  bool get isPickupCodeValid {
    if (pickupCodeExpiry == null) return true;
    return DateTime.now().isBefore(pickupCodeExpiry!);
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phone,
        address,
        emergencyContact,
        pickupCode,
        pickupCodeExpiry,
        isActive,
        children,
        createdBy,
        updatedBy,
        createdAt,
        updatedAt,
      ];
}
