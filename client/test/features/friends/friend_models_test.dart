import 'package:client/features/friends/data/models/friend_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FriendModels Tests', () {
    test('FriendshipStatus enum parsing and serialization', () {
      expect(FriendshipStatus.fromString('pending_sent'), FriendshipStatus.pendingSent);
      expect(FriendshipStatus.fromString('pending_received'), FriendshipStatus.pendingReceived);
      expect(FriendshipStatus.fromString('pending'), FriendshipStatus.pendingReceived);
      expect(FriendshipStatus.fromString('accepted'), FriendshipStatus.accepted);
      expect(FriendshipStatus.fromString('rejected'), FriendshipStatus.rejected);
      expect(FriendshipStatus.fromString('blocked'), FriendshipStatus.blocked);
      expect(FriendshipStatus.fromString('unknown'), FriendshipStatus.none);

      expect(FriendshipStatus.accepted.toServerString(), 'accepted');
      expect(FriendshipStatus.pendingSent.toServerString(), 'pending_sent');
    });

    test('FriendUser deserialization and serialization', () {
      final json = {
        'user_id': 'u100',
        'username': 'bob',
        'display_name': 'Bob Builder',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final friend = FriendUser.fromJson(json);
      expect(friend.userId, 'u100');
      expect(friend.username, 'bob');
      expect(friend.displayName, 'Bob Builder');
      expect(friend.createdAt, '2024-01-01T00:00:00Z');

      final serialized = friend.toJson();
      expect(serialized['user_id'], 'u100');
      expect(serialized['username'], 'bob');
    });

    test('FriendRequestItem deserialization from flat or nested map', () {
      final flatJson = {
        'id': 'req_1',
        'user_id': 'u200',
        'username': 'charlie',
        'display_name': 'Charlie Chaplin',
        'requested_at': '2024-03-01T12:00:00Z',
        'status': 'pending',
      };

      final item = FriendRequestItem.fromJson(flatJson);
      expect(item.requestId, 'req_1');
      expect(item.userId, 'u200');
      expect(item.username, 'charlie');
      expect(item.displayName, 'Charlie Chaplin');

      final nestedJson = {
        'request_id': 'req_2',
        'user': {
          'user_id': 'u300',
          'username': 'david',
          'display_name': 'David Guetta',
        },
        'created_at': '2024-03-02T12:00:00Z',
      };

      final item2 = FriendRequestItem.fromJson(nestedJson);
      expect(item2.requestId, 'req_2');
      expect(item2.userId, 'u300');
      expect(item2.username, 'david');
    });

    test('FriendshipStatusData deserialization', () {
      final json = {
        'status': 'accepted',
        'request_id': 'req_99',
      };

      final data = FriendshipStatusData.fromJson(json);
      expect(data.status, FriendshipStatus.accepted);
      expect(data.requestId, 'req_99');
    });
  });
}
