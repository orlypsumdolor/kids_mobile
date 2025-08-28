# Error Handling & API Response Guide

This guide explains how to use the comprehensive error handling and API response system implemented in the Kids Church Check-in application.

## Overview

The error handling system provides:
- **Standardized API error parsing** following the API documentation
- **Reusable error handling components** for providers and UI
- **User-friendly error messages** with appropriate styling
- **Automatic retry logic** for recoverable errors
- **Consistent error display** across the application

## Components

### 1. API Error Models (`lib/data/models/api_error_model.dart`)

Models that represent the standard API error response format:

```dart
// Parse error response from API
final errorResponse = ApiErrorResponse.fromJson(responseData);

// Check error types
if (errorResponse.isValidationError) {
  // Handle validation errors
}

if (errorResponse.isAuthenticationError) {
  // Handle authentication errors
}

// Get field-specific validation errors
final fieldErrors = errorResponse.fieldErrors;
final emailError = errorResponse.getFieldError('email');
```

### 2. API Response Handler (`lib/core/services/api_response_handler.dart`)

Service for handling API responses and converting errors:

```dart
// Handle successful responses
final data = ApiResponseHandler.handleSuccessResponse(response);

// Handle errors
final errorResponse = ApiResponseHandler.handleErrorResponse(error);

// Check if response is successful
final isSuccess = ApiResponseHandler.isSuccessResponse(response);

// Get user-friendly error message
final message = ApiResponseHandler.getUserFriendlyMessage(errorResponse);
```

### 3. API Response Mixin (`lib/core/mixins/api_response_mixin.dart`)

Mixin that providers can use for standardized error handling:

```dart
class MyProvider extends ChangeNotifier with ApiResponseMixin {
  
  Future<void> fetchData() async {
    await handleApiResponse(
      apiCall: () => _apiService.getData(),
      successMessage: 'Data loaded successfully',
      errorMessage: 'Failed to load data',
      showLoading: true,
      onSuccess: (data) {
        // Handle success
      },
      onError: (errorResponse) {
        // Handle specific error types
        if (errorResponse.isAuthenticationError) {
          // Redirect to login
        }
      },
    );
  }
  
  // Access error information
  bool get hasError => error != null;
  bool get isLastErrorValidation => lastError?.isValidationError ?? false;
  Map<String, String> get fieldErrors => lastErrorFieldErrors;
}
```

### 4. Error Utilities (`lib/core/utils/error_utils.dart`)

Utility functions for common error handling patterns:

```dart
// Get user-friendly error message
final message = ErrorUtils.getUserFriendlyMessage(errorResponse);

// Check if error should trigger retry
if (ErrorUtils.shouldRetry(errorResponse)) {
  // Implement retry logic
}

// Get suggested action for user
final action = ErrorUtils.getSuggestedAction(errorResponse);

// Get error category for styling
final category = ErrorUtils.getErrorCategory(errorResponse);
```

### 5. Error Display Widgets (`lib/presentation/widgets/error_display.dart`)

Reusable widgets for displaying errors:

```dart
// Display API error response
ErrorDisplay(
  errorResponse: errorResponse,
  onRetry: () => retryAction(),
  onDismiss: () => clearError(),
  showDetails: true,
  showActions: true,
)

// Display simple error message
SimpleErrorDisplay(
  message: 'Something went wrong',
  onRetry: () => retryAction(),
)
```

### 6. Success Display Widgets (`lib/presentation/widgets/success_display.dart`)

Widgets for displaying success messages:

```dart
// Static success display
SuccessDisplay(
  message: 'Operation completed successfully',
  onDismiss: () => clearSuccess(),
)

// Animated success display
AnimatedSuccessDisplay(
  message: 'Success!',
  autoHideDuration: Duration(seconds: 3),
  onAutoHide: () => clearSuccess(),
)

// Success snackbar
SuccessSnackBar.show(
  context,
  message: 'Operation completed successfully',
)
```

### 7. Loading Indicators (`lib/presentation/widgets/loading_indicator.dart`)

Widgets for showing loading states:

```dart
// Basic loading indicator
LoadingIndicator(
  message: 'Loading data...',
  size: 40.0,
)

// Loading overlay
LoadingOverlay(
  isLoading: isLoading,
  child: MyContent(),
  message: 'Processing...',
)

// Loading button
LoadingButton(
  isLoading: isLoading,
  onPressed: () => performAction(),
  child: Text('Submit'),
  loadingMessage: 'Submitting...',
)
```

## Usage Examples

### Provider Implementation

```dart
class UserProvider extends ChangeNotifier with ApiResponseMixin {
  final ApiService _apiService;
  
  UserProvider(this._apiService);
  
  Future<void> createUser(User user) async {
    await handleApiResponse(
      apiCall: () => _apiService.createUser(user),
      successMessage: 'User created successfully',
      errorMessage: 'Failed to create user',
      showLoading: true,
      onSuccess: (createdUser) {
        // Handle success
        _users.add(createdUser);
      },
      onError: (errorResponse) {
        // Handle specific error types
        if (errorResponse.isValidationError) {
          // Show field-specific errors
          final fieldErrors = errorResponse.fieldErrors;
          // Update form validation
        }
      },
    );
  }
  
  Future<void> updateUser(String id, User user) async {
    await handleApiResponseWithCustomLogic(
      apiCall: () => _apiService.updateUser(id, user),
      successHandler: (updatedUser) {
        // Custom success logic
        final index = _users.indexWhere((u) => u.id == id);
        if (index != -1) {
          _users[index] = updatedUser;
        }
        return updatedUser;
      },
      errorHandler: (errorResponse) {
        // Custom error handling
        if (errorResponse.isNotFoundError) {
          return 'User not found. Please check the ID.';
        }
        return ErrorUtils.getUserFriendlyMessage(errorResponse);
      },
    );
  }
}
```

