class ApiConstants {
  // Update this to your actual API URL
  static const String baseUrl =
      'http://192.168.254.105:5000'; // Local development
  // static const String baseUrl = 'https://api.kidschurch.com'; // Production

  // Auth endpoints
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';
  static const String refresh = '/api/auth/refresh';

  // User endpoints
  static const String users = '/api/users';
  static String userById(String id) => '/api/users/$id';

  // Children endpoints
  static const String children = '/api/children';
  static String childById(String id) => '/api/children/$id';
  static String childQrCode(String id) => '/api/children/$id/qr-code';
  static String childRfid(String id) => '/api/children/$id/rfid';

  // Guardian endpoints
  static const String guardians = '/api/guardians';
  static String guardianById(String id) => '/api/guardians/$id';
  static String guardianPickupCode(String id) =>
      '/api/guardians/$id/pickup-code';
  static String guardianChildren(String id) => '/api/guardians/$id/children';

  // Attendance endpoints
  static const String attendance = '/api/attendance';
  static const String checkin = '/api/attendance/checkin';
  static String checkout(String recordId) =>
      '/api/attendance/checkout/$recordId';
  static String childAttendance(String childId) =>
      '/api/attendance/child/$childId';
  static const String activeAttendance = '/api/attendance/active';
  static const String attendanceStats = '/api/attendance/stats';

  // Service endpoints
  static const String services = '/api/services';
  static String serviceById(String id) => '/api/services/$id';

  // Reports endpoints
  static const String reportsAttendance = '/api/reports/attendance';
  static const String reportsChildren = '/api/reports/children';
  static const String reportsGuardians = '/api/reports/guardians';
  static const String reportsDashboard = '/api/reports/dashboard';

  // Health check
  static const String health = '/api/health';

  // Search endpoints
  static String searchChildren(String query) => '/api/children?search=$query';
  static String searchChildrenByQr(String qrCode) =>
      '/api/children?qrCode=$qrCode&isActive=true';
  static String searchChildrenByRfid(String rfidTag) =>
      '/api/children?rfidTag=$rfidTag&isActive=true';
}
