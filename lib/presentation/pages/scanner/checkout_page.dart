import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:convert';
import '../../providers/checkout_provider.dart';
import '../../providers/checkin_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/hardware_scanner_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  // Parsed from the pickup slip QR
  Map<String, dynamic>? _scannedQrData;
  List<Map<String, dynamic>>? _childInfo;

  // Hardware barcode scanner (M7710)
  late final FocusNode _scannerFocusNode;
  StreamSubscription<String>? _scannerSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerFocusNode = FocusNode(debugLabel: 'checkoutScanner');

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

      if (guardianQr is! String ||
          pickupCodes is! List ||
          childIds is! List) {
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
      final childIds =
          (_scannedQrData!['childIds'] as List).cast<String>();
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
            ? _childInfo!.map((c) => c['name']).join(', ')
            : '${records.length} child(ren)';

        setState(() {
          _successMessage =
              'Successfully checked out $names';
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
    return Focus(
      focusNode: _scannerFocusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: GestureDetector(
        onTap: () => _scannerFocusNode.requestFocus(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Check-Out'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            actions: [
              if (_scannedQrData != null)
                IconButton(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Start Over',
                ),
            ],
          ),
          body: SafeArea(
            child: _buildBody(),
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
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing...'),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Scan Pickup Slip',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan the pickup slip QR code using the\nkiosk scanner or the camera button below',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Kiosk scanner ready',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _openCameraScanner,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Use Camera Instead'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmation() {
    final childNames = _childInfo != null
        ? _childInfo!.map((c) => c['name'] as String).toList()
        : (_scannedQrData!['childIds'] as List)
            .map((id) => id.toString())
            .toList();
    final pickupCodes =
        (_scannedQrData!['pickupCodes'] as List).cast<String>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Pickup Slip Scanned',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text(
                    'Children to check out:',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(childNames.length, (i) {
                    final code =
                        i < pickupCodes.length ? pickupCodes[i] : '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.child_care,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  childNames[i],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                if (code.isNotEmpty)
                                  Text(
                                    'Code: $code',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetForm,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _performCheckout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Confirm Check-Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle,
                  size: 80, color: Colors.green.shade600),
            ),
            const SizedBox(height: 24),
            Text(
              'Check-Out Successful!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              _successMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: _resetForm,
              child: const Text('Check Out Another'),
            ),
          ],
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: 80, color: Colors.red.shade600),
            ),
            const SizedBox(height: 24),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _resetForm,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
