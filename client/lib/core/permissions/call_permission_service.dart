import 'package:permission_handler/permission_handler.dart' as ph;

class CallPermissionService {
  /// Request necessary permissions for audio calls (Microphone, Bluetooth).
  static Future<bool> requestAudioCallPermissions() async {
    final permissions = <ph.Permission>[ph.Permission.microphone, ph.Permission.bluetoothConnect];

    final statuses = await permissions.request();
    final micGranted = statuses[ph.Permission.microphone]?.isGranted ?? false;
    return micGranted;
  }

  /// Request necessary permissions for video calls (Camera, Microphone, Bluetooth).
  static Future<bool> requestVideoCallPermissions() async {
    final permissions = <ph.Permission>[ph.Permission.microphone, ph.Permission.camera, ph.Permission.bluetoothConnect];

    final statuses = await permissions.request();
    final micGranted = statuses[ph.Permission.microphone]?.isGranted ?? false;
    final cameraGranted = statuses[ph.Permission.camera]?.isGranted ?? false;
    return micGranted && cameraGranted;
  }

  /// Check if microphone permission is granted.
  static Future<bool> hasAudioCallPermissions() async {
    return await ph.Permission.microphone.isGranted;
  }

  /// Check if both camera and microphone permissions are granted.
  static Future<bool> hasVideoCallPermissions() async {
    final micGranted = await ph.Permission.microphone.isGranted;
    final cameraGranted = await ph.Permission.camera.isGranted;
    return micGranted && cameraGranted;
  }

  /// Open application settings if permissions were permanently denied.
  static Future<bool> openSettings() async {
    return await ph.openAppSettings();
  }
}
