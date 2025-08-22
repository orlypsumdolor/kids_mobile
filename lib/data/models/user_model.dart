import '../../domain/entities/user.dart';

class UserModel {
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

  UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['fullName'],
      role: json['role'],
      isActive: json['isActive'] ?? true,
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      createdBy: json['createdBy'] is String
          ? json['createdBy']
          : json['createdBy']?['_id'],
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
      'username': username,
      'email': email,
      'fullName': fullName,
      'role': role,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  User toEntity() {
    return User(
      id: id,
      username: username,
      email: email,
      fullName: fullName,
      role: role,
      isActive: isActive,
      lastLogin: lastLogin,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helper getters
  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff' || role == 'admin';
  bool get isVolunteer =>
      role == 'volunteer' || role == 'staff' || role == 'admin';
}
