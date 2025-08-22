import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Summary'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date and Stats Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(selectedDate),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      TextButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.edit_calendar),
                        label: const Text('Change Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Check-ins',
                          value: '${attendanceData.length}',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Still Here',
                          value:
                              '${attendanceData.where((a) => a['status'] == 'Checked In').length}',
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Completed',
                          value:
                              '${attendanceData.where((a) => a['status'] == 'Completed').length}',
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Attendance List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : attendanceData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No attendance records',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'for ${_formatDate(selectedDate)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: attendanceData.length,
                          itemBuilder: (context, index) {
                            final record = attendanceData[index];
                            return _AttendanceCard(record: record);
                          },
                        ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const _AttendanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = record['status'] == 'Checked In';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  radius: 20,
                  child: Text(
                    record['childName'][0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['childName'],
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        'Guardian: ${record['guardianName']}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCheckedIn
                        ? Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.1)
                        : Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record['status'],
                    style: TextStyle(
                      color: isCheckedIn
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'In: ${record['checkinTime']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (record['checkoutTime'] != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.logout,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Out: ${record['checkoutTime']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const Spacer(),
                Text(
                  record['service'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
