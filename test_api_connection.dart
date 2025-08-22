import 'package:dio/dio.dart';

// Simple test script to verify API connection
// Run this with: dart test_api_connection.dart

void main() async {
  print('🧪 Testing Kids Church API Connection...\n');

  final dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.254.105:5000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  try {
    // Test 1: Health Check
    print('1️⃣ Testing Health Check...');
    final healthResponse = await dio.get('/api/health');
    print('✅ Health Check: ${healthResponse.statusCode}');
    print('   Response: ${healthResponse.data}\n');

    // Test 2: Get Services
    print('2️⃣ Testing Services Endpoint...');
    final servicesResponse = await dio.get('/api/services?limit=5');
    print('✅ Services: ${servicesResponse.statusCode}');
    print('   Found ${servicesResponse.data['data']?.length ?? 0} services\n');

    // Test 3: Get Children
    print('3️⃣ Testing Children Endpoint...');
    final childrenResponse = await dio.get('/api/children?limit=5');
    print('✅ Children: ${childrenResponse.statusCode}');
    print('   Found ${childrenResponse.data['data']?.length ?? 0} children\n');

    // Test 4: Get Active Attendance
    print('4️⃣ Testing Active Attendance...');
    final attendanceResponse = await dio.get('/api/attendance/active');
    print('✅ Active Attendance: ${attendanceResponse.statusCode}');
    print(
        '   Found ${attendanceResponse.data['data']?.length ?? 0} active records\n');

    print('🎉 All API tests passed! The backend is working correctly.');
  } catch (e) {
    if (e is DioException) {
      print('❌ API Error: ${e.message}');
      print('   Status: ${e.response?.statusCode}');
      print('   Response: ${e.response?.data}');

      if (e.type == DioExceptionType.connectionTimeout) {
        print(
            '\n💡 Tip: Make sure your Node.js backend is running on port 5000');
        print('   Run: cd ../kids-api && npm start');
      }
    } else {
      print('❌ Unexpected Error: $e');
    }
  }
}

// Test specific endpoints
Future<Response?> testEndpoint(
    Dio dio, String endpoint, String description) async {
  try {
    final response = await dio.get(endpoint);
    print('✅ $description: ${response.statusCode}');
    return response;
  } catch (e) {
    print('❌ $description failed: $e');
    rethrow;
  }
}
