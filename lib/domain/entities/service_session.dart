import 'package:equatable/equatable.dart';

class ServiceSession extends Equatable {
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

  const ServiceSession({
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

  bool get isCurrentlyActive {
    if (!isActive) return false;

    final now = DateTime.now();
    final today = now.weekday == 7 ? 'sunday' : _getDayName(now.weekday);

    if (today != dayOfWeek) return false;

    // Parse time strings to compare with current time
    final startParts = startTime.split(':').map(int.parse).toList();
    final endParts = endTime.split(':').map(int.parse).toList();

    if (startParts.length < 2 || endParts.length < 2) return false;

    final startMinutes = startParts[0] * 60 + startParts[1];
    final endMinutes = endParts[0] * 60 + endParts[1];
    final currentMinutes = now.hour * 60 + now.minute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  int? get duration {
    if (startTime.isEmpty || endTime.isEmpty) return null;

    final startParts = startTime.split(':').map(int.parse).toList();
    final endParts = endTime.split(':').map(int.parse).toList();

    if (startParts.length < 2 || endParts.length < 2) return null;

    final startMinutes = startParts[0] * 60 + startParts[1];
    final endMinutes = endParts[0] * 60 + endParts[1];

    return endMinutes - startMinutes;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'sunday';
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        startTime,
        endTime,
        dayOfWeek,
        isActive,
        description,
        ageGroups,
        maxCapacity,
        createdBy,
        updatedBy,
        createdAt,
        updatedAt,
      ];
}
