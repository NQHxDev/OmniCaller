import 'package:client/core/auth/auth_controller.dart';
import 'package:client/core/auth/auth_scope.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/services/auth_api_service.dart';
import 'package:client/features/friends/data/models/friend_models.dart';
import 'package:client/features/friends/data/services/friend_api_service.dart';
import 'package:client/features/profile/presentation/pages/user_profile_page.dart';
import 'package:client/features/profile/presentation/widgets/user_profile_detail_view.dart';
import 'package:client/features/search/data/models/user_search_models.dart';
import 'package:client/features/search/data/services/user_search_api_service.dart';
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
  Future<String?> getAccessToken() async => 'fake_access_token';
  @override
  Future<String?> getRefreshToken() async => 'fake_refresh_token';
  @override
  Future<AuthSessionData?> loadSession() async => const AuthSessionData(userId: 'usr_me', username: 'current_user', displayName: 'Current User', accessToken: 'fake_access_token', refreshToken: 'fake_refresh_token');
  @override
  Future<void> saveSession({required String userId, required String username, required String displayName, required String accessToken, required String refreshToken}) async {}
}

class MockUserSearchApiService implements IUserSearchApiService {
  bool shouldThrow = false;
  UserPublicProfile? profileToReturn;

  @override
  Future<SearchUsersResponse> searchUsers({required String query, required String token, int page = 1, int pageSize = 10}) async =>
      const SearchUsersResponse(users: [], pagination: SearchPagination(currentPage: 1, pageSize: 10, totalItems: 0, totalPages: 0));

  @override
  Future<UserPublicProfile> getUserProfile({required String username, required String token}) async {
    if (shouldThrow) throw Exception('User not found');
    return profileToReturn ??
        UserPublicProfile(
          userId: 'u_test_999',
          username: username,
          displayName: 'Test $username',
          createdAt: '2024-10-01 10:30:45.123456 +00:00',
        );
  }
}

class MockFriendApiService implements IFriendApiService {
  FriendshipStatus statusToReturn = FriendshipStatus.none;
  bool sendCalled = false;
  bool cancelCalled = false;
  bool unfriendCalled = false;

  @override
  Future<FriendshipStatusData> getFriendshipStatus({required String userId, required String token}) async =>
      FriendshipStatusData(status: statusToReturn);

  @override
  Future<FriendRequestItem> sendFriendRequest({String? friendId, String? friendUsername, required String token}) async {
    sendCalled = true;
    return FriendRequestItem(requestId: 'req_new', userId: friendId ?? '', username: friendUsername ?? '', displayName: '', requestedAt: '');
  }

  @override
  Future<void> cancelFriendRequest({required String requestId, required String token}) async {
    cancelCalled = true;
  }

  @override
  Future<void> unfriend({required String friendId, required String token}) async {
    unfriendCalled = true;
  }

  @override
  Future<void> acceptFriendRequest({required String requestId, required String token}) async {}
  @override
  Future<List<FriendUser>> getFriends({required String token, int page = 1, int pageSize = 50}) async => [];
  @override
  Future<List<FriendRequestItem>> getReceivedFriendRequests({required String token, int page = 1, int pageSize = 50}) async => [];
  @override
  Future<List<FriendRequestItem>> getSentFriendRequests({required String token, int page = 1, int pageSize = 50}) async => [];
  @override
  Future<void> rejectFriendRequest({required String requestId, required String token}) async {}
}

void main() {
  late AuthController authController;
  late MockUserSearchApiService mockUserService;
  late MockFriendApiService mockFriendService;

  setUp(() async {
    authController = AuthController(authService: StubAuthApiService(), tokenStorage: StubTokenStorage());
    await authController.initialize();
    mockUserService = MockUserSearchApiService();
    mockFriendService = MockFriendApiService();
  });

  testWidgets('UserProfileDetailView renders profile details and action buttons', (WidgetTester tester) async {
    const profile = UserPublicProfile(
      userId: 'u_123',
      username: 'johndoe',
      displayName: 'John Doe',
      createdAt: '2024-05-15 12:00:00.000Z',
    );

    var addPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserProfileDetailView(
            profile: profile,
            onAddFriend: () => addPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('@johndoe'), findsOneWidget);
    expect(find.text('Ngày tham gia'), findsOneWidget);
    expect(find.text('15/05/2024'), findsOneWidget);
    expect(find.text('Kết bạn'), findsOneWidget);

    await tester.tap(find.text('Kết bạn'));
    expect(addPressed, isTrue);
  });

  testWidgets('UserProfilePage handles Add Friend and Send Request flow', (WidgetTester tester) async {
    mockUserService.profileToReturn = const UserPublicProfile(
      userId: 'u_456',
      username: 'alice',
      displayName: 'Alice Wonderland',
      createdAt: '2024-02-20 08:00:00.000Z',
    );
    mockFriendService.statusToReturn = FriendshipStatus.none;

    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          controller: authController,
          child: UserProfilePage(
            username: 'alice',
            userApiService: mockUserService,
            friendApiService: mockFriendService,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Alice Wonderland'), findsWidgets);
    expect(find.text('@alice'), findsWidgets);
    expect(find.text('Kết bạn'), findsOneWidget);

    // Tap Add Friend
    await tester.tap(find.text('Kết bạn'));
    await tester.pumpAndSettle();

    expect(mockFriendService.sendCalled, isTrue);
    expect(find.text('Hủy lời mời'), findsOneWidget);

    // Tap Cancel Request
    await tester.tap(find.text('Hủy lời mời'));
    await tester.pumpAndSettle();

    expect(mockFriendService.cancelCalled, isTrue);
    expect(find.text('Kết bạn'), findsOneWidget);
  });
}
