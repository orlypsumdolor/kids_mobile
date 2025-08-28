import 'package:flutter/material.dart';

/// Reusable success message display widget
class SuccessDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final bool showIcon;
  final Duration autoHideDuration;

  const SuccessDisplay({
    super.key,
    required this.message,
    this.onDismiss,
    this.showIcon = true,
    this.autoHideDuration = const Duration(seconds: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              Icons.check_circle_outline,
              color: Colors.green.shade600,
              size: 20.0,
            ),
            const SizedBox(width: 8.0),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 20.0),
              color: Colors.green.shade600,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32.0,
                minHeight: 32.0,
              ),
            ),
        ],
      ),
    );
  }
}

/// Animated success display that automatically hides
class AnimatedSuccessDisplay extends StatefulWidget {
  final String message;
  final VoidCallback? onDismiss;
  final Duration autoHideDuration;
  final VoidCallback? onAutoHide;

  const AnimatedSuccessDisplay({
    super.key,
    required this.message,
    this.onDismiss,
    this.autoHideDuration = const Duration(seconds: 4),
    this.onAutoHide,
  });

  @override
  State<AnimatedSuccessDisplay> createState() => _AnimatedSuccessDisplayState();
}

class _AnimatedSuccessDisplayState extends State<AnimatedSuccessDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // Start animation
    _animationController.forward();

    // Auto-hide after duration
    Future.delayed(widget.autoHideDuration, () {
      if (mounted) {
        _hide();
      }
    });
  }

  void _hide() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onAutoHide?.call();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SuccessDisplay(
          message: widget.message,
          onDismiss: () {
            _hide();
            widget.onDismiss?.call();
          },
        ),
      ),
    );
  }
}

/// Success message that appears as a snackbar
class SuccessSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20.0,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}
