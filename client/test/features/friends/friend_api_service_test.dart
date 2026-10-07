import 'dart:convert';
import 'package:client/core/network/api_client.dart';
import 'package:client/features/friends/data/models/friend_models.dart';
import 'package:client/features/friends/data/services/friend_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('FriendApiService Tests', () {
    test('getFriends sends request and parses friends list', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/friends');
        expect(request.headers['Authorization'], 'Bearer test_token');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'friends': [
                {
                  'user_id': 'u1',
                  'username': 'john',
                  'display_name': 'John Doe',
                }
              ]
            }
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = FriendApiService(apiClient: ApiClient(client: mockClient));
      final friends = await service.getFriends(token: 'test_token');

      expect(friends.length, 1);
      expect(friends.first.username, 'john');
    });

    test('getReceivedFriendRequests and getSentFriendRequests parse correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/friends/requests/received') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'requests': [
                  {
                    'id': 'req_rec_1',
                    'user_id': 'u2',
                    'username': 'anna',
                    'display_name': 'Anna Bell',
                    'requested_at': '2024-01-01',
                  }
                ]
              }
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path == '/api/friends/requests/sent') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'requests': [
                  {
                    'id': 'req_sent_1',
                    'user_id': 'u3',
                    'username': 'ben',
                    'display_name': 'Ben Ten',
                    'requested_at': '2024-01-02',
                  }
                ]
              }
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = FriendApiService(apiClient: ApiClient(client: mockClient));
      final received = await service.getReceivedFriendRequests(token: 'token');
      final sent = await service.getSentFriendRequests(token: 'token');

      expect(received.length, 1);
      expect(received.first.username, 'anna');
      expect(sent.length, 1);
      expect(sent.first.username, 'ben');
    });

    test('sendFriendRequest sends friend_id body and returns request item', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/friends/requests');
        final body = jsonDecode(request.body);
        expect(body['friend_id'], 'u500');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'req_new_500',
              'user_id': 'u500',
              'username': 'target',
              'display_name': 'Target User',
              'requested_at': '2024-01-03',
            }
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = FriendApiService(apiClient: ApiClient(client: mockClient));
      final item = await service.sendFriendRequest(friendId: 'u500', token: 'token');

      expect(item.requestId, 'req_new_500');
      expect(item.userId, 'u500');
    });

    test('sendFriendRequest sends friend_username body and returns request item', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/friends/requests');
        final body = jsonDecode(request.body);
        expect(body['friend_username'], 'johndoe');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'req_new_600',
              'user_id': 'u600',
              'username': 'johndoe',
              'display_name': 'John Doe',
              'requested_at': '2024-01-03',
            }
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = FriendApiService(apiClient: ApiClient(client: mockClient));
      final item = await service.sendFriendRequest(friendUsername: 'johndoe', token: 'token');

      expect(item.requestId, 'req_new_600');
      expect(item.username, 'johndoe');
    });

    test('accept, reject, cancel, unfriend calls matching endpoints', () async {
      final pathsCalled = <String>[];
      final mockClient = MockClient((request) async {
        pathsCalled.add('${request.method} ${request.url.path}');
        return http.Response(
          jsonEncode({'success': true, 'data': {'message': 'ok'}}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = FriendApiService(apiClient: ApiClient(client: mockClient));
      await service.acceptFriendRequest(requestId: 'req_1', token: 'token');
      await service.rejectFriendRequest(requestId: 'req_2', token: 'token');
      await service.cancelFriendRequest(requestId: 'req_3', token: 'token');
      await service.unfriend(friendId: 'f_4', token: 'token');

      expect(pathsCalled, [
        'POST /api/friends/requests/req_1/accept',
        'POST /api/friends/requests/req_2/reject',
        'DELETE /api/friends/requests/req_3/cancel',
        'DELETE /api/friends/f_4',
      ]);
    });

    test('getFriendshipStatus returns parsed status', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/friends/status/u99');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'status': 'accepted',
              'request_id': 'r_99',
            }
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = FriendApiService(apiClient: ApiClient(client: mockClient));
      final statusData = await service.getFriendshipStatus(userId: 'u99', token: 'token');

      expect(statusData.status, FriendshipStatus.accepted);
      expect(statusData.requestId, 'r_99');
    });
  });
}
