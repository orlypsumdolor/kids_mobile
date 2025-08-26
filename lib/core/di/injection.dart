import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/preferences_helper.dart';
import '../../data/datasources/remote/api_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/checkin_repository_impl.dart';
import '../../data/repositories/service_repository_impl.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/checkin_repository.dart';
import '../../domain/repositories/service_repository.dart';

import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/checkin_usecases.dart';
import '../../domain/usecases/checkout_usecases.dart';
import '../../domain/usecases/service_usecases.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/checkin_provider.dart';
import '../../presentation/providers/checkout_provider.dart';
import '../../presentation/providers/services_provider.dart';

import '../../core/services/camera_service.dart';
// import '../../core/services/nfc_service.dart'; // Temporarily disabled
import '../../core/services/printer_service.dart';
import '../../core/services/permission_service.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  final database = await DatabaseHelper.initializeDatabase();
  getIt.registerLazySingleton<Database>(() => database);

  // Core services
  getIt.registerLazySingleton<PreferencesHelper>(
      () => PreferencesHelper(getIt()));
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  getIt.registerLazySingleton<ApiService>(() => ApiService());

  // Platform services
  getIt.registerLazySingleton<CameraService>(() => CameraService());
  // getIt.registerLazySingleton<NfcService>(() => NfcService()); // Temporarily disabled
  getIt.registerLazySingleton<PrinterService>(() => PrinterService());
  getIt.registerLazySingleton<PermissionService>(() => PermissionService());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        apiService: getIt(),
        preferencesHelper: getIt(),
      ));
  getIt.registerLazySingleton<CheckinRepository>(() => CheckinRepositoryImpl(
        apiService: getIt(),
        databaseHelper: getIt(),
      ));
  getIt.registerLazySingleton<ServiceRepository>(() => ServiceRepositoryImpl(
        apiService: getIt(),
      ));

  // Use cases
  getIt.registerLazySingleton<LoginUseCase>(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(getIt()));
  getIt.registerLazySingleton<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(getIt()));

  getIt.registerLazySingleton<CheckInChildUseCase>(
      () => CheckInChildUseCase(getIt()));
  getIt.registerLazySingleton<GetChildByCodeUseCase>(
      () => GetChildByCodeUseCase(getIt()));
  getIt.registerLazySingleton<GeneratePickupCodeUseCase>(
      () => GeneratePickupCodeUseCase(getIt()));

  getIt.registerLazySingleton<CheckOutChildUseCase>(
      () => CheckOutChildUseCase(getIt()));
  getIt.registerLazySingleton<VerifyPickupCodeUseCase>(
      () => VerifyPickupCodeUseCase(getIt()));

  getIt.registerLazySingleton<GetServiceSessionsUseCase>(
      () => GetServiceSessionsUseCase(getIt()));
  getIt.registerLazySingleton<GetServiceSessionByIdUseCase>(
      () => GetServiceSessionByIdUseCase(getIt()));

  // Providers
  getIt.registerFactory<AuthProvider>(() => AuthProvider(
        loginUseCase: getIt(),
        logoutUseCase: getIt(),
        getCurrentUserUseCase: getIt(),
      ));
  getIt.registerFactory<CheckinProvider>(() => CheckinProvider(
        checkInChildUseCase: getIt(),
        getChildByCodeUseCase: getIt(),
        generatePickupCodeUseCase: getIt(),
        cameraService: getIt(),
        printerService: getIt(),
        apiService: getIt(),
      ));
  getIt.registerFactory<CheckoutProvider>(() => CheckoutProvider(
        checkOutChildUseCase: getIt(),
        verifyPickupCodeUseCase: getIt(),
        cameraService: getIt(),
        checkinProvider: getIt(),
        apiService: getIt(),
      ));
  getIt.registerFactory<ServicesProvider>(() => ServicesProvider(
        getServiceSessionsUseCase: getIt(),
      ));
}
