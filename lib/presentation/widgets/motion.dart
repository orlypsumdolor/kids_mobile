import 'package:flutter/material.dart';

/// Fade + slight upward-slide entrance, matching the design's `rise` keyframe.
/// Plays once whenever this widget is first mounted (i.e. each time the
/// caller swaps to a new state/branch).
class RiseIn extends StatefulWidget {
  final Widget child;

  const RiseIn({super.key, required this.child});

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}

/// Gentle scale + opacity pulse, matching the design's `scanPulse` keyframe.
/// Wrap the scan-target icon box with this while idly waiting for a scan.
class ScanPulse extends StatefulWidget {
  final Widget child;

  const ScanPulse({super.key, required this.child});

  @override
  State<ScanPulse> createState() => _ScanPulseState();
}

class _ScanPulseState extends State<ScanPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: 0.7 + 0.3 * curved.value,
          child: Transform.scale(
            scale: 1 + 0.04 * curved.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// The design's decorative "Scanner" / "Printer" hardware pointer: a label,
/// a short stem, and a downward chevron, bobbing up and down to draw the eye
/// toward the physical peripheral (matches the `nudgeDown` keyframe).
class HardwarePointer extends StatefulWidget {
  final String label;
  final Color color;
  final CrossAxisAlignment align;

  const HardwarePointer({
    super.key,
    required this.label,
    required this.color,
    this.align = CrossAxisAlignment.center,
  });

  @override
  State<HardwarePointer> createState() => _HardwarePointerState();
}

class _HardwarePointerState extends State<HardwarePointer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sized relative to screen height (~1/4) so it reads as a deliberate,
    // noticeable pointer rather than a small decorative detail.
    final totalH = MediaQuery.sizeOf(context).height * 0.25;
    final fontSize = totalH * 0.14;
    final labelGap = totalH * 0.05;
    final stemW = totalH * 0.03;
    final stemH = totalH * 0.55;
    final chevronSize = totalH * 0.22;
    final chevronBorder = totalH * 0.045;
    final bounce = totalH * 0.12;

    final curved =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final dy = -bounce / 2 + bounce * curved.value;
        final opacity = 0.55 + 0.45 * curved.value;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(offset: Offset(0, dy), child: child),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: widget.align,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: widget.color,
            ),
          ),
          SizedBox(height: labelGap),
          // Stem + chevron always stay centered on each other (the stem
          // must line up with the chevron's tip, not its bounding box
          // edge) — only this whole arrow shape, as a unit, follows
          // widget.align relative to the label above it.
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: stemW,
                height: stemH,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(stemW),
                ),
              ),
              Transform.rotate(
                angle:
                    0.785398, // 45deg: turns a right+bottom border into a chevron
                child: Container(
                  width: chevronSize,
                  height: chevronSize,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                          color: widget.color, width: chevronBorder),
                      bottom: BorderSide(
                          color: widget.color, width: chevronBorder),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
