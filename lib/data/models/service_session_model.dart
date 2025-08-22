import '../../domain/entities/service_session.dart';

class ServiceSessionModel {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final String dayOfWeek;
  final bool isActive;
  final String? description;
  final List<String> ageGroups;
  final int? maxCapacity;
  final String createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceSessionModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    required this.isActive,
    this.description,
    required this.ageGroups,
    this.maxCapacity,
    required this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceSessionModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(String? dateString) {
      if (dateString == null) return DateTime.now();
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        print('Error parsing date: $dateString, error: $e');
        return DateTime.now();
      }
    }

    return ServiceSessionModel(
      id: json['_id'] ?? json['id'] ?? 'unknown_id',
      name: json['name'] ?? 'Unknown Service',
      startTime: json['startTime'] ?? '00:00',
      endTime: json['endTime'] ?? '01:00',
      dayOfWeek: json['dayOfWeek'] ?? 'sunday',
      isActive: json['isActive'] ?? true,
      description: json['description'],
      ageGroups: (() {
        try {
          if (json['ageGroups'] == null) return <String>[];
          if (json['ageGroups'] is List) {
            return List<String>.from(json['ageGroups']);
          }
          return <String>[];
        } catch (e) {
          print('Error parsing ageGroups: ${json['ageGroups']}, error: $e');
          return <String>[];
        }
      })(),
      maxCapacity: json['maxCapacity'],
      createdBy: json['createdBy'] == null
          ? 'Unknown'
          : json['createdBy'] is String
              ? json['createdBy']
              : json['createdBy']['_id'] ?? 'Unknown',
      updatedBy: json['updatedBy'] == null
          ? null
          : json['updatedBy'] is String
              ? json['updatedBy']
              : json['updatedBy']['_id'],
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'dayOfWeek': dayOfWeek,
      'isActive': isActive,
      'description': description,
      'ageGroups': ageGroups,
      'maxCapacity': maxCapacity,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ServiceSession toEntity() {
    return ServiceSession(
      id: id,
      name: name,
      startTime: startTime,
      endTime: endTime,
      dayOfWeek: dayOfWeek,
      isActive: isActive,
      description: description,
      ageGroups: ageGroups,
      maxCapacity: maxCapacity,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helper getters
  int? get duration {
    if (startTime.isEmpty || endTime.isEmpty) return null;

    final startParts = startTime.split(':').map(int.parse).toList();
    final endParts = endTime.split(':').map(int.parse).toList();

    if (startParts.length < 2 || endParts.length < 2) return null;

    final startMinutes = startParts[0] * 60 + startParts[1];
    final endMinutes = endParts[0] * 60 + endParts[1];

    return endMinutes - startMinutes;
  }
}
