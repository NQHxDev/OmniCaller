import 'dart:convert';
import 'package:client/core/network/api_client.dart';
import 'package:client/features/search/data/services/user_search_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('UserSearchApiService Tests', () {
    test('searchUsers sends request with query parameters and auth header', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/users/search');
        expect(request.url.queryParameters['query'], 'john');
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['page_size'], '10');
        expect(request.headers['Authorization'], 'Bearer fake_token');

        final responseBody = {
          'success': true,
          'data': {
            'users': [
              {
                'user_id': 'u123',
                'username': 'johndoe',
                'display_name': 'John Doe',
              }
            ],
            'pagination': {
              'current_page': 1,
              'page_size': 10,
              'total_items': 1,
              'total_pages': 1,
            }
          },
          'error': null,
        };

        return http.Response(
          jsonEncode(responseBody),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3000');
      final searchService = UserSearchApiService(apiClient: apiClient);

      final result = await searchService.searchUsers(
        query: 'john',
        token: 'fake_token',
      );

      expect(result.users.length, 1);
      expect(result.users[0].username, 'johndoe');
      expect(result.users[0].displayName, 'John Doe');
      expect(result.pagination.totalItems, 1);
    });

    test('getUserProfile sends request and parses UserPublicProfile', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/users/john123');
        expect(request.headers['Authorization'], 'Bearer fake_token');

        final responseBody = {
          'success': true,
          'data': {
            'user_id': '01928374-5678-9abc-def0-123456789abc',
            'username': 'john123',
            'display_name': 'John Doe',
            'created_at': '2024-10-01 10:30:45.123456 +00:00',
          },
          'error': null,
        };

        return http.Response(
          jsonEncode(responseBody),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3000');
      final searchService = UserSearchApiService(apiClient: apiClient);

      final result = await searchService.getUserProfile(
        username: 'john123',
        token: 'fake_token',
      );

      expect(result.userId, '01928374-5678-9abc-def0-123456789abc');
      expect(result.username, 'john123');
      expect(result.displayName, 'John Doe');
      expect(result.createdAt, contains('2024-10-01'));
    });
  });
}
