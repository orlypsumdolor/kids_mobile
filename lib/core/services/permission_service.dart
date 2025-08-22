import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> requestBluetoothPermission() async {
    final status = await Permission.bluetooth.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status == PermissionStatus.granted;
  }

  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status == PermissionStatus.granted;
  }

  Future<bool> hasBluetoothPermission() async {
    final status = await Permission.bluetooth.status;
    return status == PermissionStatus.granted;
  }

  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    return await [
      Permission.camera,
      Permission.location,
      Permission.bluetooth,
    ].request();
  }
}