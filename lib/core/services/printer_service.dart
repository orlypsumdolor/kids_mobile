import 'dart:async';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_usb_thermal_plugin/flutter_usb_thermal_plugin.dart';
import 'package:flutter_usb_thermal_plugin/model/usb_device_model.dart';
import '../../domain/entities/child.dart';
import '../../domain/entities/checkin_session.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:image/image.dart' as img;
import '../models/connected_printer_info.dart';

enum PrinterConnectionType { bluetooth, usb }

class PrinterService {
  bool _isConnected = false;
  PrinterConnectionType? _connectionType;
  BluetoothInfo? _connectedDevice;
  BluetoothDevice? _connectedBleDevice;
  String? _connectedUsbName;
  String? _connectedUsbVendorId;
  String? _connectedUsbProductId;
  FlutterUsbThermalPlugin? _usbPlugin;
  static const String _printerNameKey = 'connected_printer_name';
  static const String _printerAddressKey = 'connected_printer_address';
  static const String _printerTypeKey = 'connected_printer_type';
  static const String _printerUsbVendorIdKey = 'connected_printer_usb_vendor_id';
  static const String _printerUsbProductIdKey = 'connected_printer_usb_product_id';

  bool get isConnected => _isConnected;
  PrinterConnectionType? get connectionType => _connectionType;

  /// Unified connected printer info for display (works for both Bluetooth and USB).
  ConnectedPrinterInfo? get connectedDevice {
    if (!_isConnected) return null;
    if (_connectionType == PrinterConnectionType.usb &&
        _connectedUsbName != null &&
        _connectedUsbVendorId != null &&
        _connectedUsbProductId != null) {
      return ConnectedPrinterInfo(
        name: _connectedUsbName!,
        addressOrId: 'USB (${_connectedUsbVendorId!}:${_connectedUsbProductId!})',
        isUsb: true,
      );
    }
    if (_connectionType == PrinterConnectionType.bluetooth && _connectedDevice != null) {
      return ConnectedPrinterInfo(
        name: _connectedDevice!.name ?? 'Unknown',
        addressOrId: _connectedDevice!.macAdress ?? '',
        isUsb: false,
      );
    }
    return null;
  }

  /// Initialize the printer service and restore saved connection
  Future<void> initialize() async {
    try {
      await _restoreSavedConnection();
    } catch (e) {
      print('⚠️ Could not restore saved printer connection: $e');
    }
  }

