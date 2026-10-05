import 'package:client/core/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiConfig Tests', () {
    tearDown(() {
      ApiConfig.resetBaseUrl();
    });

    test('default baseUrl points to physical device LAN IP 192.168.1.162:3000', () {
      expect(ApiConfig.baseUrl, 'http://192.168.1.162:3000');
    });

    test('runtime setBaseUrl overrides baseUrl and reset restores it', () {
      ApiConfig.setBaseUrl('http://192.168.1.200:8080');
      expect(ApiConfig.baseUrl, 'http://192.168.1.200:8080');

      ApiConfig.resetBaseUrl();
      expect(ApiConfig.baseUrl, 'http://192.168.1.162:3000');
    });
  });
}
