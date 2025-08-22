import 'package:equatable/equatable.dart';

enum UserRole { volunteer, staff, admin }

class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final DateTime? lastLogin;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.lastLogin,
    this.createdBy,
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

  UserRole get userRole {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'staff':
        return UserRole.staff;
      default:
        return UserRole.volunteer;
    }
  }

  bool get canScan =>
      userRole == UserRole.volunteer ||
      userRole == UserRole.staff ||
      userRole == UserRole.admin;
  bool get canViewReports =>
      userRole == UserRole.staff || userRole == UserRole.admin;
  bool get canManageUsers => userRole == UserRole.admin;

  // Direct role checks
  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff' || role == 'admin';
  bool get isVolunteer =>
      role == 'volunteer' || role == 'staff' || role == 'admin';

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        fullName,
        role,
        isActive,
        lastLogin,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
