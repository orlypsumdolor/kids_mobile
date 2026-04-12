import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Service that captures barcode/QR data from USB HID barcode scanners
/// (e.g. MS-M7710 embedded in kiosks).
///
/// USB HID scanners emulate a keyboard: they send characters rapidly followed
/// by Enter (or a configurable suffix). This service buffers those keystrokes
/// and emits the complete barcode string via [onBarcodeScanned].
class HardwareScannerService {
  HardwareScannerService({
    this.suffixKey = LogicalKeyboardKey.enter,
    this.maxInputGap = const Duration(milliseconds: 100),
    this.minBarcodeLength = 3,
  });

  /// The key that terminates a barcode scan (usually Enter).
  final LogicalKeyboardKey suffixKey;

  /// Max gap between keystrokes to consider them part of a single scan.
  /// Human typing is much slower; scanner bursts arrive < 50 ms apart.
  final Duration maxInputGap;

  /// Minimum barcode length to accept (filters accidental key presses).
  final int minBarcodeLength;

  final _buffer = StringBuffer();
  Timer? _resetTimer;
  DateTime? _lastKeystroke;

  final _controller = StreamController<String>.broadcast();

  /// Stream of successfully scanned barcode/QR strings.
  Stream<String> get onBarcodeScanned => _controller.stream;

  bool _enabled = true;
  bool get isEnabled => _enabled;

  /// Temporarily disable scanning (e.g. when a text field is focused).
  void disable() => _enabled = false;

  /// Re-enable scanning.
  void enable() => _enabled = true;

  /// Call this from a [KeyEvent] handler (via [FocusNode.onKeyEvent]).
  /// Returns [KeyEventResult.handled] if the event was consumed by the
  /// scanner service, [KeyEventResult.ignored] otherwise.
  KeyEventResult handleKeyEvent(KeyEvent event) {
    if (!_enabled) return KeyEventResult.ignored;

    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final now = DateTime.now();

    // If the gap since the last keystroke is too large, this is probably
    // manual typing — reset the buffer.
    if (_lastKeystroke != null && now.difference(_lastKeystroke!) > maxInputGap) {
      _buffer.clear();
    }
    _lastKeystroke = now;

    // Check for the termination key.
    if (event.logicalKey == suffixKey) {
      _onScanComplete();
      return KeyEventResult.handled;
    }

    // Append printable character.
    final char = event.character;
    if (char != null && char.isNotEmpty && char.codeUnitAt(0) >= 32) {
      _buffer.write(char);
      _restartResetTimer();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _restartResetTimer() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      _buffer.clear();
    });
  }

  void _onScanComplete() {
    _resetTimer?.cancel();
    final barcode = _buffer.toString().trim();
    _buffer.clear();

    if (barcode.length >= minBarcodeLength) {
      print('📡 Hardware scanner captured: "$barcode" (${barcode.length} chars)');
      _controller.add(barcode);
    }
  }

  void dispose() {
    _resetTimer?.cancel();
    _controller.close();
  }
}
