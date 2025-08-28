import 'package:dio/dio.dart';
import '../../data/models/api_error_model.dart';

/// Service for handling API responses and errors in a standardized way
class ApiResponseHandler {
  /// Handle successful API responses
  static Map<String, dynamic>? handleSuccessResponse(Response response) {
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // Check if the response indicates success
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        } else {
          // Even though success is false, we might have data
          return data['data'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print('Error parsing success response: $e');
      return null;
    }
  }

  /// Handle error responses and convert them to ApiErrorResponse
  static ApiErrorResponse handleErrorResponse(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is Map<String, dynamic>) {
      return ApiErrorResponse.fromJson(error);
    } else {
      return ApiErrorResponse(
        success: false,
        message: error.toString(),
        error: ApiError(
          code: 'UNKNOWN_ERROR',
          details: error.toString(),
        ),
      );
    }
  }

  /// Handle Dio-specific errors
  static ApiErrorResponse _handleDioError(DioException error) {
    // Handle network errors
    if (error.type == DioExceptionType.connectionError) {
      return const ApiErrorResponse(
        success: false,
        message:
            'Network connection error. Please check your internet connection.',
        error: ApiError(
          code: 'NETWORK_ERROR',
          details: 'Failed to connect to the server',
        ),
      );
    }

    // Handle timeout errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiErrorResponse(
        success: false,
        message: 'Request timed out. Please try again.',
        error: ApiError(
          code: 'TIMEOUT_ERROR',
          details: 'Request exceeded time limit',
        ),
      );
    }

    // Handle response errors
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final responseData = error.response!.data;

      // Try to parse the error response from the API
      if (responseData is Map<String, dynamic>) {
        try {
          return ApiErrorResponse.fromJson(responseData);
        } catch (e) {
          // Fallback to status code based error
          return _createStatusBasedError(statusCode, responseData);
        }
      } else {
        return _createStatusBasedError(statusCode, responseData);
      }
    }

    // Handle other Dio errors
    return ApiErrorResponse(
      success: false,
      message: 'An unexpected error occurred',
      error: ApiError(
        code: 'DIO_ERROR',
        details: error.message ?? 'Unknown Dio error',
      ),
    );
  }

  /// Create error response based on HTTP status code
  static ApiErrorResponse _createStatusBasedError(
      int? statusCode, dynamic responseData) {
    String message;
    String code;
    String details;

    switch (statusCode) {
      case 400:
        message = 'Bad request';
        code = 'BAD_REQUEST';
        details = 'The request was invalid or malformed';
        break;
      case 401:
        message = 'Authentication required';
        code = 'AUTHENTICATION_FAILED';
        details = 'Please log in to continue';
        break;
      case 403:
        message = 'Access denied';
        code = 'INSUFFICIENT_PERMISSIONS';
        details = 'You do not have permission to perform this action';
        break;
      case 404:
        message = 'Resource not found';
        code = 'RESOURCE_NOT_FOUND';
        details = 'The requested resource was not found';
        break;
      case 409:
        message = 'Resource conflict';
        code = 'DUPLICATE_RESOURCE';
        details = 'The resource already exists or conflicts with existing data';
        break;
      case 422:
        message = 'Validation failed';
        code = 'VALIDATION_ERROR';
        details = 'The provided data is invalid';
        break;
      case 429:
        message = 'Too many requests';
        code = 'RATE_LIMIT_EXCEEDED';
        details = 'Please wait before making another request';
        break;
      case 500:
        message = 'Internal server error';
        code = 'INTERNAL_ERROR';
        details = 'An unexpected error occurred on the server';
        break;
      case 502:
        message = 'Bad gateway';
        code = 'GATEWAY_ERROR';
        details =
            'The server received an invalid response from an upstream server';
        break;
      case 503:
        message = 'Service unavailable';
        code = 'SERVICE_UNAVAILABLE';
        details = 'The service is temporarily unavailable';
        break;
      default:
        message = 'An error occurred';
        code = 'HTTP_ERROR';
        details = 'HTTP $statusCode error';
    }

    return ApiErrorResponse(
      success: false,
      message: message,
      error: ApiError(
        code: code,
        details: details,
      ),
    );
  }

  /// Check if a response is successful
  static bool isSuccessResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return data['success'] == true;
    }
    return response.statusCode! >= 200 && response.statusCode! < 300;
  }

  /// Extract success message from response
  static String? getSuccessMessage(Response response) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return data['message'] as String?;
    }
    return null;
  }

  /// Extract pagination data from response
  static Map<String, dynamic>? getPaginationData(Response response) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return data['pagination'] as Map<String, dynamic>?;
    }
    return null;
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(ApiErrorResponse errorResponse) {
    // For validation errors, show the first field error
    if (errorResponse.isValidationError &&
        errorResponse.errors != null &&
        errorResponse.errors!.isNotEmpty) {
      final firstError = errorResponse.errors!.first;
      return '${firstError.field}: ${firstError.message}';
    }

    // For other errors, show the main message
    return errorResponse.message;
  }

  /// Check if error is retryable
  static bool isRetryableError(ApiErrorResponse errorResponse) {
    // Retry server errors (5xx) and network errors
    return errorResponse.isServerError ||
        errorResponse.error?.code == 'NETWORK_ERROR' ||
        errorResponse.error?.code == 'TIMEOUT_ERROR';
  }

  /// Get retry delay for rate limit errors
  static Duration? getRetryDelay(ApiErrorResponse errorResponse) {
    if (errorResponse.isRateLimitError) {
      // Default to 60 seconds for rate limit errors
      return const Duration(seconds: 60);
    }
    return null;
  }
}
