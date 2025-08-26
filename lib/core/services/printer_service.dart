import 'dart:async';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../domain/entities/child.dart';
import '../../domain/entities/checkin_session.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:image/image.dart' as img;

class PrinterService {
  bool _isConnected = false;
  BluetoothInfo? _connectedDevice;
  BluetoothDevice? _connectedBleDevice;
  static const String _printerNameKey = 'connected_printer_name';
  static const String _printerAddressKey = 'connected_printer_address';

  bool get isConnected => _isConnected;
  BluetoothInfo? get connectedDevice => _connectedDevice;

  /// Initialize the printer service and restore saved connection
  Future<void> initialize() async {
    try {
      await _restoreSavedConnection();
    } catch (e) {
      print('⚠️ Could not restore saved printer connection: $e');
    }
  }

  /// Save printer connection information to persistent storage
  Future<void> _savePrinterConnection(BluetoothInfo device) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_printerNameKey, device.name ?? 'Unknown');
      await prefs.setString(_printerAddressKey, device.macAdress ?? '');
      print(
          '💾 Saved printer connection: ${device.name} (${device.macAdress})');
    } catch (e) {
      print('❌ Failed to save printer connection: $e');
    }
  }

  /// Restore printer connection from persistent storage
  Future<void> _restoreSavedConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_printerNameKey);
      final savedAddress = prefs.getString(_printerAddressKey);

      if (savedName != null &&
          savedAddress != null &&
          savedAddress.isNotEmpty) {
        print(
            '🔄 Restoring saved printer connection: $savedName ($savedAddress)');

        // Create a BluetoothInfo object from saved data
        final savedDevice = BluetoothInfo(
          name: savedName,
          macAdress: savedAddress,
        );

        // Try to reconnect to the saved printer
        final success = await connect(savedDevice);
        if (success) {
          print('✅ Successfully restored connection to saved printer');
        } else {
          print(
              '⚠️ Could not restore connection to saved printer, clearing saved data');
          await _clearSavedConnection();
        }
      }
    } catch (e) {
      print('❌ Error restoring saved printer connection: $e');
      await _clearSavedConnection();
    }
  }

  /// Clear saved printer connection information
  Future<void> _clearSavedConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_printerNameKey);
      await prefs.remove(_printerAddressKey);
      print('🗑️ Cleared saved printer connection');
    } catch (e) {
      print('❌ Failed to clear saved printer connection: $e');
    }
  }

  /// Public method to clear saved printer connection
  Future<void> clearSavedConnection() async {
    await _clearSavedConnection();
    _isConnected = false;
    _connectedDevice = null;
    _connectedBleDevice = null;
    print('🗑️ Public clear saved connection completed');
  }

  /// Open app settings to allow user to manually enable permissions
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
      print('🔧 Opened app settings');
    } catch (e) {
      print('❌ Could not open app settings: $e');
    }
  }

  /// Check if permissions are granted without requesting them
  Future<Map<String, bool>> checkPermissionStatus() async {
    final bluetoothStatus = await Permission.bluetooth.status;
    final bluetoothScanStatus = await Permission.bluetoothScan.status;
    final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
    final locationStatus = await Permission.location.status;

    return {
      'bluetooth': bluetoothStatus == PermissionStatus.granted,
      'bluetoothScan': bluetoothScanStatus == PermissionStatus.granted,
      'bluetoothConnect': bluetoothConnectStatus == PermissionStatus.granted,
      'location': locationStatus == PermissionStatus.granted,
    };
  }

  /// Get a user-friendly message about what permissions are needed
  String getPermissionHelpMessage() {
    return '''
🔐 Bluetooth Permissions Required

To scan for Bluetooth printers, the app needs these permissions:

📱 Nearby Devices (Bluetooth)
   - Allows the app to discover Bluetooth devices
   - Required for finding available printers

📍 Location
   - Required by Android for Bluetooth scanning
   - The app does NOT access your location data

💡 How to Enable:
1. Go to Settings > Apps > Kids Church Check-in
2. Tap "Permissions"
3. Enable "Nearby devices" and "Location"
4. Return to the app and try scanning again

If permissions are still denied, you may need to:
- Restart the app after granting permissions
- Check if your device has any additional security settings
- Ensure Bluetooth is enabled on your device
''';
  }

  /// Check and request necessary permissions for Bluetooth scanning
  Future<bool> _ensurePermissions() async {
    try {
      print('🔐 Starting permission check...');

      // Check and request Bluetooth permissions for modern Android
      final bluetoothStatus = await Permission.bluetooth.status;
      final bluetoothScanStatus = await Permission.bluetoothScan.status;
      final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
      final locationStatus = await Permission.location.status;

      print('🔐 Current permission status:');
      print('   Bluetooth: $bluetoothStatus');
      print('   BluetoothScan: $bluetoothScanStatus');
      print('   BluetoothConnect: $bluetoothConnectStatus');
      print('   Location: $locationStatus');

      // Request Bluetooth permissions if not granted
      if (bluetoothStatus != PermissionStatus.granted) {
        print('🔐 Requesting Bluetooth permission...');
        final result = await Permission.bluetooth.request();
        if (result != PermissionStatus.granted) {
          print('❌ Bluetooth permission denied');
          print(
              '💡 Please enable "Nearby devices" permission in Settings > Apps > Kids Church Check-in > Permissions');
          return false;
        }
      }

      // Request Bluetooth Scan permission if not granted (Android 12+)
      if (bluetoothScanStatus != PermissionStatus.granted) {
        print('🔐 Requesting Bluetooth Scan permission...');
        final result = await Permission.bluetoothScan.request();
        if (result != PermissionStatus.granted) {
          print('❌ Bluetooth Scan permission denied');
          print(
              '💡 Please enable "Nearby devices" permission in Settings > Apps > Kids Church Check-in > Permissions');
          return false;
        }
      }

      // Request Bluetooth Connect permission if not granted (Android 12+)
      if (bluetoothConnectStatus != PermissionStatus.granted) {
        print('🔐 Requesting Bluetooth Connect permission...');
        final result = await Permission.bluetoothConnect.request();
        if (result != PermissionStatus.granted) {
          print('❌ Bluetooth Connect permission denied');
          print(
              '💡 Please enable "Nearby devices" permission in Settings > Apps > Kids Church Check-in > Permissions');
          return false;
        }
      }

      // Check location permission (required for Bluetooth scanning on Android)
      if (locationStatus != PermissionStatus.granted) {
        print('🔐 Requesting Location permission...');
        final result = await Permission.location.request();
        if (result != PermissionStatus.granted) {
          print(
              '❌ Location permission denied (required for Bluetooth scanning)');
          print(
              '💡 Please enable "Location" permission in Settings > Apps > Kids Church Check-in > Permissions');
          return false;
        }
      }

      // Final check - verify all permissions are actually granted
      final finalBluetoothStatus = await Permission.bluetooth.status;
      final finalBluetoothScanStatus = await Permission.bluetoothScan.status;
      final finalBluetoothConnectStatus =
          await Permission.bluetoothConnect.status;
      final finalLocationStatus = await Permission.location.status;

      if (finalBluetoothStatus != PermissionStatus.granted ||
          finalBluetoothScanStatus != PermissionStatus.granted ||
          finalBluetoothConnectStatus != PermissionStatus.granted ||
          finalLocationStatus != PermissionStatus.granted) {
        print('❌ Some permissions are still not granted after request');
        print(
            '💡 Please manually enable permissions in Settings > Apps > Kids Church Check-in > Permissions');
        print('   Required permissions:');
        print('   - Nearby devices (Bluetooth)');
        print('   - Location');
        return false;
      }

      print('✅ All required permissions granted');
      return true;
    } catch (e) {
      print('❌ Error checking permissions: $e');
      print(
          '💡 Please check app permissions manually in Settings > Apps > Kids Church Check-in > Permissions');
      return false;
    }
  }

  /// Get available Bluetooth devices using real Bluetooth scanning
  Future<List<BluetoothInfo>> getAvailableDevices() async {
    try {
      print('🔍 Starting Bluetooth device scan...');

      // First, get paired devices from print_bluetooth_thermal (this should always work)
      List<BluetoothInfo> pairedDevices = [];
      try {
        pairedDevices = await PrintBluetoothThermal.pairedBluetooths;
        print('🔍 Found ${pairedDevices.length} paired Bluetooth devices');
      } catch (e) {
        print('⚠️ Could not get paired devices: $e');
        pairedDevices = [];
      }

      // Try to scan for available BLE devices using flutter_blue_plus
      final List<BluetoothInfo> availableDevices = [];
      bool bleScanSuccessful = false;
      String? permissionError;

      try {
        // Ensure permissions are granted
        final permissionsGranted = await _ensurePermissions();

        if (permissionsGranted) {
          print('🔐 Permissions granted, attempting BLE scan...');

          // Start BLE scan
          print('🔍 Starting BLE scan...');

          final List<BluetoothDevice> discoveredDevices = [];

          // Listen to scan results
          final subscription = FlutterBluePlus.scanResults.listen((results) {
            for (final result in results) {
              if (!discoveredDevices
                  .any((d) => d.remoteId == result.device.remoteId)) {
                discoveredDevices.add(result.device);
                print(
                    '🔍 Found BLE device: ${result.device.platformName} (${result.device.remoteId})');
              }
            }
          });

          // Start the scan
          await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));

          // Wait for scan to complete
          await Future.delayed(const Duration(seconds: 10));

          // Cancel the subscription and stop scanning
          await subscription.cancel();
          await FlutterBluePlus.stopScan();

          print('🔍 Found ${discoveredDevices.length} discovered BLE devices');

          // Convert discovered devices to BluetoothInfo format
          for (final device in discoveredDevices) {
            final name = device.platformName.isNotEmpty
                ? device.platformName
                : device.remoteId.toString();

            final bluetoothInfo = BluetoothInfo(
              name: name,
              macAdress: device.remoteId.toString(),
            );

            // Avoid duplicates
            if (!availableDevices
                .any((d) => d.macAdress == bluetoothInfo.macAdress)) {
              availableDevices.add(bluetoothInfo);
              print('🔍 Added available device: $name (${device.remoteId})');
            }
          }

          bleScanSuccessful = true;
          print('✅ BLE scan completed successfully');
        } else {
          print('⚠️ Permissions not granted, skipping BLE scan');
          permissionError =
              'Bluetooth permissions not granted. Please enable "Nearby devices" and "Location" permissions in app settings.';
        }
      } catch (e) {
        print('⚠️ BLE scan failed: $e');
        bleScanSuccessful = false;
        permissionError = 'Bluetooth scanning failed: $e';
      }

      // Combine paired and available devices, removing duplicates
      final allDevices = <BluetoothInfo>[];
      final seenAddresses = <String>{};

      // Add paired devices first
      for (final device in pairedDevices) {
        if (device.macAdress.isNotEmpty) {
          allDevices.add(device);
          seenAddresses.add(device.macAdress);
        }
      }

      // Add available devices that aren't already paired
      for (final device in availableDevices) {
        if (device.macAdress.isNotEmpty &&
            !seenAddresses.contains(device.macAdress)) {
          allDevices.add(device);
          seenAddresses.add(device.macAdress);
        }
      }

      print('🖨️ Total devices found: ${allDevices.length}');
      print('   📍 Paired devices: ${pairedDevices.length}');
      print('   📍 Available BLE devices: ${availableDevices.length}');
      print('   📍 BLE scan successful: $bleScanSuccessful');

      for (final device in allDevices) {
        print(
            '   📍 ${device.name ?? 'Unknown'} (${device.macAdress ?? 'No address'})');
      }

      // If we have permission errors, log them clearly
      if (permissionError != null) {
        print('⚠️ Permission/Scanning Issues:');
        print('   $permissionError');
        print('💡 Help: ${getPermissionHelpMessage()}');
      }

      return allDevices;
    } catch (e) {
      print('💥 Error scanning for devices: $e');
      // Fallback to just paired devices
      try {
        final List<BluetoothInfo> pairedDevices =
            await PrintBluetoothThermal.pairedBluetooths;
        print('🔄 Fallback: Found ${pairedDevices.length} paired devices');
        return pairedDevices;
      } catch (fallbackError) {
        print('💥 Fallback also failed: $fallbackError');
        return [];
      }
    }
  }

  /// Check if a device name suggests it's a printer
  bool _isPrinterDevice(String name) {
    if (name.isEmpty) return false;

    final lowerName = name.toLowerCase();
    return lowerName.contains('printer') ||
        lowerName.contains('thermal') ||
        lowerName.contains('zebra') ||
        lowerName.contains('brother') ||
        lowerName.contains('label') ||
        lowerName.contains('receipt') ||
        lowerName.contains('pos') ||
        lowerName.contains('bluetooth') ||
        lowerName.contains('bt') ||
        lowerName.contains('esc') ||
        lowerName.contains('pos');
  }

  /// Connect to a Bluetooth device
  Future<bool> connect(BluetoothInfo device) async {
    try {
      print(
          '🔗 Connecting to ${device.name ?? 'Unknown'} (${device.macAdress ?? 'No address'})...');

      // Try to connect using print_bluetooth_thermal first
      bool result = false;

      // Check if device is already paired by trying to connect
      try {
        result = await PrintBluetoothThermal.connect(
            macPrinterAddress: device.macAdress);
      } catch (e) {
        print('❌ print_bluetooth_thermal connection failed: $e');

        // If print_bluetooth_thermal fails, try BLE connection
        try {
          final bleDevice = BluetoothDevice.fromId(device.macAdress);
          await bleDevice.connect();
          _connectedBleDevice = bleDevice;
          result = true;
        } catch (bleError) {
          print('❌ BLE connection also failed: $bleError');
          result = false;
        }
      }

      if (result) {
        _isConnected = true;
        _connectedDevice = device;

        // Save the successful connection to persistent storage
        await _savePrinterConnection(device);

        print('✅ Connected to ${device.name ?? 'Unknown'}');
        return true;
      } else {
        print('❌ Failed to connect to ${device.name ?? 'Unknown'}');
        return false;
      }
    } catch (e) {
      print('❌ Failed to connect: $e');
      return false;
    }
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        print('🔌 Disconnecting from ${_connectedDevice!.name ?? 'Unknown'}');

        // Disconnect from BLE device if connected
        if (_connectedBleDevice != null) {
          await _connectedBleDevice!.disconnect();
          _connectedBleDevice = null;
        }

        // Disconnect from print_bluetooth_thermal
        await PrintBluetoothThermal.disconnect;

        _isConnected = false;
        _connectedDevice = null;

        // Clear the saved connection from persistent storage
        await _clearSavedConnection();

        print('✅ Disconnected successfully');
      }
    } catch (e) {
      print('❌ Error disconnecting: $e');
    }
  }

  /// Print check-in sticker
  Future<bool> printCheckInSticker({
    required Child child,
    required CheckInSession session,
  }) async {
    if (!_isConnected || _connectedDevice == null) {
      throw Exception('Printer not connected');
    }

    try {
      print('🖨️ Printing check-in sticker for ${child.fullName}...');

      // Create ESC/POS commands for the check-in sticker
      final commands = await _createCheckInStickerCommands(
        childName: child.fullName,
        childId: child.id,
        guardianId: child.primaryGuardianId ?? 'No guardian',
        pickupCode: session.pickupCode,
        serviceSession: session.serviceSession,
        checkinTime: session.checkinTime,
      );

      // Send the ESC/POS commands to the printer using print_bluetooth_thermal
      final result = await PrintBluetoothThermal.writeBytes(commands);

      if (result == true) {
        print('✅ Check-in sticker printed successfully');
        return true;
      } else {
        print('❌ Print failed with result: $result');
        return false;
      }
    } catch (e) {
      print('❌ Failed to print sticker: $e');
      throw Exception('Failed to print sticker: $e');
    }
  }

  /// Print guardian-based check-in sticker with pickup code, QR code, and child info
  Future<bool> printGuardianCheckInSticker({
    required List<String> childIds,
    required List<String> children,
    required List<String> pickupCodes,
    required String guardianQrCode,
    required String serviceName,
    required DateTime checkInTime,
  }) async {
    if (!_isConnected || _connectedDevice == null) {
      throw Exception('Printer not connected');
    }

    try {
      print('🖨️ Printing guardian check-in sticker for $children...');

      // Create ESC/POS commands for the guardian check-in sticker
      final commands = await _createGuardianCheckInStickerCommands(
        childIds: childIds,
        children: children,
        pickupCodes: pickupCodes,
        guardianQrCode: guardianQrCode,
        serviceName: serviceName,
        checkInTime: checkInTime,
      );

      // Send the ESC/POS commands to the printer using print_bluetooth_thermal
      final result = await PrintBluetoothThermal.writeBytes(commands);

      if (result == true) {
        print('✅ Guardian check-in sticker printed successfully');
        return true;
      } else {
        print('❌ Print failed with result: $result');
        return false;
      }
    } catch (e) {
      print('❌ Failed to print guardian check-in sticker: $e');
      throw Exception('Failed to print guardian check-in sticker: $e');
    }
  }

  /// Create ESC/POS commands for check-in sticker
  Future<List<int>> _createCheckInStickerCommands({
    required String childName,
    required String childId,
    required String guardianId,
    required String pickupCode,
    required String serviceSession,
    required DateTime checkinTime,
  }) async {
    // Simple text-based commands for thermal printer
    final commands = <int>[];

    // Initialize printer
    commands.addAll([27, 64]); // ESC @ - Initialize printer
    commands.addAll([27, 97, 1]); // ESC a 1 - Center alignment

    // Header
    commands.addAll([27, 33, 48]); // ESC ! 0 - Normal text size
    commands.addAll(_textToBytes('KIDS CHURCH CHECK-IN\n\n'));

    // Child information
    commands.addAll([27, 33, 16]); // ESC ! 16 - Bold text
    commands.addAll(_textToBytes('CHILD:\n'));
    commands.addAll([27, 33, 32]); // ESC ! 32 - Double height
    commands.addAll(_textToBytes('$childName\n\n'));

    // Pickup code (large and bold)
    commands.addAll([27, 33, 16]); // ESC ! 16 - Bold text
    commands.addAll(_textToBytes('PICKUP CODE:\n'));
    commands.addAll([27, 33, 48]); // ESC ! 48 - Double height and width
    commands.addAll(_textToBytes('$pickupCode\n\n'));

    // QR Code image (guardianId|pickupCode)
    commands.addAll([27, 33, 0]); // ESC ! 0 - Normal text
    commands.addAll(_textToBytes('QR CODE:\n'));

    // Add spacing and center the QR code
    commands.addAll([27, 97, 1]); // ESC a 1 - Center alignment
    commands.addAll(_textToBytes('\n')); // Extra spacing

    // Add QR code bitmap commands
    final qrData = '$guardianId|$pickupCode';
    final qrImage = await _generateQRCodeImage(qrData, size: 256);
    final qrCommands = await _imageToEscPosCommands(qrImage);
    commands.addAll(qrCommands);

    // Reset alignment and add spacing after QR code
    commands.addAll([27, 97, 0]); // ESC a 0 - Left alignment
    commands.addAll(_textToBytes('\n\n'));

    // Service and time
    commands.addAll([27, 33, 0]); // ESC ! 0 - Normal text
    commands.addAll(_textToBytes('SERVICE: $serviceSession\n'));
    commands.addAll(_textToBytes('TIME: ${_formatTime(checkinTime)}\n\n'));

    // Footer
    commands
        .addAll(_textToBytes('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n'));

    // Cut paper
    commands.addAll([29, 86, 66, 0]); // GS V B 0 - Full cut

    return commands;
  }

  /// Create ESC/POS commands for guardian check-in sticker
  Future<List<int>> _createGuardianCheckInStickerCommands({
    required List<String> childIds,
    required List<String> children,
    required List<String> pickupCodes,
    required String guardianQrCode,
    required String serviceName,
    required DateTime checkInTime,
  }) async {
    // Simple text-based commands for thermal printer
    final commands = <int>[];

    // Initialize printer
    commands.addAll([27, 64]); // ESC @ - Initialize printer
    commands.addAll([27, 97, 1]); // ESC a 1 - Center alignment

    // Header
    commands.addAll([27, 33, 48]); // ESC ! 48 - Double height and width
    commands.addAll(_textToBytes('KIDS CHURCH\n'));
    commands.addAll([27, 33, 16]); // ESC ! 16 - Bold text
    commands.addAll(_textToBytes('GUARDIAN PICKUP SLIP\n\n'));

    // Child name loop to print the names of the children
    for (int i = 0; i < children.length; i++) {
      commands.addAll([27, 33, 16]); // ESC ! 16 - Bold text
      commands.addAll(_textToBytes('CHILD:\n'));
      commands.addAll([27, 33, 48]); // ESC ! 48 - Double height and width
      commands.addAll(_textToBytes('${children[i]}\n\n'));
    }

    // Pickup code loop to print the pickup codes of the children
    for (int i = 0; i < pickupCodes.length; i++) {
      commands.addAll([27, 33, 16]); // ESC ! 16 - Bold text
      commands.addAll(_textToBytes('PICKUP CODE:\n'));
      commands.addAll([27, 33, 48]); // ESC ! 48 - Double height and width
      commands.addAll(_textToBytes('${pickupCodes[i]}\n\n'));
    }

    // Add spacing and center the QR code
    commands.addAll([27, 97, 1]); // ESC a 1 - Center alignment
    commands.addAll(_textToBytes('\n')); // Extra spacing

    // format should be on jsonstring format
    final qrData = json.encode({
      'guardianQrCode': guardianQrCode,
      'pickupCodes': pickupCodes,
      'childIds': childIds,
    });

    final qrImage = await _generateQRCodeImage(qrData, size: 256);
    final qrCommands = await _imageToEscPosCommands(qrImage);
    commands.addAll(qrCommands);

    // Reset alignment and add spacing after QR code
    commands.addAll([27, 97, 0]); // ESC a 0 - Left alignment
    commands.addAll(_textToBytes('\n\n'));

    // Service and time
    commands.addAll(_textToBytes('SERVICE: $serviceName\n'));
    commands.addAll(_textToBytes('TIME: ${_formatTime(checkInTime)}\n\n'));

    // Footer
    commands
        .addAll(_textToBytes('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n'));

    // Cut paper
    commands.addAll([29, 86, 66, 0]); // GS V B 0 - Full cut

    return commands;
  }

  /// Convert text to bytes for ESC/POS commands
  List<int> _textToBytes(String text) {
    return text.codeUnits;
  }

  /// Format time for display
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Generate QR code as image data
  Future<Uint8List> _generateQRCodeImage(String data, {int size = 200}) async {
    try {
      print(
          '🖨️ Generating QR code for data: "$data" with size: ${size}x$size');

      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: false,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final qrSize = size.toDouble();

      qrPainter.paint(canvas, Size(qrSize, qrSize));
      final picture = recorder.endRecording();
      final image = await picture.toImage(qrSize.toInt(), qrSize.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      final result = byteData!.buffer.asUint8List();
      print('🖨️ QR code generated successfully: ${result.length} bytes');

      return result;
    } catch (e) {
      print('❌ Error generating QR code: $e');
      // Return a simple fallback image if QR generation fails
      return _createFallbackImage();
    }
  }

  /// Create a simple fallback image if QR generation fails
  Uint8List _createFallbackImage() {
    // Create a simple 8x8 black and white pattern as fallback
    final bytes = <int>[];
    for (int i = 0; i < 64; i++) {
      bytes.add(i % 2 == 0 ? 0xFF : 0x00); // Alternating black and white
    }
    return Uint8List.fromList(bytes);
  }

  /// Convert image to ESC/POS bitmap commands
  Future<List<int>> _imageToEscPosCommands(Uint8List imageData) async {
    final commands = <int>[];

    try {
      print('🖨️ Converting actual QR code image to ESC/POS commands...');
      print('🖨️ Image data length: ${imageData.length} bytes');

      // Decode the PNG image data
      final decoded = img.decodeImage(imageData);
      if (decoded == null) {
        print('❌ Failed to decode PNG image');
        throw Exception('Failed to decode PNG image');
      }

      print('🖨️ Decoded image: ${decoded.width}x${decoded.height}');

      // Load ESC/POS capability profile
      final profile = await CapabilityProfile.load();

      // Create generator with 58mm paper size (common for thermal printers)
      final generator = Generator(PaperSize.mm58, profile);

      // Convert image to ESC/POS raster commands
      final List<int> rasterCommands = generator.imageRaster(decoded);

      print('🖨️ Generated ${rasterCommands.length} ESC/POS raster commands');

      return rasterCommands;
    } catch (e) {
      print('❌ Error converting image to ESC/POS: $e');
      // Fallback to simple pattern if conversion fails
      commands.addAll([29, 118, 48, 0]); // GS v 0 - Print raster bitmap
      commands.addAll([1, 0, 8, 0]); // 1 byte width, 8 dots height
      for (int i = 0; i < 8; i++) {
        commands.add(0xFF); // Solid black line
      }
      return commands;
    }
  }
}
