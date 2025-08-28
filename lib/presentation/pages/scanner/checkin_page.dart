import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/child_info_card.dart';
import '../../widgets/service_selector.dart';
import '../../widgets/scan_method_selector.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/printer_service.dart';
import 'package:flutter/foundation.dart';

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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Check-In'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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

              // Printer Status Check
              Consumer<PrinterService>(
                builder: (context, printerService, child) {
                  if (!printerService.isConnected) {
                    return _buildPrinterNotConnectedCard(context);
                  }

                  // Show scan methods only if printer is connected
                  if (selectedServiceId != null) {
                    return Column(
                      children: [
                        _buildPrinterConnectedCard(printerService),
                        const SizedBox(height: 20),
                        ScanMethodSelector(
                          onQRScan: () => _handleQRScan(),
                          onRFIDScan: () => _handleRFIDScan(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

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
                            const Icon(
                              Icons.error_outline,
                              color: Color.fromARGB(255, 218, 69, 59),
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        const Color.fromARGB(255, 218, 69, 59),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 218, 69, 59),
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
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Success!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.green),
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
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

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build card showing printer is not connected
  Widget _buildPrinterNotConnectedCard(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.print_disabled,
              size: 48,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'Printer Not Connected',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You need to connect a printer before you can check in children and print stickers.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _navigateToSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Connect Printer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _showPrinterHelp(context),
              child: Text(
                'Need Help?',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build card showing printer is connected
  Widget _buildPrinterConnectedCard(PrinterService printerService) {
    final connectedDevice = printerService.connectedDevice;
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.print,
              color: Colors.green.shade600,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Printer Connected',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (connectedDevice?.name != null)
                    Text(
                      connectedDevice!.name,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _navigateToSettings(),
              icon: Icon(
                Icons.settings,
                color: Colors.green.shade600,
              ),
              tooltip: 'Printer Settings',
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to settings page to manage printer
  void _navigateToSettings() {
    context.push('/settings');
  }

  /// Show printer help information
  void _showPrinterHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Printer Setup Help'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To connect a printer:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('1. Go to Settings > Printer Setup'),
            const Text('2. Tap "Scan for Printers"'),
            const Text('3. Select your printer from the list'),
            const Text('4. Wait for connection confirmation'),
            const SizedBox(height: 16),
            Text(
              'Supported printers:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('• Bluetooth thermal printers'),
            const Text('• ESC/POS compatible printers'),
            const Text('• Most label printers'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToSettings();
            },
            child: const Text('Go to Settings'),
          ),
        ],
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
