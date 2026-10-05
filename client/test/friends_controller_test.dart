import 'package:client/features/friends/data/models/friend_models.dart';
import 'package:client/features/friends/data/services/friend_api_service.dart';
import 'package:client/features/friends/presentation/controllers/friends_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class MockFriendApiService implements IFriendApiService {
  List<FriendUser> friendsList = [];
  bool shouldFail = false;

  @override
  Future<List<FriendUser>> getFriends({required String token, int page = 1, int pageSize = 50}) async {
    if (shouldFail) throw Exception('Failed to get friends');
    return friendsList;
  }

  @override
  Future<void> unfriend({required String friendId, required String token}) async {
    if (shouldFail) throw Exception('Failed to unfriend');
    friendsList.removeWhere((f) => f.userId == friendId);
  }

  @override
  Future<void> acceptFriendRequest({required String requestId, required String token}) async {}
  @override
  Future<void> cancelFriendRequest({required String requestId, required String token}) async {}
  @override
  Future<FriendshipStatusData> getFriendshipStatus({required String userId, required String token}) async =>
      const FriendshipStatusData(status: FriendshipStatus.none);
  @override
  Future<List<FriendRequestItem>> getReceivedFriendRequests({required String token, int page = 1, int pageSize = 50}) async => [];
  @override
  Future<List<FriendRequestItem>> getSentFriendRequests({required String token, int page = 1, int pageSize = 50}) async => [];
  @override
  Future<void> rejectFriendRequest({required String requestId, required String token}) async {}
  @override
  Future<FriendRequestItem> sendFriendRequest({String? friendId, String? friendUsername, required String token}) async =>
      FriendRequestItem(requestId: 'r1', userId: friendId ?? '', username: friendUsername ?? '', displayName: '', requestedAt: '');
}

void main() {
  group('FriendsController Tests', () {
    late MockFriendApiService apiService;
    late FriendsController controller;

    setUp(() {
      apiService = MockFriendApiService();
      controller = FriendsController(friendService: apiService);
    });

    tearDown(() {
      controller.dispose();
    });

    test('fetchFriends populates list', () async {
      apiService.friendsList = [
        const FriendUser(userId: 'u1', username: 'john', displayName: 'John Doe'),
        const FriendUser(userId: 'u2', username: 'alice', displayName: 'Alice Wonder'),
      ];

      await controller.fetchFriends(token: 'valid_token');

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.friendCount, 2);
      expect(controller.friends.length, 2);
    });

    test('filter filters friends by display name and username', () async {
      apiService.friendsList = [
        const FriendUser(userId: 'u1', username: 'john123', displayName: 'John Doe'),
        const FriendUser(userId: 'u2', username: 'alice', displayName: 'Alice Wonder'),
      ];
      await controller.fetchFriends(token: 'token');

      controller.filter('ali');
      expect(controller.filteredFriends.length, 1);
      expect(controller.filteredFriends.first.username, 'alice');

      controller.filter('123');
      expect(controller.filteredFriends.length, 1);
      expect(controller.filteredFriends.first.username, 'john123');
    });

    test('unfriend removes friend from list', () async {
      apiService.friendsList = [
        const FriendUser(userId: 'u1', username: 'john', displayName: 'John Doe'),
      ];
      await controller.fetchFriends(token: 'token');
      expect(controller.friendCount, 1);

      final success = await controller.unfriend(friendId: 'u1', token: 'token');
      expect(success, isTrue);
      expect(controller.friendCount, 0);
    });
  });
}
