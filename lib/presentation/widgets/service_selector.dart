import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/services_provider.dart';

class ServiceSelector extends StatefulWidget {
  final String? selectedServiceId;
  final Function(String) onServiceSelected;

  const ServiceSelector({
    super.key,
    required this.selectedServiceId,
    required this.onServiceSelected,
  });

  @override
  State<ServiceSelector> createState() => _ServiceSelectorState();
}

class _ServiceSelectorState extends State<ServiceSelector> {
  @override
  void initState() {
    super.initState();
    // Load services when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicesProvider>().loadServices();
    });
  }

  @override
  Widget build(BuildContext context) {
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
            Consumer<ServicesProvider>(
              builder: (context, servicesProvider, child) {
                if (servicesProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (servicesProvider.error != null) {
                  return Column(
                    children: [
                      Text(
                        'Error loading services: ${servicesProvider.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => servicesProvider.loadServices(),
                        child: const Text('Retry'),
                      ),
                    ],
                  );
                }

                if (servicesProvider.services.isEmpty) {
                  return const Text('No services available');
                }

                return Column(
                  children: servicesProvider.services
                      .map(
                        (service) => RadioListTile<String>(
                          title: Text(service.name),
                          subtitle:
                              Text('${service.startTime} - ${service.endTime}'),
                          value: service.id,
                          groupValue: widget.selectedServiceId,
                          onChanged: (value) {
                            if (value != null) {
                              widget.onServiceSelected(value);
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
