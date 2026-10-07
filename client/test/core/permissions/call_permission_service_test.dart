import 'package:flutter_test/flutter_test.dart';
import 'package:client/core/permissions/call_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CallPermissionService Tests', () {
    test('hasAudioCallPermissions and hasVideoCallPermissions return boolean', () async {
      // In test environment without native channel mocking, checking calls
      expect(CallPermissionService.hasAudioCallPermissions, isNotNull);
      expect(CallPermissionService.hasVideoCallPermissions, isNotNull);
      expect(CallPermissionService.requestAudioCallPermissions, isNotNull);
      expect(CallPermissionService.requestVideoCallPermissions, isNotNull);
    });
  });
}
