import 'package:flutter/material.dart';

/// Reusable loading indicator widget
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool showMessage;
  final double size;
  final Color? color;
  final bool isCircular;

  const LoadingIndicator({
    super.key,
    this.message,
    this.showMessage = true,
    this.size = 40.0,
    this.color,
    this.isCircular = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCircular)
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? Theme.of(context).primaryColor,
                ),
              ),
            )
          else
            SizedBox(
              width: size,
              height: size,
              child: LinearProgressIndicator(
                backgroundColor: color?.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? Theme.of(context).primaryColor,
                ),
              ),
            ),
          if (showMessage && message != null) ...[
            const SizedBox(height: 16.0),
            Text(
              message!,
              style: TextStyle(
                color: color ?? Theme.of(context).primaryColor,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading indicator with overlay
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;
  final double opacity;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: (backgroundColor ?? Colors.black).withOpacity(opacity),
            child: LoadingIndicator(
              message: message ?? 'Loading...',
              color: Colors.white,
            ),
          ),
      ],
    );
  }
}

/// Loading button that shows loading state
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? loadingChild;
  final String? loadingMessage;
  final ButtonStyle? style;
  final bool isOutlined;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    this.loadingChild,
    this.loadingMessage,
    this.style,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: _buildChild(),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: _buildChild(),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16.0,
            height: 16.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),
          if (loadingMessage != null) ...[
            const SizedBox(width: 8.0),
            Text(loadingMessage!),
          ],
        ],
      );
    }

    return loadingChild ?? child;
  }
}

/// Loading text that shows dots animation
class LoadingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;

  const LoadingText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<LoadingText> createState() => _LoadingTextState();
}

class _LoadingTextState extends State<LoadingText>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        const dots = '...';
        final dotCount = (_animation.value * dots.length).floor();
        final displayDots = dots.substring(0, dotCount);

        return Text(
          '${widget.text}$displayDots',
          style: widget.style,
        );
      },
    );
  }
}
