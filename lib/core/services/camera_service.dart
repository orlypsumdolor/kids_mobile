import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  List<CameraDescription>? _cameras;
  CameraController? _controller;

  Future<void> initialize() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Camera permission denied');
    }

    _cameras = await availableCameras();
  }

  Future<CameraController> getCameraController() async {
    if (_cameras == null || _cameras!.isEmpty) {
      await initialize();
    }

    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      _cameras!.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    return _controller!;
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }

  bool get isInitialized => _controller?.value.isInitialized ?? false;
}
