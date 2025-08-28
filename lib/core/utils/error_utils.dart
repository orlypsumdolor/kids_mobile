import '../../data/models/api_error_model.dart';

/// Utility class for common error handling patterns
class ErrorUtils {
  /// Get user-friendly error message based on error type
  static String getUserFriendlyMessage(ApiErrorResponse errorResponse) {
    switch (errorResponse.error?.code) {
      case 'VALIDATION_ERROR':
        return _getValidationErrorMessage(errorResponse);
      case 'AUTHENTICATION_FAILED':
        return 'Please log in to continue';
      case 'TOKEN_EXPIRED':
        return 'Your session has expired. Please log in again';
      case 'INSUFFICIENT_PERMISSIONS':
        return 'You do not have permission to perform this action';
      case 'RESOURCE_NOT_FOUND':
        return 'The requested item was not found';
      case 'DUPLICATE_RESOURCE':
        return 'This item already exists';
      case 'RATE_LIMIT_EXCEEDED':
        return 'Too many requests. Please wait a moment and try again';
      case 'NETWORK_ERROR':
        return 'Network connection error. Please check your internet connection';
      case 'TIMEOUT_ERROR':
        return 'Request timed out. Please try again';
      case 'INTERNAL_ERROR':
        return 'An unexpected error occurred. Please try again later';
      default:
        return errorResponse.message;
    }
  }

  /// Get validation error message with field context
  static String _getValidationErrorMessage(ApiErrorResponse errorResponse) {
    if (errorResponse.errors != null && errorResponse.errors!.isNotEmpty) {
      final firstError = errorResponse.errors!.first;
      final fieldName = _getFieldDisplayName(firstError.field);
      return '$fieldName: ${firstError.message}';
    }
    return 'Please check your input and try again';
  }

  /// Convert field names to user-friendly display names
  static String _getFieldDisplayName(String field) {
    switch (field.toLowerCase()) {
      case 'firstname':
        return 'First Name';
      case 'lastname':
        return 'Last Name';
      case 'email':
        return 'Email';
      case 'phone':
        return 'Phone Number';
      case 'password':
        return 'Password';
      case 'username':
        return 'Username';
      case 'childid':
        return 'Child ID';
      case 'guardianid':
        return 'Guardian ID';
      case 'pickupcode':
        return 'Pickup Code';
      case 'qrcode':
        return 'QR Code';
      case 'rfidcode':
        return 'RFID Code';
      case 'notes':
        return 'Notes';
      case 'dob':
        return 'Date of Birth';
      case 'agegroup':
        return 'Age Group';
      case 'servicename':
        return 'Service Name';
      case 'servicedate':
        return 'Service Date';
      case 'servicetime':
        return 'Service Time';
      default:
        // Capitalize first letter and replace underscores with spaces
        return field
            .replaceAll('_', ' ')
            .replaceFirst(field[0], field[0].toUpperCase());
    }
  }

  /// Check if error should trigger a retry
  static bool shouldRetry(ApiErrorResponse errorResponse) {
    return errorResponse.isServerError ||
        errorResponse.error?.code == 'NETWORK_ERROR' ||
        errorResponse.error?.code == 'TIMEOUT_ERROR';
  }

  /// Get retry delay for rate limit errors
  static Duration getRetryDelay(ApiErrorResponse errorResponse) {
    if (errorResponse.isRateLimitError) {
      // Try to extract delay from error details
      final details = errorResponse.error?.details ?? '';
      final match = RegExp(r'(\d+)\s*seconds?').firstMatch(details);
      if (match != null) {
        final seconds = int.tryParse(match.group(1) ?? '60') ?? 60;
        return Duration(seconds: seconds);
      }
      return const Duration(seconds: 60);
    }
    return Duration.zero;
  }

  /// Get error category for UI styling
  static String getErrorCategory(ApiErrorResponse errorResponse) {
    if (errorResponse.isValidationError) {
      return 'validation';
    } else if (errorResponse.isAuthenticationError) {
      return 'authentication';
    } else if (errorResponse.isPermissionError) {
      return 'permission';
    } else if (errorResponse.isServerError) {
      return 'server';
    } else if (errorResponse.error?.code == 'NETWORK_ERROR') {
      return 'network';
    } else {
      return 'general';
    }
  }

  /// Check if error requires user action
  static bool requiresUserAction(ApiErrorResponse errorResponse) {
    return errorResponse.isValidationError ||
        errorResponse.isAuthenticationError ||
        errorResponse.isPermissionError;
  }

  /// Check if error is recoverable
  static bool isRecoverable(ApiErrorResponse errorResponse) {
    return !errorResponse.isServerError &&
        errorResponse.error?.code != 'INSUFFICIENT_PERMISSIONS';
  }

  /// Get suggested action for error
  static String getSuggestedAction(ApiErrorResponse errorResponse) {
    switch (errorResponse.error?.code) {
      case 'VALIDATION_ERROR':
        return 'Please check your input and try again';
      case 'AUTHENTICATION_FAILED':
        return 'Please log in again';
      case 'TOKEN_EXPIRED':
        return 'Please log in again';
      case 'INSUFFICIENT_PERMISSIONS':
        return 'Contact an administrator for access';
      case 'RESOURCE_NOT_FOUND':
        return 'Check if the item still exists';
      case 'DUPLICATE_RESOURCE':
        return 'Try using different information';
      case 'RATE_LIMIT_EXCEEDED':
        return 'Wait a moment before trying again';
      case 'NETWORK_ERROR':
        return 'Check your internet connection';
      case 'TIMEOUT_ERROR':
        return 'Try again in a moment';
      case 'INTERNAL_ERROR':
        return 'Try again later or contact support';
      default:
        return 'Please try again';
    }
  }
}
