import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  final SharedPreferences _prefs;

  PreferencesHelper(this._prefs);

  // User session
  Future<void> setUserData(String userData) async {
    await _prefs.setString('user_data', userData);
  }

  String? getUserData() {
    return _prefs.getString('user_data');
  }

  Future<void> setAuthToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  String? getAuthToken() {
    return _prefs.getString('auth_token');
  }

  Future<void> clearUserSession() async {
    await _prefs.remove('user_data');
    await _prefs.remove('auth_token');
  }

  // App settings
  Future<void> setServiceSession(String session) async {
    await _prefs.setString('current_service_session', session);
  }

  String? getServiceSession() {
    return _prefs.getString('current_service_session');
  }

  Future<void> setPrinterAddress(String address) async {
    await _prefs.setString('printer_bluetooth_address', address);
  }

  String? getPrinterAddress() {
    return _prefs.getString('printer_bluetooth_address');
  }

  // Sync settings
  Future<void> setLastSyncTime(DateTime dateTime) async {
    await _prefs.setString('last_sync_time', dateTime.toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final timeString = _prefs.getString('last_sync_time');
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }
}
