import 'package:client/core/auth/auth_controller.dart';
import 'package:client/core/auth/auth_scope.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/services/auth_api_service.dart';
import 'package:client/features/chat/presentation/pages/chat_page.dart';
import 'package:client/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:client/features/friends/data/models/friend_models.dart';
import 'package:client/features/friends/data/services/friend_api_service.dart';
import 'package:client/features/friends/presentation/controllers/friends_controller.dart';
import 'package:client/features/messages/presentation/pages/messages_page.dart';
import 'package:client/features/profile/presentation/pages/user_profile_page.dart';
import 'package:client/features/search/data/models/user_search_models.dart';
import 'package:client/features/search/data/services/user_search_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class StubAuthService implements IAuthApiService {
  @override
  Future<AuthResponseDto> login({required String username, required String password}) => throw UnimplementedError();
  @override
  Future<void> logout(String token) async {}
  @override
  Future<RefreshTokenResponseDto> refreshToken(String refreshToken) async =>
      const RefreshTokenResponseDto(accessToken: 'test_token', refreshToken: 'test_refresh_token');
  @override
  Future<AuthResponseDto> register({required String displayName, required String username, required String password, required String confirmPassword}) => throw UnimplementedError();
}

class StubTokenStorage implements ITokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> getAccessToken() async => 'test_token';
  @override
  Future<String?> getRefreshToken() async => 'test_refresh_token';
  @override
  Future<AuthSessionData?> loadSession() async => const AuthSessionData(
        userId: 'u_me',
        username: 'me',
        displayName: 'Me',
        accessToken: 'test_token',
        refreshToken: 'test_refresh_token',
      );
  @override
  Future<void> saveSession({required String userId, required String username, required String displayName, required String accessToken, required String refreshToken}) async {}
}

class StubFriendApiService implements IFriendApiService {
  List<FriendUser> friendsToReturn;

  StubFriendApiService({this.friendsToReturn = const []});

  @override
  Future<List<FriendUser>> getFriends({
    required String token,
    int page = 1,
    int pageSize = 50,
  }) async {
    return friendsToReturn;
  }

  @override
  Future<void> acceptFriendRequest({required String requestId, required String token}) async {}
  @override
  Future<void> cancelFriendRequest({required String requestId, required String token}) async {}
  @override
  Future<FriendshipStatusData> getFriendshipStatus({required String userId, required String token}) async =>
      const FriendshipStatusData(status: FriendshipStatus.none);
  @override
  Future<List<FriendRequestItem>> getReceivedFriendRequests({
    required String token,
    int page = 1,
    int pageSize = 50,
  }) async => [];
  @override
  Future<List<FriendRequestItem>> getSentFriendRequests({
    required String token,
    int page = 1,
    int pageSize = 50,
  }) async => [];
  @override
  Future<void> rejectFriendRequest({required String requestId, required String token}) async {}
  @override
  Future<FriendRequestItem> sendFriendRequest({String? friendId, String? friendUsername, required String token}) async =>
      throw UnimplementedError();
  @override
  Future<void> unfriend({required String friendId, required String token}) async {}
}

class StubUserSearchApiService implements IUserSearchApiService {
  @override
  Future<SearchUsersResponse> searchUsers({required String query, required String token, int page = 1, int pageSize = 10}) async {
    return const SearchUsersResponse(users: [], pagination: SearchPagination(currentPage: 1, pageSize: 10, totalItems: 0, totalPages: 0));
  }

  @override
  Future<UserPublicProfile> getUserProfile({required String username, required String token}) async {
    return UserPublicProfile(
      userId: 'u_123',
      username: username,
      displayName: 'Alice Wonderland',
      createdAt: '2026-01-01',
    );
  }
}

void main() {
  late AuthController authController;

  setUp(() async {
    authController = AuthController(
      authService: StubAuthService(),
      tokenStorage: StubTokenStorage(),
    );
    await authController.initialize();
  });

  testWidgets('ChatPage renders recipient info in AppBar and navigates to UserProfilePage on tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      AuthScope(
        controller: authController,
        child: const MaterialApp(
          home: ChatPage(
            userId: 'u_123',
            username: 'alice',
            displayName: 'Alice Wonderland',
          ),
        ),
      ),
    );

    expect(find.text('Alice Wonderland'), findsOneWidget);
    expect(find.text('@alice'), findsOneWidget);
    expect(find.byType(ChatPage), findsOneWidget);
    expect(find.byType(ChatInputBar), findsOneWidget);

    // Tap on Alice's name in the AppBar
    await tester.tap(find.text('Alice Wonderland'));
    await tester.pumpAndSettle();

    // Verify UserProfilePage is opened
    expect(find.byType(UserProfilePage), findsOneWidget);
  });

  testWidgets('ChatInputBar enters text and triggers onSendMessage callback', (WidgetTester tester) async {
    String? sentMessage;
    bool imageClicked = false;
    bool emojiClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(
            onSendMessage: (msg) => sentMessage = msg,
            onSendImage: () => imageClicked = true,
            onEmojiPressed: () => emojiClicked = true,
          ),
        ),
      ),
    );

    // Test send image click
    await tester.tap(find.byTooltip('Gửi ảnh'));
    await tester.pump();
    expect(imageClicked, isTrue);

    // Test emoji click
    await tester.tap(find.byTooltip('Thả icon / Emoji'));
    await tester.pump();
    expect(emojiClicked, isTrue);

    // Enter text
    await tester.enterText(find.byType(TextField), 'Hello World');
    await tester.pump();

    // Verify send button appears
    expect(find.byTooltip('Gửi tin nhắn'), findsOneWidget);

    // Tap send
    await tester.tap(find.byTooltip('Gửi tin nhắn'));
    await tester.pump();

    expect(sentMessage, equals('Hello World'));
  });

  testWidgets('MessagesPage renders newly accepted friend with "Bạn mới" badge and navigates to ChatPage on tap', (WidgetTester tester) async {
    final stubFriendService = StubFriendApiService(
      friendsToReturn: [
        const FriendUser(
          userId: 'f1',
          username: 'bob',
          displayName: 'Bob The Builder',
          respondedAt: '2026-10-04T12:00:00Z',
          isNewFriend: true,
        ),
      ],
    );

    final friendsController = FriendsController(friendService: stubFriendService);

    await tester.pumpWidget(
      AuthScope(
        controller: authController,
        child: MaterialApp(
          home: MessagesPage(friendsController: friendsController),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Bob is displayed in messages list
    expect(find.text('Bob The Builder'), findsOneWidget);
    expect(find.text('Bạn mới'), findsOneWidget);
    expect(find.textContaining('Các bạn đã trở thành bạn bè'), findsOneWidget);

    // Tap on Bob
    await tester.tap(find.text('Bob The Builder'));
    await tester.pumpAndSettle();

    // Verify ChatPage is opened with Bob
    expect(find.byType(ChatPage), findsOneWidget);
    expect(find.text('@bob'), findsOneWidget);
    expect(find.byType(ChatInputBar), findsOneWidget);
  });
}
