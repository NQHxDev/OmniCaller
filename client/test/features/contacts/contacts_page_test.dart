import 'package:client/core/auth/auth_controller.dart';
import 'package:client/core/auth/auth_scope.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/services/auth_api_service.dart';
import 'package:client/features/contacts/presentation/pages/contacts_page.dart';
import 'package:client/features/friends/data/models/friend_models.dart';
import 'package:client/features/friends/data/services/friend_api_service.dart';
import 'package:client/features/friends/presentation/controllers/friend_requests_controller.dart';
import 'package:client/features/friends/presentation/controllers/friends_controller.dart';
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

class FakeFriendApiService implements IFriendApiService {
  List<FriendUser> friends = [];
  List<FriendRequestItem> received = [];

  @override
  Future<List<FriendUser>> getFriends({required String token, int page = 1, int pageSize = 50}) async => friends;
  @override
  Future<List<FriendRequestItem>> getReceivedFriendRequests({required String token, int page = 1, int pageSize = 50}) async => received;
  @override
  Future<List<FriendRequestItem>> getSentFriendRequests({required String token, int page = 1, int pageSize = 50}) async => [];
  @override
  Future<void> acceptFriendRequest({required String requestId, required String token}) async {}
  @override
  Future<void> rejectFriendRequest({required String requestId, required String token}) async {}
  @override
  Future<void> cancelFriendRequest({required String requestId, required String token}) async {}
  @override
  Future<FriendRequestItem> sendFriendRequest({String? friendId, String? friendUsername, required String token}) async =>
      FriendRequestItem(requestId: 'r1', userId: friendId ?? '', username: friendUsername ?? '', displayName: '', requestedAt: '');
  @override
  Future<void> unfriend({required String friendId, required String token}) async {}
  @override
  Future<FriendshipStatusData> getFriendshipStatus({required String userId, required String token}) async =>
      const FriendshipStatusData(status: FriendshipStatus.none);
}

void main() {
  late AuthController authController;
  late FakeFriendApiService apiService;

  setUp(() async {
    authController = AuthController(authService: StubAuthApiService(), tokenStorage: StubTokenStorage());
    await authController.initialize();

    apiService = FakeFriendApiService();
    apiService.friends = [
      const FriendUser(
        userId: 'u_friend_1',
        username: 'charlie',
        displayName: 'Charlie Puth',
      ),
    ];
    apiService.received = [
      const FriendRequestItem(
        requestId: 'r_1',
        userId: 'u_req_1',
        username: 'david',
        displayName: 'David',
        requestedAt: '2024-01-01',
      ),
    ];
  });

  testWidgets('ContactsPage displays friend list and pending requests badge', (WidgetTester tester) async {
    final friendsCtrl = FriendsController(friendService: apiService);
    final requestsCtrl = FriendRequestsController(friendService: apiService);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          controller: authController,
          child: ContactsPage(
            friendsController: friendsCtrl,
            requestsController: requestsCtrl,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Quản lý nhóm'), findsOneWidget);
    expect(find.text('Lời mời kết bạn'), findsOneWidget);
    expect(find.text('Danh bạ (1)'), findsOneWidget);
    expect(find.text('Charlie Puth'), findsOneWidget);
    expect(find.text('@charlie'), findsOneWidget);

    // Pending requests badge
    expect(find.text('1'), findsWidgets);
  });
}
