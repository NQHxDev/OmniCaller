import 'package:client/core/auth/auth_controller.dart';
import 'package:client/core/auth/auth_scope.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/services/auth_api_service.dart';
import 'package:client/features/friends/data/models/friend_models.dart';
import 'package:client/features/friends/data/services/friend_api_service.dart';
import 'package:client/features/friends/presentation/controllers/friends_controller.dart';
import 'package:client/features/groups/presentation/pages/create_group_page.dart';
import 'package:client/features/messages/presentation/pages/messages_page.dart';
import 'package:client/features/search/data/models/user_search_models.dart';
import 'package:client/features/search/data/services/user_search_api_service.dart';
import 'package:client/features/search/presentation/controllers/user_search_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

class StubAuthApiService implements IAuthApiService {
  @override
  Future<AuthResponseDto> login({required String username, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout(String token) async {}

  @override
  Future<AuthResponseDto> register({required String displayName, required String username, required String password, required String confirmPassword}) async {
    throw UnimplementedError();
  }

  @override
  Future<RefreshTokenResponseDto> refreshToken(String refreshToken) async {
    return const RefreshTokenResponseDto(accessToken: 'stub_refreshed_access_token', refreshToken: 'stub_refreshed_refresh_token');
  }
}

class StubTokenStorage implements ITokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> getAccessToken() async => 'fake_access_token';
  @override
  Future<String?> getRefreshToken() async => 'fake_refresh_token';
  @override
  Future<AuthSessionData?> loadSession() async => const AuthSessionData(
    userId: 'usr_1',
    username: 'current_user',
    displayName: 'Current User',
    accessToken: 'fake_access_token',
    refreshToken: 'fake_refresh_token',
  );
  @override
  Future<void> saveSession({
    required String userId,
    required String username,
    required String displayName,
    required String accessToken,
    required String refreshToken,
  }) async {}
}

class StubUserSearchApiService implements IUserSearchApiService {
  @override
  Future<SearchUsersResponse> searchUsers({required String query, required String token, int page = 1, int pageSize = 10}) async {
    return const SearchUsersResponse(users: [], pagination: SearchPagination(currentPage: 1, pageSize: 10, totalItems: 0, totalPages: 0));
  }

  @override
  Future<UserPublicProfile> getUserProfile({required String username, required String token}) async {
    throw UnimplementedError();
  }
}

class StubFriendApiService implements IFriendApiService {
  @override
  Future<List<FriendUser>> getFriends({required String token, int page = 1, int pageSize = 50}) async {
    return [
      const FriendUser(userId: 'u1', username: 'alice', displayName: 'Alice Nguyen', createdAt: '2024-01-01'),
      const FriendUser(userId: 'u2', username: 'bob', displayName: 'Bob Tran', createdAt: '2024-01-02'),
      const FriendUser(userId: 'u3', username: 'charlie', displayName: 'Charlie Le', createdAt: '2024-01-03'),
    ];
  }

  @override
  Future<List<FriendRequestItem>> getReceivedFriendRequests({required String token, int page = 1, int pageSize = 50}) async {
    return [];
  }

  @override
  Future<List<FriendRequestItem>> getSentFriendRequests({required String token, int page = 1, int pageSize = 50}) async {
    return [];
  }

