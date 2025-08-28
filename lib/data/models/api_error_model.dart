class ApiError {
  final String code;
  final String details;
  final String? field;
  final String? value;

  const ApiError({
    required this.code,
    required this.details,
    this.field,
    this.value,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN_ERROR',
      details: json['details'] as String? ?? 'Unknown error occurred',
      field: json['field'] as String?,
      value: json['value'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'details': details,
      if (field != null) 'field': field,
      if (value != null) 'value': value,
    };
  }
}

class ValidationError {
  final String field;
  final String message;
  final String? value;

  const ValidationError({
    required this.field,
    required this.message,
    this.value,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] as String? ?? 'unknown',
      message: json['message'] as String? ?? 'Validation error',
      value: json['value'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'message': message,
      if (value != null) 'value': value,
    };
  }
}

class ApiErrorResponse {
  final bool success;
  final String message;
  final ApiError? error;
  final List<ValidationError>? errors;
  final String? timestamp;
  final String? path;
  final String? method;

  const ApiErrorResponse({
    required this.success,
    required this.message,
    this.error,
    this.errors,
    this.timestamp,
    this.path,
    this.method,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    return ApiErrorResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? 'Unknown error',
      error: json['error'] != null ? ApiError.fromJson(json['error']) : null,
      errors: json['errors'] != null
          ? (json['errors'] as List)
              .map((e) => ValidationError.fromJson(e))
              .toList()
          : null,
      timestamp: json['timestamp'] as String?,
      path: json['path'] as String?,
      method: json['method'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (error != null) 'error': error!.toJson(),
      if (errors != null) 'errors': errors!.map((e) => e.toJson()).toList(),
      if (timestamp != null) 'timestamp': timestamp,
      if (path != null) 'path': path,
      if (method != null) 'method': method,
    };
  }

  /// Check if this is a validation error
  bool get isValidationError => error?.code == 'VALIDATION_ERROR';

  /// Check if this is an authentication error
  bool get isAuthenticationError =>
      error?.code == 'AUTHENTICATION_FAILED' || error?.code == 'TOKEN_EXPIRED';

  /// Check if this is a permission error
  bool get isPermissionError => error?.code == 'INSUFFICIENT_PERMISSIONS';

  /// Check if this is a resource not found error
  bool get isNotFoundError => error?.code == 'RESOURCE_NOT_FOUND';

  /// Check if this is a duplicate resource error
  bool get isDuplicateError => error?.code == 'DUPLICATE_RESOURCE';

  /// Check if this is a rate limit error
  bool get isRateLimitError => error?.code == 'RATE_LIMIT_EXCEEDED';

  /// Check if this is a server error
  bool get isServerError => error?.code == 'INTERNAL_ERROR';

  /// Get field-specific validation errors as a map
  Map<String, String> get fieldErrors {
    if (errors == null) return {};

    final Map<String, String> fieldErrors = {};
    for (final error in errors!) {
      fieldErrors[error.field] = error.message;
    }
    return fieldErrors;
  }

  /// Get the first validation error message for a specific field
  String? getFieldError(String field) {
    if (errors == null) return null;

    for (final error in errors!) {
      if (error.field == field) {
        return error.message;
      }
    }
    return null;
  }
}
