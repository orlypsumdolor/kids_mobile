import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// Home screen's primary tile row: Check In / Check Out, role-gated on
/// [User.canScan]. Sits near the top of Home, right below the "Now serving"
/// card, per the design.
class PrimaryActionTiles extends StatelessWidget {
  const PrimaryActionTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null || !user.canScan) return const SizedBox.shrink();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PrimaryTile(
                label: 'Check In',
                subtitle: 'Scan guardian badge',
                chipColor: const Color(0xFF7FA8E8),
                filled: true,
                onTap: () => context.push(AppRouter.guardianCheckin),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _PrimaryTile(
                label: 'Check Out',
                subtitle: 'Scan pickup slip',
                chipColor: AppTheme.green,
                filled: false,
                onTap: () => context.push(AppRouter.checkout),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Home screen's secondary tile row: Attendance ([User.canViewReports]) and
/// Settings ([User.canManageUsers]). Per the design this is anchored to the
/// bottom of the screen together with the user/logout row, not stacked
/// directly under the primary tiles.
class SecondaryActionTiles extends StatelessWidget {
  const SecondaryActionTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) return const SizedBox.shrink();

        final tiles = <Widget>[
          if (user.canViewReports)
            Expanded(
              child: _SecondaryTile(
                label: 'Attendance',
                subtitle: "Today's numbers",
                chipColor: AppTheme.yellow,
                onTap: () => context.push(AppRouter.attendanceSummary),
              ),
            ),
          if (user.canManageUsers)
            Expanded(
              child: _SecondaryTile(
                label: 'Settings',
                subtitle: 'Printer + station',
                chipColor: AppTheme.blue,
                onTap: () => context.push(AppRouter.settings),
              ),
            ),
        ];

        if (tiles.isEmpty) return const SizedBox.shrink();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              tiles[i],
            ],
          ],
        );
      },
    );
  }
}

class _PrimaryTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color chipColor;
  final bool filled;
  final VoidCallback onTap;

  const _PrimaryTile({
    required this.label,
    required this.subtitle,
    required this.chipColor,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? AppTheme.navy : AppTheme.surface;
    final fg = filled ? Colors.white : AppTheme.textPrimary;
    final border = filled ? AppTheme.navy : AppTheme.hairline;

    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusTile),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusTile),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusTile),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const Spacer(),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: fg.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color chipColor;
  final VoidCallback onTap;

  const _SecondaryTile({
    required this.label,
    required this.subtitle,
    required this.chipColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