  @override
  Future<FriendRequestItem> sendFriendRequest({String? friendId, String? friendUsername, required String token}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> acceptFriendRequest({required String requestId, required String token}) async {}

  @override
  Future<void> rejectFriendRequest({required String requestId, required String token}) async {}

  @override
  Future<void> cancelFriendRequest({required String requestId, required String token}) async {}

  @override
  Future<void> unfriend({required String friendId, required String token}) async {}

  @override
  Future<FriendshipStatusData> getFriendshipStatus({required String userId, required String token}) async {
    return const FriendshipStatusData(status: FriendshipStatus.none);
  }
}

void main() {
  late AuthController authController;

  setUp(() async {
    authController = AuthController(authService: StubAuthApiService(), tokenStorage: StubTokenStorage());
    await authController.initialize();
  });

  testWidgets('Clicking Create Group from MessagesPage menu opens CreateGroupPage with header, inputs, and friend list', (WidgetTester tester) async {
    final searchController = UserSearchController(searchService: StubUserSearchApiService());

    await tester.pumpWidget(
      AuthScope(
        controller: authController,
        child: MaterialApp(home: MessagesPage(searchController: searchController)),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on the plus icon button to open popup menu
    final addIconButton = find.byWidgetPredicate((widget) => widget is HugeIcon && widget.icon == HugeIcons.strokeRoundedAdd01);
    expect(addIconButton, findsOneWidget);
    await tester.tap(addIconButton);
    await tester.pumpAndSettle();

    // Verify popup menu items are shown
    expect(find.text('Tạo nhóm'), findsOneWidget);

    // Tap on "Tạo nhóm"
    await tester.tap(find.text('Tạo nhóm'));
    await tester.pumpAndSettle();

    // Verify CreateGroupPage is displayed with "Nhóm mới" and "Đã mời: 0"
    expect(find.byType(CreateGroupPage), findsOneWidget);
    expect(find.text('Nhóm mới'), findsOneWidget);
    expect(find.text('Đã mời: 0'), findsOneWidget);

    // Verify Create button in header is present and disabled
    final createBtnFinder = find.widgetWithText(TextButton, 'Tạo mới');
    expect(createBtnFinder, findsOneWidget);
    final TextButton initialBtn = tester.widget(createBtnFinder);
    expect(initialBtn.onPressed, isNull);

    // Verify group name input and placeholder
    expect(find.text('Đặt tên nhóm'), findsOneWidget);

    // Verify avatar picker camera icon
    expect(find.byWidgetPredicate((widget) => widget is HugeIcon && widget.icon == HugeIcons.strokeRoundedCamera01), findsOneWidget);

    // Verify friends list section header
    expect(find.text('Danh sách bạn bè'), findsOneWidget);

    // Pop back to MessagesPage
    final backButton = find.byType(BackButton);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.byType(CreateGroupPage), findsNothing);
    expect(find.byType(MessagesPage), findsOneWidget);
  });

  testWidgets('CreateGroupPage allows typing group name and selecting friends which updates invited count', (WidgetTester tester) async {
    final friendsController = FriendsController(friendService: StubFriendApiService());

    await tester.pumpWidget(
      AuthScope(
        controller: authController,
        child: MaterialApp(home: CreateGroupPage(friendsController: friendsController)),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and initial count
    expect(find.text('Nhóm mới'), findsOneWidget);
    expect(find.text('Đã mời: 0'), findsOneWidget);

    // Enter group name
    await tester.enterText(find.widgetWithText(TextField, 'Đặt tên nhóm'), 'Team Dev OmniCaller');
    await tester.pumpAndSettle();
    expect(find.text('Team Dev OmniCaller'), findsOneWidget);

    // Check friends list items
    expect(find.text('Alice Nguyen'), findsOneWidget);
    expect(find.text('Bob Tran'), findsOneWidget);

    // Tap on Alice Nguyen to select
    await tester.tap(find.text('Alice Nguyen'));
    await tester.pumpAndSettle();

    // Verify invited count is now 1
    expect(find.text('Đã mời: 1'), findsOneWidget);

    // Tap on Bob Tran to select
    await tester.tap(find.text('Bob Tran'));
    await tester.pumpAndSettle();

    // Verify invited count is now 2
    expect(find.text('Đã mời: 2'), findsOneWidget);

    // Tap on Alice Nguyen again to deselect
    await tester.tap(find.text('Alice Nguyen'));
    await tester.pumpAndSettle();

    // Verify invited count is back to 1
    expect(find.text('Đã mời: 1'), findsOneWidget);
  });

  testWidgets('Create group button is disabled until group name is entered AND at least 2 members are selected', (WidgetTester tester) async {
    final friendsController = FriendsController(friendService: StubFriendApiService());

    String? createdGroupName;
    List<String>? createdMemberIds;

    await tester.pumpWidget(
      AuthScope(
        controller: authController,
        child: MaterialApp(
          home: CreateGroupPage(
            friendsController: friendsController,
            onCreateGroup: (name, memberIds) {
              createdGroupName = name;
              createdMemberIds = memberIds;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final createButtonFinder = find.widgetWithText(TextButton, 'Tạo mới');
    expect(createButtonFinder, findsOneWidget);

    // 1. Initial state: both conditions unmet -> disabled
    TextButton btn = tester.widget(createButtonFinder);
    expect(btn.onPressed, isNull);

    // 2. Only enter group name -> still disabled
    await tester.enterText(find.widgetWithText(TextField, 'Đặt tên nhóm'), 'OmniCaller Team');
    await tester.pumpAndSettle();
    btn = tester.widget(createButtonFinder);
    expect(btn.onPressed, isNull);

    // 3. Select 1 friend (Alice) -> still disabled (< 2 members)
    await tester.tap(find.text('Alice Nguyen'));
    await tester.pumpAndSettle();
    btn = tester.widget(createButtonFinder);
    expect(btn.onPressed, isNull);

    // 4. Select 2nd friend (Bob) -> now enabled!
    await tester.tap(find.text('Bob Tran'));
    await tester.pumpAndSettle();
    btn = tester.widget(createButtonFinder);
    expect(btn.onPressed, isNotNull);

    // 5. Tap create button -> callback invoked
    await tester.tap(createButtonFinder);
    await tester.pumpAndSettle();
    expect(createdGroupName, 'OmniCaller Team');
    expect(createdMemberIds, containsAll(['u1', 'u2']));

    // 6. Clear group name -> disabled again
    await tester.enterText(find.widgetWithText(TextField, 'Đặt tên nhóm'), '   ');
    await tester.pumpAndSettle();
    btn = tester.widget(createButtonFinder);
    expect(btn.onPressed, isNull);

    // 7. Re-enter group name -> enabled again
    await tester.enterText(find.widgetWithText(TextField, 'Đặt tên nhóm'), 'Dev Gang');
    await tester.pumpAndSettle();
    btn = tester.widget(createButtonFinder);
    expect(btn.onPressed, isNotNull);

    // 8. Deselect Bob (back to 1 member) -> disabled again
    await tester.tap(find.text('Bob Tran'));
    await tester.pumpAndSettle();
    btn = tester.widget(createButtonFinder);
    expect(btn.onPressed, isNull);

    // 9. Select Charlie Le (now Alice and Charlie = 2 members) -> enabled again
    await tester.tap(find.text('Charlie Le'));
    await tester.pumpAndSettle();
    btn = tester.widget(createButtonFinder);
    expect(btn.onPressed, isNotNull);

    // Tap again to confirm callback payload
    await tester.tap(createButtonFinder);
    await tester.pumpAndSettle();
    expect(createdGroupName, 'Dev Gang');
    expect(createdMemberIds, containsAll(['u1', 'u3']));
  });
}
