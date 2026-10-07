import 'package:client/core/auth/auth_controller.dart';
import 'package:client/core/auth/auth_scope.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/services/auth_api_service.dart';
import 'package:client/features/contacts/presentation/pages/friend_requests_page.dart';
import 'package:client/features/friends/data/models/friend_models.dart';
import 'package:client/features/friends/data/services/friend_api_service.dart';
import 'package:client/features/friends/presentation/controllers/friend_requests_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class StubAuthApiService implements IAuthApiService {
  @override
  Future<AuthResponseDto> login({required String username, required String password}) async => throw UnimplementedError();
  @override
  Future<void> logout(String token) async {}
  @override
  Future<AuthResponseDto> register({required String displayName, required String username, required String password, required String confirmPassword}) async => throw UnimplementedError();
  @override
  Future<RefreshTokenResponseDto> refreshToken(String refreshToken) async => const RefreshTokenResponseDto(accessToken: 'token', refreshToken: 'ref_token');
}

class StubTokenStorage implements ITokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> getAccessToken() async => 'test_token';
  @override
  Future<String?> getRefreshToken() async => 'test_ref_token';
  @override
  Future<AuthSessionData?> loadSession() async => const AuthSessionData(userId: 'u1', username: 'me', displayName: 'Me', accessToken: 'test_token', refreshToken: 'test_ref_token');
  @override
  Future<void> saveSession({required String userId, required String username, required String displayName, required String accessToken, required String refreshToken}) async {}
}

class FakeFriendRequestsApiService implements IFriendApiService {
  List<FriendRequestItem> received = [];
  List<FriendRequestItem> sent = [];

  @override
  Future<List<FriendRequestItem>> getReceivedFriendRequests({required String token, int page = 1, int pageSize = 50}) async => received;
  @override
  Future<List<FriendRequestItem>> getSentFriendRequests({required String token, int page = 1, int pageSize = 50}) async => sent;
  @override
  Future<void> acceptFriendRequest({required String requestId, required String token}) async {
    received.removeWhere((r) => r.requestId == requestId);
  }
  @override
  Future<void> rejectFriendRequest({required String requestId, required String token}) async {
    received.removeWhere((r) => r.requestId == requestId);
  }
  @override
  Future<void> cancelFriendRequest({required String requestId, required String token}) async {
    sent.removeWhere((r) => r.requestId == requestId);
  }
  @override
  Future<FriendRequestItem> sendFriendRequest({String? friendId, String? friendUsername, required String token}) async =>
      FriendRequestItem(requestId: 'r1', userId: friendId ?? '', username: friendUsername ?? '', displayName: '', requestedAt: '');
  @override
  Future<void> unfriend({required String friendId, required String token}) async {}
  @override
  Future<List<FriendUser>> getFriends({required String token, int page = 1, int pageSize = 50}) async => [];
  @override
  Future<FriendshipStatusData> getFriendshipStatus({required String userId, required String token}) async =>
      const FriendshipStatusData(status: FriendshipStatus.none);
}

void main() {
  late AuthController authController;
  late FakeFriendRequestsApiService fakeApiService;
  late FriendRequestsController controller;

  setUp(() async {
    authController = AuthController(authService: StubAuthApiService(), tokenStorage: StubTokenStorage());
    await authController.initialize();

    fakeApiService = FakeFriendRequestsApiService();
    fakeApiService.received = [
      const FriendRequestItem(
        requestId: 'req_rec_1',
        userId: 'u2',
        username: 'alice',
        displayName: 'Alice Wonderland',
        requestedAt: '2024-01-01',
      ),
    ];
    fakeApiService.sent = [
      const FriendRequestItem(
        requestId: 'req_sent_1',
        userId: 'u3',
        username: 'bob',
        displayName: 'Bob Builder',
        requestedAt: '2024-01-02',
      ),
    ];

    controller = FriendRequestsController(friendService: fakeApiService);
  });

  testWidgets('FriendRequestsPage displays received requests, accepts and switches to sent tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          controller: authController,
          child: FriendRequestsPage(controller: controller),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Received Tab
    expect(find.text('Alice Wonderland'), findsOneWidget);
    expect(find.text('@alice'), findsOneWidget);
    expect(find.text('Đồng ý'), findsOneWidget);
    expect(find.text('Xóa'), findsOneWidget);

    // Accept request
    await tester.tap(find.text('Đồng ý'));
    await tester.pumpAndSettle();

    expect(find.text('Alice Wonderland'), findsNothing);
    expect(find.text('Không có lời mời kết bạn nào'), findsOneWidget);

    // Switch to Sent Tab
    await tester.tap(find.text('Đã gửi'));
    await tester.pumpAndSettle();

    expect(find.text('Bob Builder'), findsOneWidget);
    expect(find.text('@bob'), findsOneWidget);
    expect(find.text('Hủy'), findsOneWidget);

    // Cancel sent request
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(find.text('Bob Builder'), findsNothing);
    expect(find.text('Không có lời mời đã gửi'), findsOneWidget);
  });
}
