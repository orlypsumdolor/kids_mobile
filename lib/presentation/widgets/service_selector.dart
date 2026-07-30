import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/services_provider.dart';
import '../../core/theme/app_theme.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SERVICE',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Consumer<ServicesProvider>(
          builder: (context, servicesProvider, child) {
            if (servicesProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (servicesProvider.error != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error loading services: ${servicesProvider.error}',
                    style: const TextStyle(color: AppTheme.error),
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
              return const Text(
                'No services available',
                style: TextStyle(color: AppTheme.textSecondary),
              );
            }

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: servicesProvider.services.map((service) {
                final selected = widget.selectedServiceId == service.id;
                return _ServicePill(
                  label: service.name,
                  isNow: service.isCurrentlyActive,
                  selected: selected,
                  onTap: () => widget.onServiceSelected(service.id),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ServicePill extends StatelessWidget {
  final String label;
  final bool isNow;
  final bool selected;
  final VoidCallback onTap;

  const _ServicePill({
    required this.label,
    required this.isNow,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppTheme.navy : AppTheme.surface;
    final fg = selected ? Colors.white : AppTheme.textPrimary;
    final border = selected ? AppTheme.navy : AppTheme.inputBorder;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            border: Border.all(color: border, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              if (isNow) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.green,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: const Text(
                    'NOW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
