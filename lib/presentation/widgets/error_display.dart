import 'package:flutter/material.dart';
import '../../data/models/api_error_model.dart';
import '../../core/utils/error_utils.dart';

/// Reusable error display widget that handles different error types
class ErrorDisplay extends StatelessWidget {
  final ApiErrorResponse? errorResponse;
  final String? customErrorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showDetails;
  final bool showActions;

  const ErrorDisplay({
    super.key,
    this.errorResponse,
    this.customErrorMessage,
    this.onRetry,
    this.onDismiss,
    this.showDetails = false,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    if (errorResponse == null && customErrorMessage == null) {
      return const SizedBox.shrink();
    }

    final message =
        customErrorMessage ?? ErrorUtils.getUserFriendlyMessage(errorResponse!);
    final errorCategory = errorResponse != null
        ? ErrorUtils.getErrorCategory(errorResponse!)
        : 'general';

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _getErrorColor(errorCategory),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: _getErrorBorderColor(errorCategory),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getErrorIcon(errorCategory),
                color: _getErrorIconColor(errorCategory),
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: _getErrorTextColor(errorCategory),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 20.0),
                  color: _getErrorTextColor(errorCategory),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32.0,
                    minHeight: 32.0,
                  ),
                ),
            ],
          ),
          if (showDetails && errorResponse != null) ...[
            const SizedBox(height: 8.0),
            _buildErrorDetails(context),
          ],
          if (showActions) ...[
            const SizedBox(height: 12.0),
            _buildErrorActions(context),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorDetails(BuildContext context) {
    if (errorResponse == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorResponse!.error?.details != null) ...[
          Text(
            'Details: ${errorResponse!.error!.details}',
            style: TextStyle(
              color: _getErrorTextColor(
                      ErrorUtils.getErrorCategory(errorResponse!))
                  .withOpacity(0.8),
              fontSize: 12.0,
            ),
          ),
          const SizedBox(height: 4.0),
        ],
        if (errorResponse!.errors != null &&
            errorResponse!.errors!.isNotEmpty) ...[
          Text(
            'Validation Errors:',
            style: TextStyle(
              color: _getErrorTextColor(
                      ErrorUtils.getErrorCategory(errorResponse!))
                  .withOpacity(0.8),
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4.0),
          ...errorResponse!.errors!.map((error) => Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  '• ${error.field}: ${error.message}',
                  style: TextStyle(
                    color: _getErrorTextColor(
                            ErrorUtils.getErrorCategory(errorResponse!))
                        .withOpacity(0.7),
                    fontSize: 11.0,
                  ),
                ),
              )),
        ],
        if (errorResponse!.timestamp != null) ...[
          const SizedBox(height: 4.0),
          Text(
            'Time: ${errorResponse!.timestamp}',
            style: TextStyle(
              color: _getErrorTextColor(
                      ErrorUtils.getErrorCategory(errorResponse!))
                  .withOpacity(0.6),
              fontSize: 10.0,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (errorResponse != null &&
            ErrorUtils.shouldRetry(errorResponse!)) ...[
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16.0),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: _getErrorTextColor(
                  ErrorUtils.getErrorCategory(errorResponse!)),
            ),
          ),
          const SizedBox(width: 8.0),
        ],
        if (errorResponse != null &&
            ErrorUtils.requiresUserAction(errorResponse!)) ...[
          TextButton.icon(
            onPressed: () {
              // Show suggested action in a snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ErrorUtils.getSuggestedAction(errorResponse!)),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            icon: const Icon(Icons.info_outline, size: 16.0),
            label: const Text('Help'),
            style: TextButton.styleFrom(
              foregroundColor: _getErrorTextColor(
                  ErrorUtils.getErrorCategory(errorResponse!)),
            ),
          ),
        ],
      ],
    );
  }

  Color _getErrorColor(String category) {
    switch (category) {
      case 'validation':
        return Colors.orange.shade50;
      case 'authentication':
        return Colors.red.shade50;
      case 'permission':
        return Colors.purple.shade50;
      case 'server':
        return Colors.red.shade50;
      case 'network':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getErrorBorderColor(String category) {
    switch (category) {
      case 'validation':
        return Colors.orange.shade200;
      case 'authentication':
        return Colors.red.shade200;
      case 'permission':
        return Colors.purple.shade200;
      case 'server':
        return Colors.red.shade200;
      case 'network':
        return Colors.blue.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getErrorTextColor(String category) {
    switch (category) {
      case 'validation':
        return Colors.orange.shade800;
      case 'authentication':
        return Colors.red.shade800;
      case 'permission':
        return Colors.purple.shade800;
      case 'server':
        return Colors.red.shade800;
      case 'network':
        return Colors.blue.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  Color _getErrorIconColor(String category) {
    switch (category) {
      case 'validation':
        return Colors.orange.shade600;
      case 'authentication':
        return Colors.red.shade600;
      case 'permission':
        return Colors.purple.shade600;
      case 'server':
        return Colors.red.shade600;
      case 'network':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getErrorIcon(String category) {
    switch (category) {
      case 'validation':
        return Icons.warning_amber_rounded;
      case 'authentication':
        return Icons.lock_outline;
      case 'permission':
        return Icons.block;
      case 'server':
        return Icons.error_outline;
      case 'network':
        return Icons.wifi_off;
      default:
        return Icons.error_outline;
    }
  }
}

/// Simple error message display for basic error strings
class SimpleErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const SimpleErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorDisplay(
      customErrorMessage: message,
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }
}
