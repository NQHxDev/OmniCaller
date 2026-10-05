import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthModels Test', () {
    test('LoginRequestDto serialization formats username correctly', () {
      const dto = LoginRequestDto(
        username: 'TestUser123 ',
        password: 'password123',
      );

      final json = dto.toJson();
      expect(json['username'], 'testuser123');
      expect(json['password'], 'password123');
    });

    test('RegisterRequestDto serialization formats display name and username correctly', () {
      const dto = RegisterRequestDto(
        displayName: ' Test User ',
        username: ' TestUser123 ',
        password: 'password123',
        confirmPassword: 'password123',
      );

      final json = dto.toJson();
      expect(json['display_name'], 'Test User');
      expect(json['username'], 'testuser123');
      expect(json['password'], 'password123');
      expect(json['confirm_password'], 'password123');
    });

    test('AuthResponseDto deserializes correctly from json', () {
      final json = {
        'user_id': 'usr_abc_123',
        'username': 'john_doe',
        'display_name': 'John Doe',
        'access_token': 'jwt.access.token',
        'refresh_token': 'jwt.refresh.token',
      };

      final response = AuthResponseDto.fromJson(json);
      expect(response.userId, 'usr_abc_123');
      expect(response.username, 'john_doe');
      expect(response.displayName, 'John Doe');
      expect(response.accessToken, 'jwt.access.token');
      expect(response.refreshToken, 'jwt.refresh.token');
    });
  });
}
