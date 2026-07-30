import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_shell_header.dart';
import '../../providers/attendance_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/attendance_record_entry.dart';

class AttendanceSummaryPage extends StatefulWidget {
  const AttendanceSummaryPage({super.key});

  @override
  State<AttendanceSummaryPage> createState() => _AttendanceSummaryPageState();
}

class _AttendanceSummaryPageState extends State<AttendanceSummaryPage> {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().loadAttendance(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final printerConnected = context.watch<PrinterService>().isConnected;
    final attendanceProvider = context.watch<AttendanceProvider>();
    final summary = attendanceProvider.summary;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: Column(
        children: [
          AppShellHeader(
            title: 'Attendance',
            subtitle: _formatDate(selectedDate),
            showBackButton: true,
            onBack: () => context.pop(),
            onSettings: () => context.push(AppRouter.settings),
            printerConnected: printerConnected,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.edit_calendar, size: 18),
                          label: const Text('Change date'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Check-ins',
                            value: '${summary.totalSessions}',
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Still Here',
                            value: '${summary.activeSessions}',
                            color: AppTheme.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Completed',
                            value: '${summary.completedSessions}',
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (attendanceProvider.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ErrorBanner(message: attendanceProvider.error!),
                    ),
                  const SizedBox(height: 4),

                  // Attendance List
                  Expanded(
                    child: attendanceProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: AppTheme.navy))
                        : summary.records.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.event_busy,
                                      size: 64,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No attendance records',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'for ${_formatDate(selectedDate)}',
                                      style: const TextStyle(color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                                  border: Border.all(color: AppTheme.hairline),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemCount: summary.records.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1, color: AppTheme.hairline),
                                  itemBuilder: (context, index) {
                                    return _AttendanceRow(
                                        record: summary.records[index], index: index);
                                  },
                                ),
                              ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate && mounted) {
      setState(() {
        selectedDate = picked;
      });
      context.read<AttendanceProvider>().loadAttendance(selectedDate);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        border: Border.all(color: AppTheme.errorBorder, width: 1.5),
      ),
      child: Text(
        'Could not load attendance: $message',
        style: const TextStyle(fontSize: 12.5, color: AppTheme.error),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final AttendanceRecordEntry record;
  final int index;

  const _AttendanceRow({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    const barColors = [AppTheme.green, AppTheme.blue, AppTheme.yellow, AppTheme.magenta];
    final checkInLabel = DateFormat('h:mm a').format(record.checkInTime.toLocal());
    final checkOutLabel = record.checkOutTime != null
        ? DateFormat('h:mm a').format(record.checkOutTime!.toLocal())
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              color: barColors[index % barColors.length],
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record.childName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${record.guardianName} · In $checkInLabel'
                  '${checkOutLabel != null ? ' · Out $checkOutLabel' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: record.isCheckedIn ? const Color(0xFFE6F5EA) : AppTheme.chipNeutralBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              record.isCheckedIn ? 'Here' : 'Out',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: record.isCheckedIn ? const Color(0xFF1F6E39) : AppTheme.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
