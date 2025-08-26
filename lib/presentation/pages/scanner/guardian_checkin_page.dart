import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/services_provider.dart';
import '../../widgets/child_selection_card.dart';
import '../../../domain/entities/guardian.dart';
import '../../../domain/entities/child.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../../domain/entities/service_session.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/printer_service.dart';
import '../../../data/models/guardian_model.dart';
import '../../../data/models/child_model.dart';

class GuardianCheckinPage extends StatefulWidget {
  const GuardianCheckinPage({super.key});

  @override
  State<GuardianCheckinPage> createState() => _GuardianCheckinPageState();
}

class _GuardianCheckinPageState extends State<GuardianCheckinPage> {
  Guardian? _scannedGuardian;
  List<Child> _linkedChildren = [];
  List<String> _selectedChildIds = [];
  bool _isLoading = false;
  bool _isScanning = false;
  bool _isPrinting = false;
  String? _error;
  String? _successMessage;
  String? _selectedServiceId;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      await context.read<ServicesProvider>().loadServices();
    } catch (e) {
      _setError('Failed to load services: $e');
    }
  }

  Future<void> _scanGuardianQR() async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      // Navigate to QR scanner
      final result = await context.push<String>(
        AppRouter.qrScanner,
        extra: {
          'title': 'Scan Guardian QR Code',
          'onScanComplete': (String qrCode) async {
            await _processGuardianQR(qrCode);
          },
        },
      );

      if (result != null) {
        await _processGuardianQR(result);
      }
    } catch (e) {
      _setError('QR scanning failed: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _scanGuardianRFID() async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      // For now, show a dialog to enter RFID manually
      // In production, this would use NFC scanning
      final rfidCode = await _showRFIDInputDialog();
      if (rfidCode != null) {
        await _processGuardianRFID(rfidCode);
      }
    } catch (e) {
      _setError('RFID scanning failed: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<String?> _showRFIDInputDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter RFID Code'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'RFID Code',
            hintText: 'Enter the RFID code from the guardian\'s tag',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _processGuardianQR(String qrCode) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Comprehensive logging of QR code data
      print('🔍 ===== QR CODE SCANNED =====');
      print('📱 Raw QR Data: "$qrCode"');
      print('📊 Data Length: ${qrCode.length} characters');
      print('📋 Data Type: ${_detectQRCodeType(qrCode)}');
      print('🔤 Contains Letters: ${RegExp(r'[a-zA-Z]').hasMatch(qrCode)}');
      print('🔢 Contains Numbers: ${RegExp(r'[0-9]').hasMatch(qrCode)}');
      print(
          '🔤 Contains Special Chars: ${RegExp(r'[^a-zA-Z0-9]').hasMatch(qrCode)}');
      print(
          '🌐 Is URL: ${qrCode.startsWith('http://') || qrCode.startsWith('https://')}');
      print('📧 Is Email: ${qrCode.contains('@') && qrCode.contains('.')}');
      print('📞 Is Phone: ${qrCode.startsWith('tel:')}');
      print('🖼️ Is Image Data: ${qrCode.startsWith('data:image/')}');
      print(
          '🔑 Is Guardian ID: ${qrCode.startsWith('G') && qrCode.length > 10}');
      print(
          '🗄️ Is MongoDB ID: ${qrCode.length == 24 && RegExp(r'^[a-fA-F0-9]+$').hasMatch(qrCode)}');
      print(
          '📝 First 10 chars: "${qrCode.length > 10 ? '${qrCode.substring(0, 10)}...' : qrCode}"');
      print(
          '📝 Last 10 chars: "${qrCode.length > 10 ? '...${qrCode.substring(qrCode.length - 10)}' : qrCode}"');
      print('🔍 ===========================');

      final checkinProvider = context.read<CheckinProvider>();
      print('🔍 Searching for guardian with QR code...');

      // Check if QR code is a MongoDB ObjectId (guardian _id)
      if (qrCode.length == 24 && RegExp(r'^[a-fA-F0-9]+$').hasMatch(qrCode)) {
        print(
            '🔍 QR code appears to be a MongoDB ObjectId - searching for guardian by ID...');
        // Search for guardian by ID directly
        final guardian = await checkinProvider.getGuardianById(qrCode);

        if (guardian != null) {
          print(
              '✅ Guardian found by ID: ${guardian.fullName} (ID: ${guardian.id})');
          print(
              '📱 Guardian details: ${guardian.contactNumber}, ${guardian.email}');
          print('👥 Linked children count: ${guardian.linkedChildren.length}');

          await _fetchGuardianWithChildren(qrCode);
        } else {
          print('❌ Guardian not found with ID: "$qrCode"');
          _setError('Guardian not found with this ID');
        }
      } else {
        final guardian = await checkinProvider.getGuardianByQrCode(qrCode);

        if (guardian != null) {
          print('✅ Guardian found: ${guardian.fullName} (ID: ${guardian.id})');
          print(
              '📱 Guardian details: ${guardian.contactNumber}, ${guardian.email}');
          print('👥 Linked children count: ${guardian.linkedChildren.length}');

          await _fetchGuardianWithChildren(guardian.id);
        } else {
          print('❌ Guardian not found with QR code: "$qrCode"');
          _setError('Guardian not found with this QR code');
        }
      }
    } catch (e) {
      print('💥 Error processing guardian QR code: $e');
      _setError('Failed to process guardian QR code: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processGuardianRFID(String rfidCode) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final checkinProvider = context.read<CheckinProvider>();
      final guardian = await checkinProvider.getGuardianByRfidTag(rfidCode);

      if (guardian != null) {
        await _fetchGuardianWithChildren(guardian.id);
      } else {
        _setError('Guardian not found with this RFID code');
      }
    } catch (e) {
      _setError('Failed to process guardian RFID code: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchGuardianWithChildren(String guardianId) async {
    try {
      final checkinProvider = context.read<CheckinProvider>();
      final result = await checkinProvider.getGuardianWithChildren(guardianId);

      if (result != null) {
        try {
          // Parse guardian data using GuardianModel
          final guardianData = result['guardian'] as Map<String, dynamic>;
          final guardianModel = GuardianModel.fromJson(guardianData);
          final guardian = guardianModel.toEntity();

          // Parse children data using ChildModel
          final childrenData = result['children'] as List<dynamic>;
          final children = childrenData.map((childJson) {
            final childModel =
                ChildModel.fromJson(childJson as Map<String, dynamic>);
            return childModel.toEntity();
          }).toList();

          setState(() {
            _scannedGuardian = guardian;
            _linkedChildren = children;
            _selectedChildIds = [];
            _error = null;
          });

          print('✅ Guardian and children parsed successfully');
          print('👤 Guardian: ${guardian.fullName}');
          print('👶 Children: ${children.length} children loaded');
        } catch (parseError) {
          print('💥 Error parsing guardian/children data: $parseError');
          _setError('Failed to parse guardian information: $parseError');
        }
      } else {
        _setError('Failed to fetch guardian information');
      }
    } catch (e) {
      _setError('Failed to fetch guardian information: $e');
    }
  }

  void _toggleChildSelection(String childId) {
    setState(() {
      if (_selectedChildIds.contains(childId)) {
        _selectedChildIds.remove(childId);
      } else {
        _selectedChildIds.add(childId);
      }
    });
  }

  Future<void> _checkInSelectedChildren() async {
    if (_selectedChildIds.isEmpty) {
      _setError('Please select at least one child to check in');
      return;
    }

    if (_selectedServiceId == null) {
      _setError('Please select a service');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final checkinProvider = context.read<CheckinProvider>();
      final attendanceRecords = await checkinProvider.checkInChildren(
        guardianId: _scannedGuardian!.id,
        serviceId: _selectedServiceId!,
        childIds: _selectedChildIds,
      );

      // Create a detailed success message with pickup codes
      final pickupCodes =
          attendanceRecords.map((record) => record.pickupCode).join(', ');
      final childNames = attendanceRecords.map((record) {
        final child = _linkedChildren.firstWhere(
          (c) => c.id == record.childId,
          orElse: () => Child(
            id: record.childId,
            fullName: 'Unknown Child',
            dateOfBirth: DateTime.now(),
            gender: 'unknown',
            ageGroup: 'unknown',
            guardianIds: const [],
            isActive: true,
            currentlyCheckedIn: false,
          ),
        );
        return '${child.firstName} ${child.lastName}';
      }).join(', ');

      setState(() {
        _successMessage =
            '✅ Successfully checked in ${attendanceRecords.length} child(ren)\n'
            '👶 Children: $childNames\n'
            '🎫 Pickup Codes: $pickupCodes';
        _selectedChildIds = [];
      });

      // Print stickers for each child
      await _printStickers(attendanceRecords);

      // Clear the form after successful check-in
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _scannedGuardian = null;
            _linkedChildren = [];
            _successMessage = null;
          });
        }
      });
    } catch (e) {
      _setError('Check-in failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _printStickers(List<AttendanceRecord> records) async {
    print('��️ Starting to print sticker for ${records.length} children');

    setState(() {
      _isPrinting = true;
    });

    try {
      // Get the printer service
      final printerService = context.read<PrinterService>();

      // Check if printer is connected
      if (!printerService.isConnected) {
        print('⚠️ Printer not connected. Checking for saved connection...');

        // Check if there's a saved printer connection first
        final savedDevice = printerService.connectedDevice;
        if (savedDevice != null) {
          print(
              '🔄 Found saved printer: ${savedDevice.name}. Attempting to reconnect...');
          final connected = await printerService.connect(savedDevice);
          if (connected) {
            print(
                '✅ Successfully reconnected to saved printer: ${savedDevice.name}');
          } else {
            print(
                '❌ Failed to reconnect to saved printer: ${savedDevice.name}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '⚠️ Failed to reconnect to saved printer: ${savedDevice.name}. Please check printer connection in Settings.'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
            return;
          }
        } else {
          print('❌ No saved printer connection found');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '⚠️ No printer connected. Please connect a printer in Settings first.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      // Get service name
      final servicesProvider = context.read<ServicesProvider>();
      final service = servicesProvider.services.firstWhere(
        (s) => s.id == records.first.serviceId,
        orElse: () => ServiceSession(
          id: records.first.serviceId,
          name: 'Unknown Service',
          startTime: '00:00',
          endTime: '00:00',
          dayOfWeek: 'unknown',
          description: '',
          ageGroups: const [],
          maxCapacity: 0,
          isActive: true,
          createdBy: 'system',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Prepare data for printing
      final childrenNames = records.map((record) {
        final child = _linkedChildren.firstWhere(
          (c) => c.id == record.childId,
          orElse: () => Child(
            id: record.childId,
            fullName: 'Unknown Child',
            dateOfBirth: DateTime.now(),
            gender: 'unknown',
            ageGroup: 'unknown',
            guardianIds: const [],
            isActive: true,
            currentlyCheckedIn: false,
          ),
        );
        return '${child.firstName} ${child.lastName}';
      }).toList();

      final pickupCodes = records.map((record) => record.pickupCode).toList();

      print('🎫 Printing sticker for ${childrenNames.length} children...');
      print('   👶 Children: ${childrenNames.join(', ')}');
      print('   📍 Pickup Codes: ${pickupCodes.join(', ')}');
      print('   👤 Guardian: ${_scannedGuardian?.fullName}');
      print('   ⛪ Service: ${service.name}');
      print('   🕐 Check-in Time: ${records.first.checkInTime}');

      // Print the single sticker with all children
      final success = await printerService.printGuardianCheckInSticker(
        children: childrenNames,
        pickupCodes: pickupCodes,
        guardianQrCode: _scannedGuardian?.id ?? 'Unknown',
        serviceName: service.name,
        checkInTime: records.first.checkInTime,
      );

      if (success) {
        print('✅ Sticker printed successfully for all children');
      } else {
        print('❌ Failed to print sticker');
      }

      print('🎉 Sticker printing completed!');

      // Show success message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Successfully printed sticker for ${records.length} child(ren)!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('💥 Error printing sticker: $e');
      // Show error to user but don't fail the check-in process
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Sticker printing failed: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  void _setError(String error) {
    setState(() {
      _error = error;
      _successMessage = null;
    });
  }

  void _clearError() {
    setState(() {
      _error = null;
    });
  }

  void _resetForm() {
    setState(() {
      _scannedGuardian = null;
      _linkedChildren = [];
      _selectedChildIds = [];
      _selectedServiceId = null;
      _error = null;
      _successMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final servicesProvider = context.watch<ServicesProvider>();
    final services = servicesProvider.services;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Check-In'),
        actions: [
          if (_scannedGuardian != null)
            IconButton(
              onPressed: _resetForm,
              icon: const Icon(Icons.refresh),
              tooltip: 'Start Over',
            ),
        ],
      ),
      body: _buildBody(services),
    );
  }

  Widget _buildBody(List services) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_scannedGuardian == null) {
      return _buildScanSection();
    }

    return _buildGuardianInfoSection();
  }

  Widget _buildScanSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Guardian Check-In',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan the guardian\'s QR code or RFID tag to begin the check-in process',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanGuardianQR,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR Code'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanGuardianRFID,
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Scan RFID'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  IconButton(
                    onPressed: _clearError,
                    icon: const Icon(Icons.close),
                    color: Colors.red[700],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuardianInfoSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Guardian Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          _scannedGuardian!.firstName[0] +
                              _scannedGuardian!.lastName[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _scannedGuardian!.fullName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              _scannedGuardian!.relationship,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              _scannedGuardian!.contactNumber,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Service Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Service',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedServiceId,
                    decoration: const InputDecoration(
                      labelText: 'Service',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Select a service...'),
                      ),
                      ...context
                          .watch<ServicesProvider>()
                          .services
                          .map((service) {
                        return DropdownMenuItem(
                          value: service.id,
                          child: Text(service.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedServiceId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Children Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Children to Check In',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_selectedChildIds.length}/${_linkedChildren.length} selected',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_linkedChildren.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No children linked to this guardian',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    ..._linkedChildren.map((child) => ChildSelectionCard(
                          child: child,
                          isSelected: _selectedChildIds.contains(child.id),
                          onSelectionChanged: () =>
                              _toggleChildSelection(child.id),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Check-in Button
          ElevatedButton(
            onPressed:
                _selectedChildIds.isNotEmpty && _selectedServiceId != null
                    ? _checkInSelectedChildren
                    : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Check In ${_selectedChildIds.length} Child(ren)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          if (_successMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),

            // Printing status indicator
            if (_isPrinting) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '🖨️ Printing stickers... Please wait',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  IconButton(
                    onPressed: _clearError,
                    icon: const Icon(Icons.close),
                    color: Colors.red[700],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods to detect QR/RFID code types
  String _detectQRCodeType(String code) {
    if (code.startsWith('http://') || code.startsWith('https://')) {
      return 'URL';
    } else if (code.startsWith('data:image/')) {
      return 'Image Data';
    } else if (code.contains('@') &&
        code.contains('.') &&
        !code.startsWith('http://') &&
        !code.startsWith('https://')) {
      return 'Email';
    } else if (code.startsWith('tel:')) {
      return 'Phone Number';
    } else if (code.startsWith('G') && code.length > 10) {
      return 'Guardian ID (likely)';
    } else if (code.length == 24 && RegExp(r'^[a-fA-F0-9]+$').hasMatch(code)) {
      return 'MongoDB ObjectId (likely)';
    } else if (code.length > 20) {
      return 'Long Text/Data';
    } else {
      return 'Short Text/Code';
    }
  }

  String _detectRFIDCodeType(String code) {
    if (code.startsWith('RFID')) {
      return 'RFID Tag Format';
    } else if (code.length == 8 &&
        RegExp(r'^[0-9A-F]+$', caseSensitive: false).hasMatch(code)) {
      return '8-digit Hex RFID';
    } else if (code.length == 10 && RegExp(r'^[0-9]+$').hasMatch(code)) {
      return '10-digit Numeric RFID';
    } else if (code.length == 12 && RegExp(r'^[0-9]+$').hasMatch(code)) {
      return '12-digit Numeric RFID';
    } else if (RegExp(r'^[0-9A-F]+$', caseSensitive: false).hasMatch(code)) {
      return 'Hex RFID';
    } else if (RegExp(r'^[0-9]+$').hasMatch(code)) {
      return 'Numeric RFID';
    } else {
      return 'Custom Format';
    }
  }
}