### UI Implementation

```dart
class UserForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Form fields...
            
            // Error display
            if (provider.hasError)
              ErrorDisplay(
                errorResponse: provider.lastError,
                onRetry: () => provider.createUser(user),
                showDetails: false,
              ),
            
            // Success message
            if (provider.successMessage != null)
              AnimatedSuccessDisplay(
                message: provider.successMessage!,
                onAutoHide: () => provider.clearSuccessMessage(),
              ),
            
            // Loading button
            LoadingButton(
              isLoading: provider.isLoading,
              onPressed: () => provider.createUser(user),
              child: Text('Create User'),
              loadingMessage: 'Creating...',
            ),
          ],
        );
      },
    );
  }
}
```

### Error Handling Patterns

#### Validation Errors
```dart
if (provider.isLastErrorValidation) {
  final fieldErrors = provider.lastErrorFieldErrors;
  
  // Show field-specific errors
  if (fieldErrors.containsKey('email')) {
    // Display email error
  }
  
  if (fieldErrors.containsKey('password')) {
    // Display password error
  }
}
```

#### Authentication Errors
```dart
if (provider.isLastErrorAuthentication) {
  // Redirect to login
  Navigator.pushReplacementNamed(context, '/login');
}
```

#### Network Errors
```dart
if (provider.isLastErrorRetryable) {
  // Show retry button
  ElevatedButton(
    onPressed: () => provider.retryLastAction(),
    child: Text('Retry'),
  )
}
```

#### Rate Limiting
```dart
if (provider.lastError?.isRateLimitError ?? false) {
  final retryDelay = provider.lastErrorRetryDelay;
  if (retryDelay != null) {
    // Show countdown timer
    Text('Try again in ${retryDelay.inSeconds} seconds');
  }
}
```

## Best Practices

### 1. Always Use the Mixin
- Extend your providers with `ApiResponseMixin` for consistent error handling
- Use `handleApiResponse` for standard API calls
- Use `handleApiResponseWithCustomLogic` for complex scenarios

### 2. Handle Specific Error Types
- Check error types using the provided getters
- Implement appropriate UI responses for different error categories
- Provide user-friendly messages and suggested actions

### 3. Use Reusable Widgets
- Use `ErrorDisplay` for API errors
- Use `SuccessDisplay` for success messages
- Use `LoadingIndicator` for loading states

### 4. Implement Retry Logic
- Check if errors are retryable using `isLastErrorRetryable`
- Provide retry buttons for network and server errors
- Respect rate limiting delays

### 5. Log Errors for Debugging
- Use the built-in error logging in the mixin
- Access detailed error information through `lastError`
- Log error codes and details for troubleshooting

### 6. Provide User Guidance
- Use `ErrorUtils.getSuggestedAction` for helpful hints
- Show field-specific validation errors
- Guide users through recovery steps

## Error Categories

The system categorizes errors for appropriate styling and handling:

- **validation**: Input validation errors (orange styling)
- **authentication**: Login/token errors (red styling)
- **permission**: Access control errors (purple styling)
- **server**: Server-side errors (red styling)
- **network**: Connection errors (blue styling)
- **general**: Other errors (grey styling)

## Testing Error Scenarios

Use these test cases to verify error handling:

1. **Network Errors**: Disconnect internet during API calls
2. **Validation Errors**: Submit forms with invalid data
3. **Authentication Errors**: Use expired or invalid tokens
4. **Permission Errors**: Access restricted endpoints
5. **Server Errors**: Trigger 5xx status codes
6. **Rate Limiting**: Send multiple rapid requests

## Migration Guide

To migrate existing providers to use the new error handling:

1. **Add the mixin**:
   ```dart
   class OldProvider extends ChangeNotifier with ApiResponseMixin
   ```

2. **Remove duplicate state variables**:
   - Remove `_isLoading`, `_error`, `_successMessage`
   - Use mixin getters instead

3. **Replace try-catch blocks**:
   ```dart
   // Old way
   try {
     setLoading(true);
     final result = await apiCall();
     setSuccessMessage('Success');
   } catch (e) {
     setError(e.toString());
   } finally {
     setLoading(false);
   }
   
   // New way
   await handleApiResponse(
     apiCall: () => apiCall(),
     successMessage: 'Success',
   );
   ```

4. **Update UI to use new widgets**:
   - Replace custom error displays with `ErrorDisplay`
   - Replace custom loading indicators with `LoadingIndicator`
   - Replace custom success messages with `SuccessDisplay`

This system provides a robust, maintainable, and user-friendly approach to handling API responses and errors throughout the application.
