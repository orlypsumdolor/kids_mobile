import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_usb_thermal_plugin/model/usb_device_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_shell_header.dart';
import '../../../core/models/connected_printer_info.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late PrinterService _printerService;
  bool _isScanning = false;
  List<dynamic> _availableDevices = [];
  List<UsbDevice> _availableUsbDevices = [];
  bool _showUsbDevices = false; // false = Bluetooth list, true = USB list
  ConnectedPrinterInfo? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _loadPrinterStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh printer status when dependencies change (e.g., when returning to this page)
    _refreshPrinterStatus();
  }

  void _loadPrinterStatus() {
    // Get the printer service from the provider system
    _printerService = context.read<PrinterService>();
    _refreshPrinterStatus();
  }

  void _refreshPrinterStatus() {
    if (mounted) {
      setState(() {
        _connectedDevice = _printerService.connectedDevice;
        print(
            '🔄 Refreshed printer status: ${_connectedDevice?.name ?? 'None'}');
      });
    }
  }

  void _disconnectPrinter() async {
    try {
      await _printerService.disconnect();
      setState(() {
        _connectedDevice = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer disconnected successfully'),
          backgroundColor: AppTheme.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect printer: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _scanForPrinters([void Function()? onComplete]) async {
    setState(() {
      _isScanning = true;
    });

    try {
      final devices = await _printerService.getAvailableDevicesWithTimeout();
      setState(() {
        _availableDevices = devices;
        _isScanning = false;
      });
      onComplete?.call();
      if (devices.isEmpty && mounted) {
        final status = await _printerService.checkPermissionStatus();
        final hasBluetoothPermission = status['bluetooth'] == true &&
            status['bluetoothScan'] == true &&
            status['bluetoothConnect'] == true;
        if (!hasBluetoothPermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Bluetooth permission required. Enable "Nearby devices" and "Location" in app Settings to scan for printers.',
              ),
              backgroundColor: AppTheme.warningTextStrong,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Open Settings',
                textColor: Colors.white,
                onPressed: () => _printerService.openAppSettings(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No printers found. Make sure Bluetooth is on and your printer is discoverable.',
              ),
              backgroundColor: AppTheme.warningTextStrong,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      onComplete?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to scan for printers: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _scanForUsbPrinters([void Function()? onComplete]) async {
    setState(() {
      _isScanning = true;
      _showUsbDevices = true;
      _availableUsbDevices = [];
    });

    try {
      final devices =
          await _printerService.getAvailableUsbDevicesWithTimeout();
      if (mounted) {
        setState(() {
          _availableUsbDevices = devices;
          _isScanning = false;
        });
        onComplete?.call();
        if (devices.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No USB printers found. Connect a USB printer and try again.'),
              backgroundColor: AppTheme.warningTextStrong,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        onComplete?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to scan for USB printers: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _connectToBluetoothPrinter(dynamic device) async {
    try {
      final success = await _printerService.connectBluetooth(device);
      if (success) {
        setState(() {
          _connectedDevice = _printerService.connectedDevice;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Connected to ${device.name ?? 'Unknown'} successfully'),
            backgroundColor: AppTheme.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to ${device.name ?? 'Unknown'}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to printer: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _connectToUsbPrinter(UsbDevice device) async {
    try {
      final vendorId = device.vendorId;
      final productId = device.productId;
      if (vendorId.isEmpty || productId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid USB printer'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      final name = device.productName.isNotEmpty
          ? device.productName
          : '${device.manufacturer} USB Printer';
      final success = await _printerService.connectUsb(
        name,
        vendorId,
        productId,
      );
      if (success) {
        setState(() {
          _connectedDevice = _printerService.connectedDevice;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to $name (USB) successfully'),
            backgroundColor: AppTheme.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to $name'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to USB printer: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: Column(
        children: [
          AppShellHeader(
            title: 'Settings',
            showBackButton: true,
            onBack: () => context.pop(),
            onSettings: () {},
            printerConnected: _connectedDevice != null,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Printer Settings
                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PRINTER',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _connectedDevice?.name ?? 'No printer',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  Text(
                                    _connectedDevice != null
                                        ? 'Connected · ${_connectedDevice!.isUsb ? 'USB' : 'Bluetooth'}'
                                        : 'Not connected',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _connectedDevice != null
                                          ? const Color(0xFF1F6E39)
                                          : const Color(0xFF8E2A1F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: _connectedDevice != null
                                  ? _disconnectPrinter
                                  : _showPrinterSelection,
                              child: Text(
                                _connectedDevice != null ? 'Disconnect' : 'Connect',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ElevatedButton(
                              onPressed: _testPrint,
                              child: const Text('Test print'),
                            ),
                            OutlinedButton(
                              onPressed: () =>
                                  _showPrinterSelection(forceUsb: false, autoScan: true),
                              child: const Text('Scan Bluetooth'),
                            ),
                            OutlinedButton(
                              onPressed: () =>
                                  _showPrinterSelection(forceUsb: true, autoScan: true),
                              child: const Text('Scan USB'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scanner status
                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SCANNER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: AppTheme.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'MS-M7710 · USB-HID',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Keyboard wedge · ready',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => _testPrint(),
                          child: const Text('View sticker & slip layout'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const _SettingsGapBanner(),
                  const SizedBox(height: 16),

                  // User info + logout
                  _SettingsCard(
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final user = authProvider.currentUser;
                        if (user == null) return const SizedBox.shrink();

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${user.role} · v1.0.0',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                await context.read<AuthProvider>().logout();
                                if (context.mounted) {
                                  context.go(AppRouter.login);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.error,
                                side: const BorderSide(color: AppTheme.errorBorder, width: 1.5),
                              ),
                              child: const Text('Log out'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrinterSelection({bool? forceUsb, bool autoScan = false}) {
    _showUsbDevices = forceUsb ?? false;
    bool didAutoScan = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void refreshModal() {
            setModalState(() {
              _connectedDevice = _printerService.connectedDevice;
            });
          }

          if (autoScan && !didAutoScan) {
            didAutoScan = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setModalState(() => _isScanning = true);
              if (_showUsbDevices) {
                _scanForUsbPrinters(() => setModalState(() {}));
              } else {
                _scanForPrinters(() => setModalState(() {}));
              }
            });
          }

          return Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Printer',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                // Bluetooth / USB choice
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.bluetooth,
                          color: _showUsbDevices ? null : Theme.of(context).colorScheme.primary,
                        ),
                        label: const Text('Bluetooth'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _showUsbDevices
                              ? null
                              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        ),
                        onPressed: () {
                          setModalState(() {
                            _showUsbDevices = false;
                            _isScanning = true;
                            _availableDevices = [];
                          });
                          _scanForPrinters(() => setModalState(() {}));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.usb,
                          color: !_showUsbDevices ? null : Theme.of(context).colorScheme.primary,
                        ),
                        label: const Text('USB'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: !_showUsbDevices
                              ? null
                              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        ),
                        onPressed: () {
                          setModalState(() {
                            _showUsbDevices = true;
                            _isScanning = true;
                            _availableUsbDevices = [];
                          });
                          _scanForUsbPrinters(() => setModalState(() {}));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _showUsbDevices ? 'USB printers' : 'Bluetooth printers',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _isScanning
                          ? null
                          : () {
                              setModalState(() {
                                _isScanning = true;
                              });
                              if (_showUsbDevices) {
                                _scanForUsbPrinters(() => setModalState(() {}));
                              } else {
                                _scanForPrinters(() => setModalState(() {}));
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isScanning)
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _showUsbDevices
                              ? 'Scanning for USB printers...'
                              : 'Scanning for Bluetooth printers...',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showUsbDevices
                              ? 'Make sure the printer is connected via USB'
                              : 'This may take up to 15 seconds',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  )
                else if (_showUsbDevices)
                  _availableUsbDevices.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.usb_off, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No USB printers found'),
                              Text(
                                  'Connect a USB printer to your device and try again'),
                            ],
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _availableUsbDevices.length,
                            itemBuilder: (context, index) {
                              final device = _availableUsbDevices[index];
                              final isConnected = _connectedDevice != null &&
                                  _connectedDevice!.isUsb &&
                                  _connectedDevice!.addressOrId.contains(
                                      '${device.vendorId}:${device.productId}');
                              final name = device.productName.isNotEmpty
                                  ? device.productName
                                  : '${device.manufacturer} USB';

                              return ListTile(
                                leading: Icon(
                                  Icons.usb,
                                  color: isConnected ? Colors.green : Colors.blue,
                                ),
                                title: Text(name),
                                subtitle: Text(
                                    '${device.vendorId}:${device.productId}'),
                                trailing: isConnected
                                    ? const Icon(Icons.check, color: Colors.green)
                                    : const Icon(Icons.arrow_forward_ios,
                                        size: 16),
                                onTap: isConnected
                                    ? null
                                    : () => _connectToUsbPrinter(device),
                              );
                            },
                          ),
                        )
                else if (_availableDevices.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bluetooth_disabled,
                              size: 48, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          Text(
                            'No Bluetooth printers found',
                            style: Theme.of(context).textTheme.titleSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enable "Nearby devices" and "Location" in Settings to scan, or ensure your printer is on and discoverable.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            icon: const Icon(Icons.settings, size: 20),
                            label: const Text('Open app Settings'),
                            onPressed: () =>
                                _printerService.openAppSettings(),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availableDevices.length,
                      itemBuilder: (context, index) {
                        final device = _availableDevices[index];
                        final isConnected = _connectedDevice != null &&
                            !_connectedDevice!.isUsb &&
                            _connectedDevice!.addressOrId == device.macAdress;

                        return ListTile(
                          leading: Icon(
                            isConnected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth,
                            color: isConnected ? Colors.green : Colors.blue,
                          ),
                          title: Text(device.name),
                          subtitle: Text(device.macAdress),
                          trailing: isConnected
                              ? const Icon(Icons.check, color: Colors.green)
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: isConnected
                              ? null
                              : () => _connectToBluetoothPrinter(device),
                        );
                      },
                    ),
                  ),
                if (_connectedDevice != null) ...[
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      _connectedDevice!.isUsb ? Icons.usb_off : Icons.bluetooth_disabled,
                      color: Colors.red,
                    ),
                    title: const Text('Disconnect Current Printer'),
                    subtitle:
                        Text('Currently connected to ${_connectedDevice!.name}'),
                    onTap: () {
                      _disconnectPrinter();
                      setState(() {
                        _connectedDevice = null;
                      });
                      refreshModal();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _testPrint() async {
    if (_connectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect to a printer first'),
          backgroundColor: AppTheme.warningTextStrong,
        ),
      );
      return;
    }

    try {
      // Test: 2 name tags + 1 pickup slip with QR code
      final success = await _printerService.printGuardianCheckInSticker(
        childIds: ['test-001', 'test-002'],
        children: ['Juan Dela Cruz Jr.', 'Maria Dela Cruz'],
        pickupCodes: ['ABC123', 'XYZ789'],
        ageGroups: ['Jr. Kids', 'Toddlers'],
        specialNotes: ['Peanut allergy · EpiPen in bag', null],
        guardianQrCode: 'GUARDIAN-001',
        guardianName: 'Test Guardian',
        serviceName: 'Sunday Service',
        checkInTime: DateTime.now(),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test print sent to printer successfully'),
            backgroundColor: AppTheme.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test print failed'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test print error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: child,
    );
  }
}

class _SettingsGapBanner extends StatelessWidget {
  const _SettingsGapBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        border: Border.all(color: AppTheme.warningBorder, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF6E3B8),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: const Text(
              'GAP §8',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppTheme.warningText,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Clear Cache, Export Data, Privacy and Terms are stubs today, and RFID is disabled at the service layer — all four are left out of this design until they do something. Demo credentials are gone from Login.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF6B5220), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
