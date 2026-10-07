import 'dart:convert';
import 'package:client/core/network/api_client.dart';
import 'package:client/core/network/api_exception.dart';
import 'package:client/features/auth/data/services/auth_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthApiService Tests', () {
    test('login succeeds and parses response correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          final body = jsonDecode(request.body);
          if (body['username'] == 'testuser' && body['password'] == 'password123') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'user_id': 'uid_123',
                  'username': 'testuser',
                  'display_name': 'Test User',
                  'access_token': 'access_token_123',
                  'refresh_token': 'refresh_token_123',
                },
                'error': null,
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
        }
        return http.Response(
          jsonEncode({
            'success': false,
            'data': null,
            'error': 'Invalid username or password',
          }),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3000');
      final authService = AuthApiService(apiClient: apiClient);

      final result = await authService.login(
        username: 'testuser',
        password: 'password123',
      );

      expect(result.userId, 'uid_123');
      expect(result.username, 'testuser');
      expect(result.displayName, 'Test User');
      expect(result.accessToken, 'access_token_123');
      expect(result.refreshToken, 'refresh_token_123');
    });

    test('login throws ApiException on invalid credentials', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'data': null,
            'error': 'Invalid username or password',
          }),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3000');
      final authService = AuthApiService(apiClient: apiClient);

      expect(
        () => authService.login(
          username: 'wronguser',
          password: 'wrongpassword',
        ),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Invalid username or password',
        )),
      );
    });

    test('register succeeds and returns session info', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/register') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'user_id': 'uid_new_456',
                'username': 'newuser',
                'display_name': 'New User',
                'access_token': 'new_access_token',
                'refresh_token': 'new_refresh_token',
              },
              'error': null,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3000');
      final authService = AuthApiService(apiClient: apiClient);

      final result = await authService.register(
        displayName: 'New User',
        username: 'newuser',
        password: 'password123',
        confirmPassword: 'password123',
      );

      expect(result.userId, 'uid_new_456');
      expect(result.username, 'newuser');
      expect(result.displayName, 'New User');
    });

    test('refreshToken sends request and returns new tokens', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/refresh') {
          final body = jsonDecode(request.body);
          if (body['refresh_token'] == 'valid_refresh_token') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'access_token': 'new_access_token_789',
                  'refresh_token': 'new_refresh_token_789',
                },
                'error': null,
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
        }
        return http.Response(
          jsonEncode({
            'success': false,
            'data': null,
            'error': 'Invalid refresh token',
          }),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3000');
      final authService = AuthApiService(apiClient: apiClient);

      final result = await authService.refreshToken('valid_refresh_token');
      expect(result.accessToken, 'new_access_token_789');
      expect(result.refreshToken, 'new_refresh_token_789');
    });

    test('logout sends request with Authorization Bearer header', () async {
      String? authHeaderReceived;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/logout') {
          authHeaderReceived = request.headers['Authorization'];
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'message': 'Logged out successfully',
              },
              'error': null,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3000');
      final authService = AuthApiService(apiClient: apiClient);

      await authService.logout('valid_token_xyz');

      expect(authHeaderReceived, 'Bearer valid_token_xyz');
    });
  });
}
