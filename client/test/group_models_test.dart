import 'package:client/features/groups/data/models/group_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupModels Tests', () {
    test('CreateGroupRequest serializes to json properly', () {
      const request = CreateGroupRequest(
        name: 'Alpha Team',
        description: 'Team for project alpha',
        avatarUrl: 'http://example.com/avatar.png',
        bannerUrl: 'http://example.com/banner.png',
        memberIds: ['u1', 'u2'],
      );

      final json = request.toJson();
      expect(json['name'], 'Alpha Team');
      expect(json['description'], 'Team for project alpha');
      expect(json['avatar_url'], 'http://example.com/avatar.png');
      expect(json['banner_url'], 'http://example.com/banner.png');
      expect(json['member_ids'], ['u1', 'u2']);
    });

    test('GroupProfileResponse deserializes and serializes properly', () {
      final json = {
        'id': 'grp_123',
        'name': 'Alpha Team',
        'description': 'Dev Team',
        'avatar_url': 'http://example.com/a.png',
        'banner_url': null,
        'pinned_message_id': null,
        'created_by': 'usr_creator',
        'member_count': 5,
        'created_at': '2026-10-05T12:00:00Z',
      };

      final profile = GroupProfileResponse.fromJson(json);
      expect(profile.id, 'grp_123');
      expect(profile.name, 'Alpha Team');
      expect(profile.description, 'Dev Team');
      expect(profile.avatarUrl, 'http://example.com/a.png');
      expect(profile.bannerUrl, isNull);
      expect(profile.pinnedMessageId, isNull);
      expect(profile.createdBy, 'usr_creator');
      expect(profile.memberCount, 5);
      expect(profile.createdAt, '2026-10-05T12:00:00Z');

      final outputJson = profile.toJson();
      expect(outputJson['id'], 'grp_123');
      expect(outputJson['name'], 'Alpha Team');
      expect(outputJson['member_count'], 5);
    });
  });
}
