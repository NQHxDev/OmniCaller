import 'package:client/features/friends/data/models/friend_models.dart';
import 'package:client/features/friends/data/services/friend_api_service.dart';
import 'package:client/features/friends/presentation/controllers/friend_requests_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class MockFriendRequestsApiService implements IFriendApiService {
  List<FriendRequestItem> received = [];
  List<FriendRequestItem> sent = [];
  bool shouldFail = false;

  @override
  Future<List<FriendRequestItem>> getReceivedFriendRequests({required String token, int page = 1, int pageSize = 50}) async {
    if (shouldFail) throw Exception('Failed to get received');
    return received;
  }

  @override
  Future<List<FriendRequestItem>> getSentFriendRequests({required String token, int page = 1, int pageSize = 50}) async {
    if (shouldFail) throw Exception('Failed to get sent');
    return sent;
  }

  @override
  Future<void> acceptFriendRequest({required String requestId, required String token}) async {
    if (shouldFail) throw Exception('Failed to accept');
    received.removeWhere((r) => r.requestId == requestId);
  }

  @override
  Future<void> rejectFriendRequest({required String requestId, required String token}) async {
    if (shouldFail) throw Exception('Failed to reject');
    received.removeWhere((r) => r.requestId == requestId);
  }

  @override
  Future<void> cancelFriendRequest({required String requestId, required String token}) async {
    if (shouldFail) throw Exception('Failed to cancel');
    sent.removeWhere((r) => r.requestId == requestId);
  }

  @override
  Future<FriendRequestItem> sendFriendRequest({String? friendId, String? friendUsername, required String token}) async {
    if (shouldFail) throw Exception('Failed to send');
    final item = FriendRequestItem(
      requestId: 'req_new_${friendId ?? friendUsername}',
      userId: friendId ?? '',
      username: friendUsername ?? 'target',
      displayName: 'Target User',
      requestedAt: DateTime.now().toIso8601String(),
    );
    sent.add(item);
    return item;
  }

  @override
  Future<void> unfriend({required String friendId, required String token}) async {}
  @override
  Future<List<FriendUser>> getFriends({required String token, int page = 1, int pageSize = 50}) async => [];
  @override
  Future<FriendshipStatusData> getFriendshipStatus({required String userId, required String token}) async =>
      const FriendshipStatusData(status: FriendshipStatus.none);
}

void main() {
  group('FriendRequestsController Tests', () {
    late MockFriendRequestsApiService apiService;
    late FriendRequestsController controller;

    setUp(() {
      apiService = MockFriendRequestsApiService();
      controller = FriendRequestsController(friendService: apiService);
    });

    tearDown(() {
      controller.dispose();
    });

    test('fetchRequests loads both received and sent requests', () async {
      apiService.received = [
        const FriendRequestItem(
          requestId: 'r1',
          userId: 'u1',
          username: 'anna',
          displayName: 'Anna',
          requestedAt: '2024-01-01',
        ),
      ];
      apiService.sent = [
        const FriendRequestItem(
          requestId: 'r2',
          userId: 'u2',
          username: 'ben',
          displayName: 'Ben',
          requestedAt: '2024-01-02',
        ),
      ];

      await controller.fetchRequests(token: 'token');

      expect(controller.isLoading, isFalse);
      expect(controller.receivedRequests.length, 1);
      expect(controller.sentRequests.length, 1);
      expect(controller.pendingCount, 1);
    });

    test('acceptRequest removes from received', () async {
      apiService.received = [
        const FriendRequestItem(
          requestId: 'r1',
          userId: 'u1',
          username: 'anna',
          displayName: 'Anna',
          requestedAt: '2024-01-01',
        ),
      ];
      await controller.fetchRequests(token: 'token');

      final ok = await controller.acceptRequest(requestId: 'r1', token: 'token');
      expect(ok, isTrue);
      expect(controller.receivedRequests.isEmpty, isTrue);
      expect(controller.pendingCount, 0);
    });

    test('rejectRequest removes from received', () async {
      apiService.received = [
        const FriendRequestItem(
          requestId: 'r1',
          userId: 'u1',
          username: 'anna',
          displayName: 'Anna',
          requestedAt: '2024-01-01',
        ),
      ];
      await controller.fetchRequests(token: 'token');

      final ok = await controller.rejectRequest(requestId: 'r1', token: 'token');
      expect(ok, isTrue);
      expect(controller.receivedRequests.isEmpty, isTrue);
    });

    test('cancelRequest removes from sent', () async {
      apiService.sent = [
        const FriendRequestItem(
          requestId: 'r2',
          userId: 'u2',
          username: 'ben',
          displayName: 'Ben',
          requestedAt: '2024-01-02',
        ),
      ];
      await controller.fetchRequests(token: 'token');

      final ok = await controller.cancelRequest(requestId: 'r2', token: 'token');
      expect(ok, isTrue);
      expect(controller.sentRequests.isEmpty, isTrue);
    });

    test('sendRequest adds to sent requests', () async {
      final ok = await controller.sendRequest(friendId: 'u9', token: 'token');
      expect(ok, isTrue);
      expect(controller.sentRequests.length, 1);
      expect(controller.sentRequests.first.userId, 'u9');
    });
  });
}
