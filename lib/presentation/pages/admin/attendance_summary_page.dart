import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_shell_header.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/theme/app_theme.dart';

class AttendanceSummaryPage extends StatefulWidget {
  const AttendanceSummaryPage({super.key});

  @override
  State<AttendanceSummaryPage> createState() => _AttendanceSummaryPageState();
}

class _AttendanceSummaryPageState extends State<AttendanceSummaryPage> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> attendanceData = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      isLoading = true;
    });

    // Mock data - in real app, this would come from API
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      attendanceData = [
        {
          'childName': 'Emma Johnson',
          'guardianName': 'Sarah Johnson',
          'checkinTime': '9:15 AM',
          'checkoutTime': '11:30 AM',
          'service': 'Sunday Morning',
          'status': 'Completed',
        },
        {
          'childName': 'Liam Smith',
          'guardianName': 'Mike Smith',
          'checkinTime': '9:20 AM',
          'checkoutTime': null,
          'service': 'Sunday Morning',
          'status': 'Checked In',
        },
        {
          'childName': 'Olivia Brown',
          'guardianName': 'Lisa Brown',
          'checkinTime': '9:25 AM',
          'checkoutTime': '11:45 AM',
          'service': 'Sunday Morning',
          'status': 'Completed',
        },
      ];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final printerConnected = context.watch<PrinterService>().isConnected;

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
                            value: '${attendanceData.length}',
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Still Here',
                            value:
                                '${attendanceData.where((a) => a['status'] == 'Checked In').length}',
                            color: AppTheme.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Completed',
                            value:
                                '${attendanceData.where((a) => a['status'] == 'Completed').length}',
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _SampleDataBanner(),
                  ),
                  const SizedBox(height: 12),

                  // Attendance List
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.navy))
                        : attendanceData.isEmpty
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
                                  itemCount: attendanceData.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1, color: AppTheme.hairline),
                                  itemBuilder: (context, index) {
                                    return _AttendanceRow(record: attendanceData[index], index: index);
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
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadAttendanceData();
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

class _SampleDataBanner extends StatelessWidget {
  const _SampleDataBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        border: Border.all(color: AppTheme.warningBorder, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF6E3B8),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: const Text(
              'GAP §8.1',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppTheme.warningText,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Designed against live data. Today this screen renders sample data — the reporting endpoints exist but aren't wired.",
              style: TextStyle(fontSize: 12.5, color: Color(0xFF6B5220), height: 1.4),
            ),
          ),
        ],
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
  final Map<String, dynamic> record;
  final int index;

  const _AttendanceRow({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = record['status'] == 'Checked In';
    const barColors = [AppTheme.green, AppTheme.blue, AppTheme.yellow, AppTheme.magenta];

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
                  record['childName'],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${record['guardianName']} · In ${record['checkinTime']}'
                  '${record['checkoutTime'] != null ? ' · Out ${record['checkoutTime']}' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isCheckedIn ? const Color(0xFFE6F5EA) : AppTheme.chipNeutralBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              isCheckedIn ? 'Here' : 'Out',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isCheckedIn ? const Color(0xFF1F6E39) : AppTheme.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
