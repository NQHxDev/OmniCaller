import 'dart:convert';
import 'package:client/core/network/api_client.dart';
import 'package:client/features/groups/data/services/group_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GroupApiService Tests', () {
    test('createGroup sends POST /api/groups and returns GroupProfileResponse', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/groups');
        expect(request.headers['Authorization'], 'Bearer test_token');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Flutter Devs');
        expect(body['member_ids'], ['u1', 'u2']);

        return http.Response(
          jsonEncode({
            'id': 'group-conv-uuid',
            'name': 'Flutter Devs',
            'description': null,
            'avatar_url': null,
            'banner_url': null,
            'pinned_message_id': null,
            'created_by': 'my-user-id',
            'member_count': 3,
            'created_at': '2026-10-05T10:00:00Z',
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = GroupApiService(apiClient: ApiClient(client: mockClient));
      final result = await service.createGroup(
        name: 'Flutter Devs',
        memberIds: ['u1', 'u2'],
        token: 'test_token',
      );

      expect(result.id, 'group-conv-uuid');
      expect(result.name, 'Flutter Devs');
      expect(result.memberCount, 3);
      expect(result.createdBy, 'my-user-id');
    });

    test('getUserGroups sends GET /api/groups and returns list of groups', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/groups');
        expect(request.headers['Authorization'], 'Bearer test_token');

        return http.Response(
          jsonEncode({
            'groups': [
              {
                'id': 'g1',
                'name': 'Group One',
                'description': null,
                'avatar_url': null,
                'banner_url': null,
                'pinned_message_id': null,
                'created_by': 'usr1',
                'member_count': 4,
                'created_at': '2026-10-05T08:00:00Z',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = GroupApiService(apiClient: ApiClient(client: mockClient));
      final groups = await service.getUserGroups(token: 'test_token');

      expect(groups.length, 1);
      expect(groups.first.name, 'Group One');
      expect(groups.first.memberCount, 4);
    });
  });
}
