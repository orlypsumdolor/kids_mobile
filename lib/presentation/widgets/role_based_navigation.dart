import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../core/router/app_router.dart';

class RoleBasedNavigation extends StatelessWidget {
  const RoleBasedNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Scanner/Volunteer Actions
            if (user.canScan) ...[
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      title: 'Check Out',
                      subtitle: 'Verify pickup code',
                      icon: Icons.logout,
                      color: Theme.of(context).colorScheme.secondary,
                      onTap: () => context.push(AppRouter.checkout),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      title: 'Guardian Check-In',
                      subtitle:
                          'Scan guardian QR/RFID to check in multiple children',
                      icon: Icons.family_restroom,
                      color: Colors.green[600]!,
                      onTap: () => context.push(AppRouter.guardianCheckin),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Admin/Staff Actions
            if (user.canViewReports) ...[
              _ActionCard(
                title: 'Attendance Summary',
                subtitle: 'View today\'s attendance',
                icon: Icons.analytics,
                color: Theme.of(context).colorScheme.tertiary,
                onTap: () => context.push(AppRouter.attendanceSummary),
                isFullWidth: true,
              ),
              const SizedBox(height: 12),
            ],

            // Admin Only Actions
            if (user.canManageUsers) ...[
              _ActionCard(
                title: 'Settings',
                subtitle: 'Manage app settings',
                icon: Icons.settings,
                color: Colors.grey[600]!,
                onTap: () => context.push(AppRouter.settings),
                isFullWidth: true,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isFullWidth;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isFullWidth
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey[400]),
                  ],
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
