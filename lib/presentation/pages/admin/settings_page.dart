import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/services/printer_service.dart';
import '../../../domain/entities/child.dart';
import '../../../domain/entities/checkin_session.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  late PrinterService _printerService;
  bool _isScanning = false;
  List<dynamic> _availableDevices = [];
  dynamic _connectedDevice;

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
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect printer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scanForPrinters() async {
    setState(() {
      _isScanning = true;
    });

    try {
      // Use the timeout wrapper to prevent hanging
      final devices = await _printerService.getAvailableDevicesWithTimeout();
      setState(() {
        _availableDevices = devices;
        _isScanning = false;
      });

      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No printers found. Make sure Bluetooth is enabled and printers are discoverable.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to scan for printers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Ensure scanning state is reset even if there's an error
    if (_isScanning) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _connectToPrinter(dynamic device) async {
    try {
      final success = await _printerService.connect(device);
      if (success) {
        setState(() {
          _connectedDevice = device;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Connected to ${device.name ?? 'Unknown'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to ${device.name ?? 'Unknown'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to printer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User Info Section
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                if (user == null) return const SizedBox.shrink();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Information',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              radius: 30,
                              child: Text(
                                user.firstName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    user.email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user.role.toUpperCase(),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // App Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Notifications'),
                      subtitle: const Text('Receive app notifications'),
                      value: notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          notificationsEnabled = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Printer Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Printer Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Connected Printer'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_connectedDevice != null
                              ? '${_connectedDevice!.name} (${_connectedDevice!.macAdress})'
                              : 'No printer connected'),
                          if (_connectedDevice != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Text(
                                'CONNECTED',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_connectedDevice != null)
                            IconButton(
                              icon: const Icon(Icons.bluetooth_disabled,
                                  color: Colors.red),
                              onPressed: _disconnectPrinter,
                              tooltip: 'Disconnect',
                            ),
                          IconButton(
                            icon: Icon(
                                _isScanning ? Icons.refresh : Icons.refresh,
                                color: _isScanning ? Colors.grey : Colors.blue),
                            onPressed: _isScanning ? null : _scanForPrinters,
                            tooltip: 'Scan for printers',
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.refresh, color: Colors.green),
                            onPressed: _refreshPrinterStatus,
                            tooltip: 'Refresh printer status',
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: _showPrinterSelection,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Test Print'),
                      subtitle: const Text('Print a test sticker'),
                      trailing: const Icon(Icons.print),
                      onTap: _testPrint,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Clear Saved Connection'),
                      subtitle: const Text('Remove saved printer connection'),
                      trailing: const Icon(Icons.clear, color: Colors.orange),
                      onTap: _clearSavedConnection,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Data Management
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Management',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Clear Cache'),
                      subtitle: const Text('Clear locally cached data'),
                      trailing: const Icon(Icons.clear_all),
                      onTap: _clearCache,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Export Data'),
                      subtitle: const Text('Export attendance data'),
                      trailing: const Icon(Icons.download),
                      onTap: _exportData,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // About
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const ListTile(
                      title: Text('App Version'),
                      subtitle: Text('1.0.0'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    ListTile(
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                      contentPadding: EdgeInsets.zero,
                    ),
                    ListTile(
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrinterSelection() {
    // First scan for available printers
    _scanForPrinters();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Printer',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: Icon(_isScanning ? Icons.refresh : Icons.refresh),
                  onPressed: _isScanning ? null : _scanForPrinters,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isScanning)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Scanning for Bluetooth printers...'),
                    const SizedBox(height: 8),
                    Text(
                      'This may take up to 15 seconds',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isScanning = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel Scan'),
                    ),
                  ],
                ),
              )
            else if (_availableDevices.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.bluetooth_disabled,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No Bluetooth printers found'),
                    Text(
                        'Make sure your printer is turned on and discoverable'),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _availableDevices.length,
                  itemBuilder: (context, index) {
                    final device = _availableDevices[index];
                    final isConnected =
                        _connectedDevice?.macAdress == device.macAdress;

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
                      onTap:
                          isConnected ? null : () => _connectToPrinter(device),
                    );
                  },
                ),
              ),
            if (_connectedDevice != null) ...[
              const Divider(),
              ListTile(
                leading:
                    const Icon(Icons.bluetooth_disabled, color: Colors.red),
                title: const Text('Disconnect Current Printer'),
                subtitle:
                    Text('Currently connected to ${_connectedDevice!.name}'),
                onTap: () {
                  _disconnectPrinter();
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _testPrint() async {
    if (_connectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect to a printer first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Create a mock child and session for testing
      final mockChild = Child(
        id: 'test-001',
        fullName: 'Test Child',
        dateOfBirth: DateTime(2020, 1, 1),
        gender: 'Unknown',
        ageGroup: 'Preschool',
        guardianIds: const ['guardian-001'],
        qrCode: 'test-qr-001',
        rfidTag: 'test-rfid-001',
        isActive: true,
        currentlyCheckedIn: false,
        createdBy: 'system',
        updatedBy: 'system',
      );

      final mockSession = CheckInSession(
        id: 'session-001',
        serviceSessionId: 'Sunday Service',
        date: DateTime.now(),
        createdBy: 'system',
        checkedInChildren: const ['test-001'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // For testing, we'll use the guardian check-in sticker method
      final success = await _printerService.printGuardianCheckInSticker(
        childIds: [mockChild.id],
        children: [mockChild.fullName],
        pickupCodes: ['TEST123'],
        guardianQrCode: 'GUARDIAN-001',
        serviceName: mockSession.serviceSessionId,
        checkInTime: DateTime.now(),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test print sent to printer successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test print failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test print error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'This will clear all locally cached data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export started'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _clearSavedConnection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Saved Connection'),
        content: const Text(
            'This will remove the saved printer connection. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _printerService.clearSavedConnection();
              setState(() {
                _connectedDevice = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saved printer connection cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
