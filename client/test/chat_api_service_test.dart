import 'dart:convert';
import 'package:client/core/network/api_client.dart';
import 'package:client/features/chat/data/services/chat_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.Request request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final httpRequest = request as http.Request;
    final response = await handler(httpRequest);
    return http.StreamedResponse(Stream.value(response.bodyBytes), response.statusCode, headers: response.headers);
  }
}

void main() {
  group('ChatApiService Tests', () {
    test('getConversations fetches and parses conversations list', () async {
      final mockClient = MockHttpClient((req) async {
        expect(req.url.path, '/api/conversations');
        expect(req.headers['authorization'], 'Bearer test_token');

        final body = jsonEncode({
          'success': true,
          'data': {
            'conversations': [
              {
                'id': 'conv_123',
                'type': 'direct',
                'other_user': {'user_id': 'u2', 'username': 'bob', 'display_name': 'Bob'},
                'last_message': {
                  'id': 'm1',
                  'conversation_id': 'conv_123',
                  'sender_id': 'u2',
                  'sender_username': 'bob',
                  'sender_display_name': 'Bob',
                  'content': 'Hello!',
                  'status': 'sent',
                  'created_at': '2026-10-05T10:00:00Z',
                  'updated_at': '2026-10-05T10:00:00Z',
                },
                'unread_count': 1,
                'created_at': '2026-10-05T09:00:00Z',
                'updated_at': '2026-10-05T10:00:00Z',
              },
            ],
            'total': 1,
          },
        });

        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3000');
      final service = ChatApiService(apiClient: apiClient);

      final result = await service.getConversations(token: 'test_token');
      expect(result.length, 1);
      expect(result.first.id, 'conv_123');
      expect(result.first.displayName, 'Bob');
      expect(result.first.displaySubtitle, 'Hello!');
    });

    test('createOrGetDirectConversation posts friend_username and returns ConversationModel', () async {
      final mockClient = MockHttpClient((req) async {
        expect(req.url.path, '/api/conversations/direct');
        final decoded = jsonDecode(req.body);
        expect(decoded['friend_username'], 'alice');

        final body = jsonEncode({
          'success': true,
          'data': {
            'id': 'conv_456',
            'type': 'direct',
            'other_user': {'user_id': 'u3', 'username': 'alice', 'display_name': 'Alice'},
            'unread_count': 0,
            'created_at': '2026-10-05T09:00:00Z',
            'updated_at': '2026-10-05T09:00:00Z',
          },
        });

        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3000');
      final service = ChatApiService(apiClient: apiClient);

      final result = await service.createOrGetDirectConversation(friendUsername: 'alice', token: 'test_token');
      expect(result.id, 'conv_456');
      expect(result.otherUser?.username, 'alice');
    });

    test('getMessages fetches messages for a conversation', () async {
      final mockClient = MockHttpClient((req) async {
        expect(req.url.path, '/api/conversations/conv_123/messages');
        expect(req.url.queryParameters['limit'], '30');

        final body = jsonEncode({
          'success': true,
          'data': {
            'messages': [
              {
                'id': 'm1',
                'conversation_id': 'conv_123',
                'sender_id': 'u1',
                'sender_username': 'me',
                'sender_display_name': 'Me',
                'content': 'How are you?',
                'status': 'sent',
                'created_at': '2026-10-05T10:00:00Z',
                'updated_at': '2026-10-05T10:00:00Z',
              },
            ],
            'next_cursor': null,
            'has_more': false,
          },
        });

        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3000');
      final service = ChatApiService(apiClient: apiClient);

      final result = await service.getMessages(conversationId: 'conv_123', token: 'test_token');
      expect(result.messages.length, 1);
      expect(result.messages.first.content, 'How are you?');
      expect(result.hasMore, isFalse);
    });

    test('sendMessage sends message payload and returns MessageModel', () async {
      final mockClient = MockHttpClient((req) async {
        expect(req.url.path, '/api/messages');
        final decoded = jsonDecode(req.body);
        expect(decoded['conversation_id'], 'conv_123');
        expect(decoded['content'], 'Hello!');

        final body = jsonEncode({
          'success': true,
          'data': {
            'id': 'm2',
            'conversation_id': 'conv_123',
            'sender_id': 'u1',
            'sender_username': 'me',
            'sender_display_name': 'Me',
            'content': 'Hello!',
            'status': 'sent',
            'created_at': '2026-10-05T10:05:00Z',
            'updated_at': '2026-10-05T10:05:00Z',
          },
        });

        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3000');
      final service = ChatApiService(apiClient: apiClient);

      final result = await service.sendMessage(conversationId: 'conv_123', content: 'Hello!', token: 'test_token');
      expect(result.id, 'm2');
      expect(result.content, 'Hello!');
    });
  });
}