  /// Save Bluetooth printer connection to persistent storage
  Future<void> _savePrinterConnection(BluetoothInfo device) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_printerTypeKey, 'bluetooth');
      await prefs.setString(_printerNameKey, device.name ?? 'Unknown');
      await prefs.setString(_printerAddressKey, device.macAdress ?? '');
      await prefs.remove(_printerUsbVendorIdKey);
      await prefs.remove(_printerUsbProductIdKey);
      print(
          '💾 Saved printer connection: ${device.name} (${device.macAdress})');
    } catch (e) {
      print('❌ Failed to save printer connection: $e');
    }
  }

  /// Save USB printer connection to persistent storage
  Future<void> _saveUsbPrinterConnection(
      String name, String vendorId, String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_printerTypeKey, 'usb');
      await prefs.setString(_printerNameKey, name);
      await prefs.setString(_printerUsbVendorIdKey, vendorId);
      await prefs.setString(_printerUsbProductIdKey, productId);
      await prefs.remove(_printerAddressKey);
      print('💾 Saved USB printer connection: $name ($vendorId:$productId)');
    } catch (e) {
      print('❌ Failed to save USB printer connection: $e');
    }
  }

  /// Restore printer connection from persistent storage
  Future<void> _restoreSavedConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedType = prefs.getString(_printerTypeKey);
      final savedName = prefs.getString(_printerNameKey);

      if (savedName == null || savedName.isEmpty) return;

      if (savedType == 'usb') {
        final vendorId = prefs.getString(_printerUsbVendorIdKey);
        final productId = prefs.getString(_printerUsbProductIdKey);
        if (vendorId != null &&
            productId != null &&
            vendorId.isNotEmpty &&
            productId.isNotEmpty) {
          print(
              '🔄 Restoring saved USB printer connection: $savedName ($vendorId:$productId)');
          final success = await connectUsb(savedName, vendorId, productId);
          if (success) {
            print('✅ Successfully restored connection to saved USB printer');
          } else {
            print(
                '⚠️ Could not restore connection to saved USB printer, clearing saved data');
            await _clearSavedConnection();
          }
        }
        return;
      }

      // Bluetooth
      final savedAddress = prefs.getString(_printerAddressKey);
      if (savedAddress != null && savedAddress.isNotEmpty) {
        print(
            '🔄 Restoring saved printer connection: $savedName ($savedAddress)');
        final savedDevice = BluetoothInfo(
          name: savedName,
          macAdress: savedAddress,
        );
        final success = await connectBluetooth(savedDevice);
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
      await prefs.remove(_printerTypeKey);
      await prefs.remove(_printerNameKey);
      await prefs.remove(_printerAddressKey);
      await prefs.remove(_printerUsbVendorIdKey);
      await prefs.remove(_printerUsbProductIdKey);
      print('🗑️ Cleared saved printer connection');
    } catch (e) {
      print('❌ Failed to clear saved printer connection: $e');
    }
  }

  /// Public method to clear saved printer connection
  Future<void> clearSavedConnection() async {
    await _clearSavedConnection();
    _isConnected = false;
    _connectionType = null;
    _connectedDevice = null;
    _connectedBleDevice = null;
    _connectedUsbName = null;
    _connectedUsbVendorId = null;
    _connectedUsbProductId = null;
    _usbPlugin = null;
    print('🗑️ Public clear saved connection completed');
  }

  /// Open app settings so the user can enable Bluetooth (Nearby devices) and Location
  Future<void> openAppSettings() async {
    try {
      await perm.openAppSettings();
      print('🔧 Opened app settings');
    } catch (e) {
      print('❌ Could not open app settings: $e');
    }
  }

  /// Check if permissions are granted without requesting them
  Future<Map<String, bool>> checkPermissionStatus() async {
    final bluetoothStatus = await perm.Permission.bluetooth.status;
    final bluetoothScanStatus = await perm.Permission.bluetoothScan.status;
    final bluetoothConnectStatus = await perm.Permission.bluetoothConnect.status;
    final locationStatus = await perm.Permission.location.status;

    return {
      'bluetooth': bluetoothStatus == perm.PermissionStatus.granted,
      'bluetoothScan': bluetoothScanStatus == perm.PermissionStatus.granted,
      'bluetoothConnect': bluetoothConnectStatus == perm.PermissionStatus.granted,
      'location': locationStatus == perm.PermissionStatus.granted,
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
      final bluetoothStatus = await perm.Permission.bluetooth.status;
      final bluetoothScanStatus = await perm.Permission.bluetoothScan.status;
      final bluetoothConnectStatus = await perm.Permission.bluetoothConnect.status;
      final locationStatus = await perm.Permission.location.status;

      print('🔐 Current permission status:');
      print('   Bluetooth: $bluetoothStatus');
      print('   BluetoothScan: $bluetoothScanStatus');
      print('   BluetoothConnect: $bluetoothConnectStatus');
      print('   Location: $locationStatus');

      // Request Bluetooth permissions if not granted
      if (bluetoothStatus != perm.PermissionStatus.granted) {
        print('🔐 Requesting Bluetooth permission...');
        final result = await perm.Permission.bluetooth.request();
        if (result != perm.PermissionStatus.granted) {
          print('❌ Bluetooth permission denied');
          print(
              '💡 Please enable "Nearby devices" permission in Settings > Apps > Kids Church Check-in > Permissions');
          return false;
        }
      }

      // Request Bluetooth Scan permission if not granted (Android 12+)
      if (bluetoothScanStatus != perm.PermissionStatus.granted) {
        print('🔐 Requesting Bluetooth Scan permission...');
        final result = await perm.Permission.bluetoothScan.request();
        if (result != perm.PermissionStatus.granted) {
          print('❌ Bluetooth Scan permission denied');
          print(
              '💡 Please enable "Nearby devices" permission in Settings > Apps > Kids Church Check-in > Permissions');
          return false;
        }
      }

      // Request Bluetooth Connect permission if not granted (Android 12+)
      if (bluetoothConnectStatus != perm.PermissionStatus.granted) {
        print('🔐 Requesting Bluetooth Connect permission...');
        final result = await perm.Permission.bluetoothConnect.request();
        if (result != perm.PermissionStatus.granted) {
          print('❌ Bluetooth Connect permission denied');
          print(
              '💡 Please enable "Nearby devices" permission in Settings > Apps > Kids Church Check-in > Permissions');
          return false;
        }
      }

      // Check location permission (required for Bluetooth scanning on Android)
      if (locationStatus != perm.PermissionStatus.granted) {
        print('🔐 Requesting Location permission...');
        final result = await perm.Permission.location.request();
        if (result != perm.PermissionStatus.granted) {
          print(
              '❌ Location permission denied (required for Bluetooth scanning)');
          print(
              '💡 Please enable "Location" permission in Settings > Apps > Kids Church Check-in > Permissions');
          return false;
        }
      }

      // Final check - verify all permissions are actually granted
      final finalBluetoothStatus = await perm.Permission.bluetooth.status;
      final finalBluetoothScanStatus = await perm.Permission.bluetoothScan.status;
      final finalBluetoothConnectStatus =
          await perm.Permission.bluetoothConnect.status;
      final finalLocationStatus = await perm.Permission.location.status;

      if (finalBluetoothStatus != perm.PermissionStatus.granted ||
          finalBluetoothScanStatus != perm.PermissionStatus.granted ||
          finalBluetoothConnectStatus != perm.PermissionStatus.granted ||
          finalLocationStatus != perm.PermissionStatus.granted) {
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

      // Request permissions FIRST before any Bluetooth API call (required on Android 12+)
      final permissionsGranted = await _ensurePermissions();
      if (!permissionsGranted) {
        print('⚠️ Bluetooth permissions not granted - cannot scan. User must enable Nearby devices (and Location) in app Settings.');
        return [];
      }

      // Now get paired devices from print_bluetooth_thermal
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
        print('🔐 Permissions granted, attempting BLE scan...');
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

        // Start the scan with shorter timeout
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

        // Wait for scan to complete
        await Future.delayed(const Duration(seconds: 6));

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

  /// Parse USB vendor/product ID (decimal or hex string)
  int? _parseUsbId(String s) {
    if (s.isEmpty) return null;
    final cleaned = s.toLowerCase().replaceFirst(RegExp(r'0x'), '');
    return int.tryParse(s) ?? int.tryParse(cleaned, radix: 16);
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
        lowerName.contains('rego') ||
        lowerName.contains('ruigong') ||
        lowerName.contains('rg-kl') ||
        lowerName.contains('m90') ||
        lowerName.contains('goojprt');
  }

  /// Connect to a Bluetooth device
  Future<bool> connectBluetooth(BluetoothInfo device) async {
    try {
      // Disconnect any existing connection first
      await disconnect();

      print(
          '🔗 Connecting to Bluetooth ${device.name ?? 'Unknown'} (${device.macAdress ?? 'No address'})...');

      bool result = false;
      try {
        result = await PrintBluetoothThermal.connect(
            macPrinterAddress: device.macAdress);
      } catch (e) {
        print('❌ print_bluetooth_thermal connection failed: $e');
        try {
          final bleDevice = BluetoothDevice.fromId(device.macAdress);
          await bleDevice.connect();
          _connectedBleDevice = bleDevice;
          result = true;
        } catch (bleError) {
          print('❌ BLE connection also failed: $bleError');
        }
      }

      if (result) {
        _isConnected = true;
        _connectionType = PrinterConnectionType.bluetooth;
        _connectedDevice = device;
        _connectedUsbName = null;
        _connectedUsbVendorId = null;
        _connectedUsbProductId = null;
        await _savePrinterConnection(device);
        print('✅ Connected to Bluetooth ${device.name ?? 'Unknown'}');
        return true;
      }
      print('❌ Failed to connect to ${device.name ?? 'Unknown'}');
      return false;
    } catch (e) {
      print('❌ Failed to connect: $e');
      return false;
    }
  }

  /// Connect to a USB printer
  Future<bool> connectUsb(String name, String vendorId, String productId) async {
    try {
      await disconnect();

      print('🔗 Connecting to USB printer $name ($vendorId:$productId)...');

      final vid = _parseUsbId(vendorId);
      final pid = _parseUsbId(productId);
      if (vid == null || pid == null) {
        print('❌ Invalid USB vendor/product ID: $vendorId, $productId');
        return false;
      }

      final plugin = FlutterUsbThermalPlugin();
      final result = await plugin.connect(vid, pid);

      if (result == true) {
        _isConnected = true;
        _connectionType = PrinterConnectionType.usb;
        _connectedDevice = null;
        _connectedBleDevice = null;
        _connectedUsbName = name;
        _connectedUsbVendorId = vendorId;
        _connectedUsbProductId = productId;
        _usbPlugin = plugin;
        await _saveUsbPrinterConnection(name, vendorId, productId);
        print('✅ Connected to USB printer $name');
        return true;
      }
      print('❌ Failed to connect to USB printer $name');
      return false;
    } catch (e) {
      print('❌ Failed to connect to USB printer: $e');
      return false;
    }
  }

  /// Connect to a Bluetooth device (alias for backward compatibility)
  Future<bool> connect(BluetoothInfo device) async =>
      connectBluetooth(device);

  /// Try to reconnect using the last saved printer (Bluetooth or USB).
  /// Returns true if reconnection succeeded.
  Future<bool> reconnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedType = prefs.getString(_printerTypeKey);
      final savedName = prefs.getString(_printerNameKey);
      if (savedName == null || savedName.isEmpty) return false;

      if (savedType == 'usb') {
        final vendorId = prefs.getString(_printerUsbVendorIdKey);
        final productId = prefs.getString(_printerUsbProductIdKey);
        if (vendorId != null &&
            productId != null &&
            vendorId.isNotEmpty &&
            productId.isNotEmpty) {
          return await connectUsb(savedName, vendorId, productId);
        }
        return false;
      }

      final savedAddress = prefs.getString(_printerAddressKey);
      if (savedAddress == null || savedAddress.isEmpty) return false;
      return await connectBluetooth(
          BluetoothInfo(name: savedName, macAdress: savedAddress));
    } catch (e) {
      print('❌ Reconnect failed: $e');
      return false;
    }
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    try {
      if (!_isConnected) return;

      if (_connectionType == PrinterConnectionType.usb) {
        print('🔌 Disconnecting from USB printer $_connectedUsbName');
        _usbPlugin = null;
        _connectedUsbName = null;
        _connectedUsbVendorId = null;
        _connectedUsbProductId = null;
      } else if (_connectedDevice != null) {
        print('🔌 Disconnecting from ${_connectedDevice!.name ?? 'Unknown'}');
        if (_connectedBleDevice != null) {
          await _connectedBleDevice!.disconnect();
          _connectedBleDevice = null;
        }
        await PrintBluetoothThermal.disconnect;
        _connectedDevice = null;
      }

      _isConnected = false;
      _connectionType = null;
      await _clearSavedConnection();
      print('✅ Disconnected successfully');
    } catch (e) {
      print('❌ Error disconnecting: $e');
    }
  }

  static const MethodChannel _usbChannel =
      MethodChannel('com.kidschurch.checkin/usb');

  /// Get available USB printers (devices already attached via USB).
  /// Tries plugin first; if empty, uses native UsbManager.getDeviceList() so
  /// OTG printers (e.g. Goojprt MTP-3) are detected on all devices.
  Future<List<UsbDevice>> getAvailableUsbDevices() async {
    try {
      print('🔍 Scanning for USB printers...');
      final plugin = FlutterUsbThermalPlugin();
      List<UsbDevice> devices = await plugin.getUSBDeviceList();
      if (devices.isEmpty) {
        try {
          final dynamic raw =
              await _usbChannel.invokeMethod('getUsbDeviceList');
          if (raw is List && raw.isNotEmpty) {
            devices = raw
                .map((e) => _mapToUsbDevice(e as Map<dynamic, dynamic>))
                .toList();
            print('🔍 Native USB: found ${devices.length} device(s)');
          }
        } catch (e) {
          print('⚠️ Native USB fallback error: $e');
        }
      }
      print('🔍 Found ${devices.length} USB device(s) total');
      return devices;
    } catch (e) {
      print('⚠️ USB discovery error: $e');
      return [];
    }
  }

  static UsbDevice _mapToUsbDevice(Map<dynamic, dynamic> map) {
    return UsbDevice(
      manufacturer: (map['manufacturer'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? 'USB Device',
      vendorId: (map['vendorId'] as String?) ?? '0',
      productId: (map['productId'] as String?) ?? '0',
    );
  }

  /// Get available USB printers (alias for compatibility)
  Future<List<UsbDevice>> getAvailableUsbDevicesWithTimeout() async {
    return getAvailableUsbDevices();
  }

  /// Print check-in sticker
  Future<bool> printCheckInSticker({
    required Child child,
    required CheckInSession session,
  }) async {
    if (!_isConnected) {
      throw Exception('Printer not connected');
    }

    try {
      print('🖨️ Printing check-in sticker for ${child.fullName}...');

      final commands = await _createCheckInStickerCommands(
        childName: child.fullName,
        childId: child.id,
        guardianId: child.primaryGuardianId ?? 'No guardian',
        pickupCode: session.pickupCode,
        serviceSession: session.serviceSession,
        checkinTime: session.checkinTime,
      );

      final result = await _sendBytes(commands);
      if (result) {
        print('✅ Check-in sticker printed successfully');
        return true;
      }
      print('❌ Print failed');
      return false;
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
    if (!_isConnected) {
      throw Exception('Printer not connected');
    }

    try {
      print('🖨️ Printing guardian check-in sticker for $children...');

      final commands = await _createGuardianCheckInStickerCommands(
        childIds: childIds,
        children: children,
        pickupCodes: pickupCodes,
        guardianQrCode: guardianQrCode,
        serviceName: serviceName,
        checkInTime: checkInTime,
      );

      final result = await _sendBytes(commands);
      if (result) {
        print('✅ Guardian check-in sticker printed successfully');
        return true;
      }
      print('❌ Print failed');
      return false;
    } catch (e) {
      print('❌ Failed to print guardian check-in sticker: $e');
      throw Exception('Failed to print guardian check-in sticker: $e');
    }
  }

  /// Send raw bytes to the connected printer (Bluetooth or USB)
  Future<bool> _sendBytes(List<int> commands) async {
    if (_connectionType == PrinterConnectionType.usb && _usbPlugin != null) {
      try {
        await _usbPlugin!.write(Uint8List.fromList(commands));
        return true;
      } catch (e) {
        print('❌ USB write error: $e');
        return false;
      }
    }
    return await PrintBluetoothThermal.writeBytes(commands);
  }

  /// Render sticker text layout as a landscape bitmap, rotate 90° clockwise,
  /// then return ESC/POS raster commands.
  ///
  /// Sticker is ~50mm (short, feeds first) x ~95mm (long, across paper).
  /// At 8 dots/mm: short side ≈ 400 dots, long side ≈ 576 dots (paper width).
  ///
  /// We render text in landscape (long x short), then rotate 90° CW so that:
  ///   rotated width  = 400 dots  → fits within 576-dot paper width
  ///   rotated height = 576+ dots → feeds out as the long dimension
  Future<List<int>> _renderStickerAsRaster(List<_StickerLine> lines) async {
    // Landscape canvas: long side across, short side down
    // Sticker is 50mm x 100mm → 400 x 800 dots at 8 dots/mm
    const int canvasW = 800; // sticker long side (100mm)
    const int canvasH = 400; // sticker short side (50mm)
    const double padding = 16;

    // Paint text onto landscape canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasW.toDouble(), canvasH.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // Measure total text block height
    double totalTextHeight = 0;
    for (final line in lines) {
      totalTextHeight += line.fontSize + 6;
    }

    // Center vertically with a downward nudge (+30) to sit better on the sticker
    double y = ((canvasH - totalTextHeight) / 2) + 30;
    if (y < padding) y = padding;

    for (final line in lines) {
      final textStyle = ui.TextStyle(
        color: const Color(0xFF000000),
        fontSize: line.fontSize,
        fontWeight: line.bold ? FontWeight.bold : FontWeight.normal,
      );
      final paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(textAlign: TextAlign.center),
      )
        ..pushStyle(textStyle)
        ..addText(line.text);
      final paragraph = paragraphBuilder.build();
      paragraph.layout(ui.ParagraphConstraints(width: canvasW - padding * 2));
      canvas.drawParagraph(paragraph, Offset(padding, y));
      y += line.fontSize + 6;
    }

    final picture = recorder.endRecording();
    final landscapeImg = await picture.toImage(canvasW, canvasH);
    final byteData =
        await landscapeImg.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // Decode, rotate 90° clockwise, re-encode
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) throw Exception('Failed to decode sticker image');
    final rotated = img.copyRotate(decoded, 90);

    print('🖨️ Sticker rendered ${canvasW}x$canvasH → rotated to ${rotated.width}x${rotated.height}');

    final rotatedPng = Uint8List.fromList(img.encodePng(rotated));
    return _imageToEscPosCommands(rotatedPng);
  }

  /// Create raster commands for check-in sticker.
  Future<List<int>> _createCheckInStickerCommands({
    required String childName,
    required String childId,
    required String guardianId,
    required String pickupCode,
    required String serviceSession,
    required DateTime checkinTime,
  }) async {
    final lines = <_StickerLine>[
      _StickerLine('KIDS CHURCH CHECK-IN', fontSize: 32, bold: true),
      _StickerLine(childName, fontSize: 52, bold: true),
      _StickerLine(pickupCode, fontSize: 48, bold: true),
      _StickerLine('$serviceSession  ${_formatTime(checkinTime)}', fontSize: 24),
    ];

    final raster = await _renderStickerAsRaster(lines);
    final profile = await CapabilityProfile.load();
    final gen = Generator(PaperSize.mm80, profile);
    return [...raster, ...gen.cut()];
  }

  /// Create raster commands for guardian check-in sticker.
  Future<List<int>> _createGuardianCheckInStickerCommands({
    required List<String> childIds,
    required List<String> children,
    required List<String> pickupCodes,
    required String guardianQrCode,
    required String serviceName,
    required DateTime checkInTime,
  }) async {
    final lines = <_StickerLine>[
      _StickerLine('KIDS CHURCH PICKUP SLIP', fontSize: 32, bold: true),
    ];

    for (int i = 0; i < children.length; i++) {
      lines.add(_StickerLine(children[i], fontSize: 48, bold: true));
      if (i < pickupCodes.length) {
        lines.add(_StickerLine('CODE: ${pickupCodes[i]}', fontSize: 28, bold: true));
      }
    }

    lines.add(_StickerLine('$serviceName  ${_formatTime(checkInTime)}', fontSize: 24));

    final raster = await _renderStickerAsRaster(lines);
    final profile = await CapabilityProfile.load();
    final gen = Generator(PaperSize.mm80, profile);
    return [...raster, ...gen.cut()];
  }

  /// Format time for display
  String _formatTime(DateTime dateTime) {
    // Convert UTC time to local timezone
    final localDateTime = dateTime.toLocal();

    final hour = localDateTime.hour;
    final minute = localDateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';

    // Convert to 12-hour format
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
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

      // M90 / REGO RG-KL532A-H uses 80mm paper (576 dots/line, 72mm effective)
      final generator = Generator(PaperSize.mm80, profile);

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

  /// Get available Bluetooth devices with timeout wrapper
  Future<List<BluetoothInfo>> getAvailableDevicesWithTimeout() async {
    try {
      print('⏰ Starting timeout wrapper for device scanning...');
      final result = await getAvailableDevices().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏰ Device scanning timed out after 15 seconds');
          return <BluetoothInfo>[];
        },
      );
      print(
          '⏰ Timeout wrapper completed successfully with ${result.length} devices');
      return result;
    } catch (e) {
      print('💥 Timeout wrapper error: $e');
      return <BluetoothInfo>[];
    }
  }
}

class _StickerLine {
  final String text;
  final double fontSize;
  final bool bold;

  const _StickerLine(this.text, {this.fontSize = 24, this.bold = false});
}
