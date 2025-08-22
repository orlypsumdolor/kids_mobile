import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pickup_code_input.dart';
import '../../../core/router/app_router.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _pickupCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckoutProvider>().clearSession();
    });
  }

  @override
  void dispose() {
    _pickupCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-Out'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-Out Methods',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Scan the child\'s QR code or RFID tag\n'
                        '2. Enter the pickup code from the sticker\n'
                        '3. Verify guardian information',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Scan Options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Child',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleQRScan(),
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Scan QR Code'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleRFIDScan(),
                              icon: const Icon(Icons.nfc),
                              label: const Text('Scan RFID'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pickup Code Input
              PickupCodeInput(
                controller: _pickupCodeController,
                onSubmit: (code) => _handlePickupCodeEntry(code),
              ),
              const SizedBox(height: 20),

              // Status Display
              Consumer<CheckoutProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (provider.error != null) {
                    return Card(
                      color:
                          Theme.of(context).colorScheme.error.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Verification Failed',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => provider.clearSession(),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (provider.successMessage != null) {
                    return Card(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check-Out Successful!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.successMessage!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                provider.clearSession();
                                _pickupCodeController.clear();
                              },
                              child: const Text('Check Out Another Child'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleQRScan() {
    context.push(AppRouter.qrScanner, extra: {
      'onScanComplete': (String qrCode) {
        // Handle QR code scan for checkout
        _processChildScan(qrCode, isQR: true);
      },
      'title': 'Scan Child QR Code',
    });
  }

  void _handleRFIDScan() {
    final provider = context.read<CheckoutProvider>();
    provider.startNFCScanning((rfidCode) {
      Navigator.of(context).pop(); // Close scanning dialog
      _processChildScan(rfidCode, isQR: false);
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Scanning RFID'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Hold the RFID tag near your device'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.stopNFCScanning();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _processChildScan(String code, {required bool isQR}) {
    // In a real app, you would look up the child and show verification dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Pickup Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Child scanned successfully. Please enter the pickup code to verify guardian.'),
            const SizedBox(height: 16),
            TextField(
              controller: _pickupCodeController,
              decoration: const InputDecoration(
                labelText: 'Pickup Code',
                hintText: 'Enter 6-digit code',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handlePickupCodeEntry(_pickupCodeController.text);
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _handlePickupCodeEntry(String pickupCode) {
    if (pickupCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup code must be 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final checkoutProvider = context.read<CheckoutProvider>();

    if (authProvider.currentUser != null) {
      // In a real app, you would verify the pickup code and check out the child
      checkoutProvider.checkOutChild(
          'mock-session-id', authProvider.currentUser!.id);
    }
  }
}
