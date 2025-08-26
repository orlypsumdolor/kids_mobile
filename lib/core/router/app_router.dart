import 'package:go_router/go_router.dart';

import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/scanner/checkin_page.dart';
import '../../presentation/pages/scanner/checkout_page.dart';
import '../../presentation/pages/scanner/qr_scanner_page.dart';
import '../../presentation/pages/scanner/guardian_checkin_page.dart';
import '../../presentation/pages/admin/attendance_summary_page.dart';
import '../../presentation/pages/admin/settings_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String checkin = '/checkin';
  static const String checkout = '/checkout';
  static const String qrScanner = '/qr-scanner';
  static const String guardianCheckin = '/guardian-checkin';
  static const String attendanceSummary = '/attendance-summary';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: checkin,
        builder: (context, state) => const CheckinPage(),
      ),
      GoRoute(
        path: checkout,
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: guardianCheckin,
        builder: (context, state) => const GuardianCheckinPage(),
      ),
      GoRoute(
        path: qrScanner,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return QRScannerPage(
            onScanComplete: extra?['onScanComplete'],
            title: extra?['title'] ?? 'Scan QR Code',
          );
        },
      ),
      GoRoute(
        path: attendanceSummary,
        builder: (context, state) => const AttendanceSummaryPage(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}
