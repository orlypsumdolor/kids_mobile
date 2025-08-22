import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/child_info_card.dart';
import '../../widgets/service_selector.dart';
import '../../widgets/scan_method_selector.dart';
import '../../../core/router/app_router.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  String? selectedServiceId;

  @override
  void initState() {
    super.initState();
    // Clear any previous scan data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckinProvider>().clearScannedChild();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-In'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Service Selection
              ServiceSelector(
                selectedServiceId: selectedServiceId,
                onServiceSelected: (serviceId) {
                  setState(() {
                    selectedServiceId = serviceId;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Scan Method Selection
              if (selectedServiceId != null) ...[
                ScanMethodSelector(
                  onQRScan: () => _handleQRScan(),
                  onRFIDScan: () => _handleRFIDScan(),
                ),
                const SizedBox(height: 20),
              ],

              // Scanned Child Information
              Consumer<CheckinProvider>(
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
                              'Error',
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
                              onPressed: () => provider.clearScannedChild(),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (provider.scannedChild != null) {
                    return Column(
                      children: [
                        ChildInfoCard(child: provider.scannedChild!),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _handleCheckIn(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Check In Child',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => provider.clearScannedChild(),
                          child: const Text('Scan Different Child'),
                        ),
                      ],
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
                              'Success!',
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
                              onPressed: () => provider.clearScannedChild(),
                              child: const Text('Check In Another Child'),
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
        context.read<CheckinProvider>().scanQRCode(qrCode);
      },
      'title': 'Scan Child QR Code',
    });
  }

  void _handleRFIDScan() {
    final provider = context.read<CheckinProvider>();
    provider.startNFCScanning();

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

  void _handleCheckIn() {
    final authProvider = context.read<AuthProvider>();
    final checkinProvider = context.read<CheckinProvider>();

    if (authProvider.currentUser != null && selectedServiceId != null) {
      checkinProvider.checkInChild(
        authProvider.currentUser!.id,
        selectedServiceId!,
      );
    }
  }
}
