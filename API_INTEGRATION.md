# API Integration Documentation

This document outlines the integration between the Flutter mobile app and the Node.js backend API for the Kids Church check-in system.

## Overview

The Flutter app has been updated to align with the Node.js backend API structure. All models, API calls, and data handling have been standardized to match the backend schema.

## API Base URL

- **Development**: `http://192.168.254.105:5000`
- **Production**: `https://api.kidschurch.com`

Update the base URL in `lib/core/constants/api_constants.dart` based on your environment.

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user
- `POST /api/auth/refresh` - Refresh JWT token

### Children
- `GET /api/children` - Get children with pagination and filtering
- `GET /api/children/:id` - Get child by ID
- `GET /api/children?qrCode=:code` - Search child by QR code
- `GET /api/children?rfidTag=:tag` - Search child by RFID tag

### Attendance
- `POST /api/attendance/checkin` - Check in a child
- `POST /api/attendance/checkout/:recordId` - Check out a child
- `GET /api/attendance/active` - Get currently checked-in children
- `GET /api/attendance/child/:childId` - Get child attendance history

### Services
- `GET /api/services` - Get service sessions
- `GET /api/services/:id` - Get service session by ID

### Reports
- `GET /api/reports/attendance` - Get attendance reports
- `GET /api/reports/dashboard` - Get dashboard data

## Data Models

### Child Model
```dart
class ChildModel {
  final String id;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String ageGroup;
  final String guardianId;
  final EmergencyContactModel? emergencyContact;
  final String? specialNotes;
  final String qrCode;
  final String? rfidTag;
  final bool isActive;
  final bool currentlyCheckedIn;
  final DateTime? lastCheckIn;
  final DateTime? lastCheckOut;
  // ... other fields
}
```

### Attendance Record Model
```dart
class AttendanceRecordModel {
  final String id;
  final String childId;
  final String serviceSessionId;
  final DateTime serviceDate;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String checkedInBy;
  final String? checkedOutBy;
  final String? pickupCode;
  final String? notes;
  // ... other fields
}
```

### Service Session Model
```dart
class ServiceSessionModel {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final String dayOfWeek;
  final bool isActive;
  final String? description;
  final List<String> ageGroups;
  final int? maxCapacity;
  // ... other fields
}
```

## API Response Format

All API responses follow this standard format:

```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    // Response data here
  }
}
```

## Error Handling

The API service includes helper methods for consistent error handling:

```dart
// Check if response is successful
bool success = apiService.isSuccess(response);

// Extract data from response
Map<String, dynamic>? data = apiService.extractData(response);

// Get error message
String? message = apiService.getMessage(response);
```

## Authentication

JWT tokens are automatically included in all authenticated requests:

```dart
// Set token after login
apiService.setAuthToken(token);

// Clear token on logout
apiService.clearAuthToken();
```

## Key Changes Made

1. **Model Alignment**: All models now match the backend schema exactly
2. **Field Mapping**: Updated field names to match API (e.g., `firstName` → `fullName`)
3. **API Endpoints**: Standardized all endpoint calls
4. **Response Handling**: Added helper methods for consistent response parsing
5. **Backward Compatibility**: Maintained helper getters for existing code

## Usage Examples

### Check-in a Child
```dart
final response = await apiService.checkInChild(
  childId: child.id,
  serviceSessionId: service.id,
  notes: 'Special instructions',
);

if (apiService.isSuccess(response)) {
  final data = apiService.extractData(response);
  // Handle success
}
```

### Get Children with Filtering
```dart
final response = await apiService.getChildren(
  page: 1,
  limit: 20,
  isActive: true,
  ageGroup: 'elementary',
);
```

### Search by QR Code
```dart
final response = await apiService.getChildByQrCode(qrCode);
if (apiService.isSuccess(response)) {
  final childData = apiService.extractData(response);
  // Process child data
}
```

## Testing the Integration

1. **Start the Backend**: Ensure your Node.js API is running on the configured port
2. **Update Base URL**: Set the correct base URL in `api_constants.dart`
3. **Test Authentication**: Try logging in with valid credentials
4. **Test Endpoints**: Verify each endpoint returns the expected data format
5. **Check Error Handling**: Test with invalid data to ensure proper error responses

## Troubleshooting

### Common Issues

1. **Connection Refused**: Check if the backend is running and the port is correct
2. **401 Unauthorized**: Verify JWT token is being sent correctly
3. **404 Not Found**: Check endpoint URLs match the backend exactly
4. **Data Mismatch**: Ensure model fields match the API response structure

### Debug Tips

1. **Enable Logging**: The API service includes request/response logging
2. **Check Network Tab**: Use browser dev tools to inspect API calls
3. **Validate JSON**: Ensure API responses match the expected format
4. **Test with Postman**: Verify endpoints work outside the app first

## Next Steps

1. **Test all endpoints** to ensure they work correctly
2. **Update UI components** to use the new model structure
3. **Implement error handling** for failed API calls
4. **Add offline support** for when the API is unavailable
5. **Set up production environment** with the correct API URL

## Support

For issues with the API integration:
1. Check the backend logs for errors
2. Verify the API endpoints are accessible
3. Ensure the data models match exactly
4. Test with a simple HTTP client first
