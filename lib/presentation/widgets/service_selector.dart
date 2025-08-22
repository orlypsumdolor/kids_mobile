import 'package:flutter/material.dart';

class ServiceSelector extends StatelessWidget {
  final String? selectedServiceId;
  final Function(String) onServiceSelected;

  const ServiceSelector({
    super.key,
    required this.selectedServiceId,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Mock services - in real app, this would come from a provider
    final services = [
      {'id': '1', 'name': 'Sunday Morning Service', 'time': '9:00 AM'},
      {'id': '2', 'name': 'Sunday Evening Service', 'time': '6:00 PM'},
      {'id': '3', 'name': 'Wednesday Kids Club', 'time': '7:00 PM'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Service Session',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...services.map((service) => RadioListTile<String>(
              title: Text(service['name']!),
              subtitle: Text(service['time']!),
              value: service['id']!,
              groupValue: selectedServiceId,
              onChanged: (value) {
                if (value != null) {
                  onServiceSelected(value);
                }
              },
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
    );
  }
}