import '../../domain/entities/checkin_session.dart';

class CheckInSessionModel {
  final String id;
  final String serviceSessionId;
  final DateTime date;
  final String createdBy;
  final List<String> checkedInChildren;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CheckInSessionModel({
    required this.id,
    required this.serviceSessionId,
    required this.date,
    required this.createdBy,
    required this.checkedInChildren,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CheckInSessionModel.fromJson(Map<String, dynamic> json) {
    return CheckInSessionModel(
      id: json['_id'] ?? json['id'],
      serviceSessionId: json['serviceSession'] is String
          ? json['serviceSession']
          : json['serviceSession']['_id'],
      date: DateTime.parse(json['date']),
      createdBy: json['createdBy'] is String
          ? json['createdBy']
          : json['createdBy']['_id'],
      checkedInChildren: List<String>.from(json['checkedInChildren'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_session_id': serviceSessionId,
      'date': date.toIso8601String(),
      'created_by': createdBy,
      'checked_in_children': checkedInChildren.join(','),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CheckInSession toEntity() {
    return CheckInSession(
      id: id,
      serviceSessionId: serviceSessionId,
      date: date,
      createdBy: createdBy,
      checkedInChildren: checkedInChildren,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helper getters
  int get totalCheckedIn => checkedInChildren.length;
  bool get hasCheckedInChildren => checkedInChildren.isNotEmpty;
}
