import 'package:equatable/equatable.dart';

/// One row of the Attendance Summary list — a single child's check-in
/// (and, once released, check-out) for a given day.
class AttendanceRecordEntry extends Equatable {
  final String id;
  final String childName;
  final String ageGroup;
  final String guardianName;
  final String serviceName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;

  const AttendanceRecordEntry({
    required this.id,
    required this.childName,
    required this.ageGroup,
    required this.guardianName,
    required this.serviceName,
    required this.checkInTime,
    this.checkOutTime,
  });

  bool get isCheckedIn => checkOutTime == null;

  @override
  List<Object?> get props => [
        id,
        childName,
        ageGroup,
        guardianName,
        serviceName,
        checkInTime,
        checkOutTime
      ];
}

/// The Attendance Summary screen's full report for a day: the stat-card
/// counts plus the list of records they're derived from.
class AttendanceSummary extends Equatable {
  final int totalSessions;
  final int activeSessions;
  final int completedSessions;
  final List<AttendanceRecordEntry> records;

  const AttendanceSummary({
    required this.totalSessions,
    required this.activeSessions,
    required this.completedSessions,
    required this.records,
  });

  static const empty = AttendanceSummary(
    totalSessions: 0,
    activeSessions: 0,
    completedSessions: 0,
    records: [],
  );

  @override
  List<Object?> get props =>
      [totalSessions, activeSessions, completedSessions, records];
}
