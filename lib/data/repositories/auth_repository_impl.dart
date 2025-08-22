import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/api_service.dart';
import '../datasources/local/preferences_helper.dart';
import '../models/user_model.dart';
import 'dart:convert';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;
  final PreferencesHelper _preferencesHelper;

  AuthRepositoryImpl({
    required ApiService apiService,
    required PreferencesHelper preferencesHelper,
  })  : _apiService = apiService,
        _preferencesHelper = preferencesHelper;

  @override
  Future<User> login(String username, String password) async {
    try {
      if (await _apiService.isOnline()) {
        final response = await _apiService.login(username, password);
        
        if (response.data['success'] == true) {
          final userModel = UserModel.fromJson(response.data['data']['user']);
          final token = response.data['data']['token'];

          // Set token for future requests
          _apiService.setAuthToken(token);
          
          // Save to local storage
          await _preferencesHelper.setUserData(jsonEncode(userModel.toJson()));
          await _preferencesHelper.setAuthToken(token);

          return userModel.toEntity();
        } else {
          throw Exception(response.data['message'] ?? 'Login failed');
        }
      } else {
        // Offline login - check if user data exists
        final userData = _preferencesHelper.getUserData();
        if (userData != null) {
          final userModel = UserModel.fromJson(jsonDecode(userData));
          final token = _preferencesHelper.getAuthToken();
          if (token != null) {
            _apiService.setAuthToken(token);
          }
          // In a real app, you'd validate credentials offline too
          return userModel.toEntity();
        } else {
          throw Exception('No internet connection and no cached credentials');
        }
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      if (await _apiService.isOnline()) {
        // No logout endpoint in your API, just clear token
        _apiService.clearAuthToken();
      }
    } catch (e) {
      // Continue with local logout even if API call fails
    } finally {
      await _preferencesHelper.clearUserSession();
      _apiService.clearAuthToken();
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final token = _preferencesHelper.getAuthToken();
      if (token != null) {
        _apiService.setAuthToken(token);
        
        // Try to get fresh user data if online
        if (await _apiService.isOnline()) {
          try {
            final response = await _apiService.getCurrentUser();
            if (response.data['success'] == true) {
              final userModel = UserModel.fromJson(response.data['data']);
              await _preferencesHelper.setUserData(jsonEncode(userModel.toJson()));
              return userModel.toEntity();
            }
          } catch (e) {
            // Fall back to cached data
          }
        }
      }
      
      final userData = _preferencesHelper.getUserData();
      if (userData != null) {
        final userModel = UserModel.fromJson(jsonDecode(userData));
        return userModel.toEntity();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = _preferencesHelper.getAuthToken();
    final userData = _preferencesHelper.getUserData();
    return token != null && userData != null;
  }
}