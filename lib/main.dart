import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/checkin_provider.dart';
import 'presentation/providers/checkout_provider.dart';
import 'presentation/providers/services_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize dependencies
  await configureDependencies();

  runApp(const KidsChurchApp());
}

class KidsChurchApp extends StatelessWidget {
  const KidsChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<AuthProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<CheckinProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<CheckoutProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<ServicesProvider>()),
      ],
      child: MaterialApp.router(
        title: 'Kids Church Check-in',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
