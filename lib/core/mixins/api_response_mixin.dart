import 'package:flutter/foundation.dart';
import '../services/api_response_handler.dart';
import '../../data/models/api_error_model.dart';

/// Mixin that provides standardized API response handling for providers
mixin ApiResponseMixin on ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  ApiErrorResponse? _lastError;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  ApiErrorResponse? get lastError => _lastError;

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void setError(String error) {
    _error = error;
    _successMessage = null;
    notifyListeners();
  }

  /// Set success message
  void setSuccessMessage(String message) {
    _successMessage = message;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear success message
  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  /// Clear all messages
  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Handle API response with automatic error handling
  Future<T?> handleApiResponse<T>({
    required Future<T> Function() apiCall,
    String? successMessage,
    String? errorMessage,
    bool showLoading = true,
    Function(T)? onSuccess,
    Function(ApiErrorResponse)? onError,
    Function()? onFinally,
  }) async {
    if (showLoading) {
      setLoading(true);
    }

    try {
      final result = await apiCall();

      if (result != null) {
        if (successMessage != null) {
          setSuccessMessage(successMessage);
        }
        onSuccess?.call(result);
      }

      return result;
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      _lastError = errorResponse;

      final userMessage = errorMessage ??
          ApiResponseHandler.getUserFriendlyMessage(errorResponse);

      setError(userMessage);

      onError?.call(errorResponse);

      // Log detailed error for debugging
      if (kDebugMode) {
        print('API Error: ${errorResponse.message}');
        print('Error Code: ${errorResponse.error?.code}');
        print('Error Details: ${errorResponse.error?.details}');
        if (errorResponse.errors != null) {
          print('Validation Errors: ${errorResponse.errors}');
        }
      }

      return null;
    } finally {
      if (showLoading) {
        setLoading(false);
      }
      onFinally?.call();
    }
  }

  /// Handle API response with custom success/error logic
  Future<T?> handleApiResponseWithCustomLogic<T>({
    required Future<T> Function() apiCall,
    required T? Function(T) successHandler,
    required String Function(ApiErrorResponse) errorHandler,
    bool showLoading = true,
    Function()? onFinally,
  }) async {
    if (showLoading) {
      setLoading(true);
    }

    try {
      final result = await apiCall();

      if (result != null) {
        final successResult = successHandler(result);
        if (successResult != null) {
          return successResult;
        }
      }

      return result;
    } catch (e) {
      final errorResponse = ApiResponseHandler.handleErrorResponse(e);
      _lastError = errorResponse;

      final userMessage = errorHandler(errorResponse);
      setError(userMessage);

      return null;
    } finally {
      if (showLoading) {
        setLoading(false);
      }
      onFinally?.call();
    }
  }

  /// Check if the last error is of a specific type
  bool isLastErrorType(String errorCode) {
    return _lastError?.error?.code == errorCode;
  }

  /// Check if the last error is a validation error
  bool get isLastErrorValidation => _lastError?.isValidationError ?? false;

  /// Check if the last error is an authentication error
  bool get isLastErrorAuthentication =>
      _lastError?.isAuthenticationError ?? false;

  /// Check if the last error is a permission error
  bool get isLastErrorPermission => _lastError?.isPermissionError ?? false;

  /// Check if the last error is a not found error
  bool get isLastErrorNotFound => _lastError?.isNotFoundError ?? false;

  /// Check if the last error is retryable
  bool get isLastErrorRetryable =>
      _lastError != null && ApiResponseHandler.isRetryableError(_lastError!);

  /// Get retry delay for the last error
  Duration? get lastErrorRetryDelay =>
      _lastError != null ? ApiResponseHandler.getRetryDelay(_lastError!) : null;

  /// Get field-specific validation errors from the last error
  Map<String, String> get lastErrorFieldErrors => _lastError?.fieldErrors ?? {};

  /// Get validation error for a specific field
  String? getLastErrorFieldError(String field) {
    return _lastError?.getFieldError(field);
  }

  /// Clear the last error
  void clearLastError() {
    _lastError = null;
  }
}
