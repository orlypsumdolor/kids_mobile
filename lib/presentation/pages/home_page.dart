import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/services_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/role_based_navigation.dart';
import '../widgets/app_shell_header.dart';
import '../../core/router/app_router.dart';
import '../../core/services/printer_service.dart';
import '../../core/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicesProvider>().loadServices();
      context.read<DashboardProvider>().loadServiceStats();
    });
    // PrinterService isn't a ChangeNotifier and the active-service window
    // can start/end while sitting on this screen, so poll periodically —
    // same pattern as the check-in page's printer-connection timer. Also
    // refreshes the "still here" / "today" counts on the now-serving card.
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<DashboardProvider>().loadServiceStats();
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pick up printer/service state immediately when returning to Home
    // (e.g. from Settings after connecting a printer).
    setState(() {});
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final printerConnected = context.read<PrinterService>().isConnected;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: Column(
        children: [
          AppShellHeader(
            title: 'Kids Church',
            subtitle: 'Victory · General Santos',
            printerConnected: printerConnected,
            onSettings: () => context.push(AppRouter.settings),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight - 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _NowServingCard(),
                              const SizedBox(height: 16),
                              const PrimaryActionTiles(),
                            ],
                          ),
                          const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SecondaryActionTiles(),
                              SizedBox(height: 20),
                              _UserRow(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NowServingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<ServicesProvider, DashboardProvider>(
      builder: (context, servicesProvider, dashboardProvider, child) {
        String activeServiceName = '—';
        String? activeServiceId;
        for (final s in servicesProvider.services) {
          if (s.isCurrentlyActive) {
            activeServiceName = s.name;
            activeServiceId = s.id;
            break;
          }
        }

        final stat = activeServiceId != null
            ? dashboardProvider.statsFor(activeServiceId)
            : null;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
            border: Border.all(color: AppTheme.hairline),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Now serving',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeServiceName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (stat != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NowServingStat(
                      value: stat.totalToday,
                      label: 'Checked in',
                      color: AppTheme.navy,
                    ),
                    const SizedBox(width: 28),
                    _NowServingStat(
                      value: stat.stillHere,
                      label: 'Still here',
                      color: AppTheme.green,
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NowServingStat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _NowServingStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.1,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) return const SizedBox.shrink();

        return Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.navy,
              radius: 22,
              child: Text(
                user.firstName.isNotEmpty
                    ? user.firstName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    user.role.isEmpty
                        ? user.role
                        : user.role[0].toUpperCase() + user.role.substring(1),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  context.go(AppRouter.login);
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                foregroundColor: AppTheme.textTertiary,
              ),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
  }
}
