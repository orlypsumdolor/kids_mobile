import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:convert';
import '../../providers/checkout_provider.dart';
import '../../providers/checkin_provider.dart';
import '../../widgets/app_shell_header.dart';
import '../../widgets/inline_error_banner.dart';
import '../../widgets/motion.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/hardware_scanner_service.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/theme/app_theme.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  // Parsed from the pickup slip QR
  Map<String, dynamic>? _scannedQrData;
  List<Map<String, dynamic>>? _childInfo;

  // Hardware barcode scanner (M7710)
  late final FocusNode _scannerFocusNode;
  StreamSubscription<String>? _scannerSubscription;

  // Idle-scan sweep-line animation
  late final AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerFocusNode = FocusNode(debugLabel: 'checkoutScanner');

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    final scannerService = context.read<HardwareScannerService>();
    _scannerSubscription = scannerService.onBarcodeScanned.listen((barcode) {
      if (mounted && !_isLoading && _scannedQrData == null) {
        print('📡 Hardware scanner (checkout): "$barcode"');
        _processQrCode(barcode);
      }
    });
  }

  @override
  void dispose() {
    _scannerSubscription?.cancel();
    _scannerFocusNode.dispose();
    _sweepController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _scannerFocusNode.requestFocus();
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final scannerService = context.read<HardwareScannerService>();
    return scannerService.handleKeyEvent(event);
  }

  void _resetForm() {
    setState(() {
      _scannedQrData = null;
      _childInfo = null;
      _error = null;
      _successMessage = null;
    });
    _scannerFocusNode.requestFocus();
  }

  Future<void> _openCameraScanner() async {
    final result = await context.push<String>(
      AppRouter.qrScanner,
      extra: {
        'title': 'Scan Pickup Slip QR',
        'onScanComplete': (String qrCode) async {
          await _processQrCode(qrCode);
        },
      },
    );
    if (result != null) {
      await _processQrCode(result);
    }
    _scannerFocusNode.requestFocus();
  }

  Future<void> _processQrCode(String qrCode) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final decoded = jsonDecode(qrCode);
      if (decoded is! Map<String, dynamic> ||
          !decoded.containsKey('guardianQrCode') ||
          !decoded.containsKey('pickupCodes') ||
          !decoded.containsKey('childIds')) {
        throw const FormatException('Not a valid pickup slip QR code');
      }

      final guardianQr = decoded['guardianQrCode'];
      final pickupCodes = decoded['pickupCodes'];
      final childIds = decoded['childIds'];

      if (guardianQr is! String || pickupCodes is! List || childIds is! List) {
        throw const FormatException('Invalid data types in QR payload');
      }

      // Fetch child names
      final checkoutProvider = context.read<CheckoutProvider>();
      List<Map<String, dynamic>>? names;
      try {
        final ids = childIds.cast<String>();
        names = await checkoutProvider.fetchChildNamesPublic(ids);
      } catch (_) {}

      setState(() {
        _scannedQrData = decoded;
        _childInfo = names;
      });
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Failed to read QR code: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performCheckout() async {
    if (_scannedQrData == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final guardianId = _scannedQrData!['guardianQrCode'] as String;
      final childIds = (_scannedQrData!['childIds'] as List).cast<String>();
      final pickupCodes =
          (_scannedQrData!['pickupCodes'] as List).cast<String>();

      final checkinProvider = context.read<CheckinProvider>();
      final records = await checkinProvider.checkOutChildren(
        guardianId: guardianId,
        childIds: childIds,
        pickupCodes: pickupCodes,
      );

      if (records.isNotEmpty) {
        final names = _childInfo != null
            ? _childInfo!.map((c) => c['name']).join(' · ')
            : '${records.length} child(ren)';

        setState(() {
          _successMessage = names;
          _scannedQrData = null;
          _childInfo = null;
        });

        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() => _successMessage = null);
            _scannerFocusNode.requestFocus();
          }
        });
      } else {
        setState(() => _error = 'No children were checked out');
      }
    } catch (e) {
      final msg = e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      setState(() => _error = msg);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final printerConnected = context.watch<PrinterService>().isConnected;

    return Focus(
      focusNode: _scannerFocusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: GestureDetector(
        onTap: () => _scannerFocusNode.requestFocus(),
        child: Scaffold(
          backgroundColor: AppTheme.pageBackground,
          body: Column(
            children: [
              AppShellHeader(
                title: 'Check Out',
                subtitle: 'Pickup slip',
                showBackButton: true,
                onBack: () => context.pop(),
                onSettings: () => context.push(AppRouter.settings),
                printerConnected: printerConnected,
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.green),
            SizedBox(height: 16),
            Text('Processing...',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    if (_successMessage != null) {
      return _buildSuccess();
    }

    if (_error != null && _scannedQrData == null) {
      return _buildError();
    }

    if (_scannedQrData != null) {
      return _buildConfirmation();
    }

    return _buildWaitingForScan();
  }

  Widget _buildWaitingForScan() {
    return Stack(
      children: [
        const Positioned(
          left: 36,
          bottom: 24,
          child: HardwarePointer(
              label: 'Scan Here',
              color: AppTheme.green,
              align: CrossAxisAlignment.start),
        ),
        Positioned(
          top: 16,
          right: 20,
          child: CircleIconButton(
            onTap: _openCameraScanner,
            child: const Icon(Icons.camera_alt_outlined, size: 20),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  constraints:
                      const BoxConstraints(maxWidth: 420, minHeight: 300),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border:
                        Border.all(color: const Color(0xFFB9C6DC), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      AnimatedBuilder(
                        animation: _sweepController,
                        builder: (context, child) {
                          return Align(
                            alignment: Alignment(
                                0, _sweepController.value * 1.8 - 0.9),
                            child: Container(
                              height: 3,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.green.withValues(alpha: 0),
                                    AppTheme.green,
                                    AppTheme.green.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScanPulse(
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: AppTheme.textPrimary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Icon(Icons.qr_code,
                                    color: Colors.white, size: 44),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Scan pickup slip',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "The QR on the guardian's slip",
                            style: TextStyle(
                                fontSize: 13.5, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lost slip? A staff member can release with ID verification.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmation() {
    final childNames = _childInfo != null
        ? _childInfo!.map((c) => c['name'] as String).toList()
        : (_scannedQrData!['childIds'] as List)
            .map((id) => id.toString())
            .toList();
    final pickupCodes = (_scannedQrData!['pickupCodes'] as List).cast<String>();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: RiseIn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusCardLarge),
                      border: Border.all(color: AppTheme.hairline),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: AppTheme.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.qr_code, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SLIP VERIFIED',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: AppTheme.green,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Pickup slip scanned',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Check each name and code against the slip in the guardian's hand.",
                    style: TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.textTertiary,
                        height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(childNames.length, (i) {
                    final code = i < pickupCodes.length ? pickupCodes[i] : '';
                    final color = const [
                      AppTheme.green,
                      AppTheme.blue,
                      AppTheme.yellow,
                      AppTheme.magenta,
                    ][i % 4];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusCard),
                        border: Border.all(color: AppTheme.hairline, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusPill),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              childNames[i],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (code.isNotEmpty)
                            Text(code, style: AppTheme.mono(fontSize: 15)),
                        ],
                      ),
                    );
                  }),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    InlineErrorBanner(
                      message: _error!,
                      onDismiss: () => setState(() => _error = null),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.hairline)),
          ),
          child: Row(
            children: [
              OutlinedButton(
                  onPressed: _resetForm, child: const Text('Cancel')),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _performCheckout,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppTheme.green),
                  child: const Text('Confirm check-out'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Container(
      color: AppTheme.successBg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: RiseIn(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: AppTheme.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Checked out',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _successMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14.5, color: AppTheme.successText),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _resetForm,
                  child: const Text('Next guardian'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppTheme.errorBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.errorBorder, width: 2),
              ),
              child: const Icon(Icons.error_outline,
                  size: 36, color: AppTheme.error),
            ),
            const SizedBox(height: 24),
            const Text(
              'Unreadable slip',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 14, color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetForm,
              child: const Text('Scan again'),
            ),
          ],
        ),
      ),
    );
  }
}
