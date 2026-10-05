import 'dart:async';
import 'package:client/core/auth/auth_controller.dart';
import 'package:client/core/auth/auth_scope.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/services/auth_api_service.dart';
import 'package:client/features/chat/data/models/chat_models.dart';
import 'package:client/features/chat/data/models/ws_models.dart';
import 'package:client/features/chat/data/services/chat_api_service.dart';
import 'package:client/features/chat/data/services/chat_websocket_service.dart';
import 'package:client/features/chat/presentation/controllers/conversations_controller.dart';
import 'package:client/features/chat/presentation/pages/chat_page.dart';
import 'package:client/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:client/features/chat/presentation/widgets/chat_message_bubble.dart';
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
      const FriendshipStatusData(status: FriendshipStatus.accepted);
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

class StubChatApiService implements IChatApiService {
  List<ConversationModel> conversationsToReturn = [];
  List<MessageModel> messagesToReturn = [];

  @override
  Future<ConversationModel> createOrGetDirectConversation({required String friendUsername, required String token}) async {
    return ConversationModel(
      id: 'conv_123',
      type: ConversationType.direct,
      otherUser: ConversationUser(userId: 'u_123', username: friendUsername, displayName: 'Alice Wonderland'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<ConversationModel>> getConversations({required String token}) async => conversationsToReturn;

  @override
  Future<MessagesResponse> getMessages({required String conversationId, required String token, String? cursor, int limit = 30}) async {
    return MessagesResponse(messages: messagesToReturn, nextCursor: null, hasMore: false);
  }

  @override
  Future<MessageModel> sendMessage({required String conversationId, required String content, String? replyToMessageId, required String token}) async {
    return MessageModel(
      id: 'm_sent_1',
      conversationId: conversationId,
      senderId: 'u_me',
      senderUsername: 'me',
      senderDisplayName: 'Me',
      content: content,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class StubChatWebSocketService implements IChatWebSocketService {
  final StreamController<WsServerEvent> _streamController = StreamController<WsServerEvent>.broadcast();
  bool connected = false;

  @override
  Stream<WsServerEvent> get events => _streamController.stream;

  @override
  bool get isConnected => connected;

  @override
  Future<void> connect({required String token}) async {
    connected = true;
  }

  @override
  void disconnect() {
    connected = false;
  }

  @override
  void dispose() {
    _streamController.close();
  }

  @override
  void send(WsClientEvent event) {}

  void emit(WsServerEvent event) {
    _streamController.add(event);
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

  testWidgets('ChatPage renders recipient info in AppBar and navigates to UserProfilePage on tap, tapping message pops back without loop', (WidgetTester tester) async {
    final stubFriendService = StubFriendApiService();
    final stubUserSearchService = StubUserSearchApiService();
    final stubChatApiService = StubChatApiService();
    final stubWsService = StubChatWebSocketService();

    await tester.pumpWidget(
      AuthScope(
        controller: authController,
        child: MaterialApp(
          home: ChatPage(
            userId: 'u_123',
            username: 'alice',
            displayName: 'Alice Wonderland',
            userApiService: stubUserSearchService,
            friendApiService: stubFriendService,
            chatApiService: stubChatApiService,
            wsService: stubWsService,
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

    // Tap "Nhắn tin" in UserProfilePage -> should pop back to existing ChatPage without pushing a new one
    final sendMessageBtn = find.widgetWithText(FilledButton, 'Nhắn tin');
    expect(sendMessageBtn, findsOneWidget);
    await tester.tap(sendMessageBtn);
    await tester.pumpAndSettle();

    // Verify we are back on ChatPage
    expect(find.byType(UserProfilePage), findsNothing);
    expect(find.byType(ChatPage), findsOneWidget);
  });

  testWidgets('ChatPage displays messages and sends a new message with bubble UI', (WidgetTester tester) async {
    final stubChatApiService = StubChatApiService();
    final stubWsService = StubChatWebSocketService();

    stubChatApiService.messagesToReturn = [
      MessageModel(
        id: 'msg_1',
        conversationId: 'conv_123',
        senderId: 'u_123',
        senderUsername: 'alice',
        senderDisplayName: 'Alice Wonderland',
        content: 'Chào bạn nhé!',
        status: MessageStatus.read,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      AuthScope(
        controller: authController,
        child: MaterialApp(
          home: ChatPage(
            conversationId: 'conv_123',
            userId: 'u_123',
            username: 'alice',
            displayName: 'Alice Wonderland',
            chatApiService: stubChatApiService,
            wsService: stubWsService,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial message rendered in bubble
    expect(find.text('Chào bạn nhé!'), findsOneWidget);
    expect(find.byType(ChatMessageBubble), findsOneWidget);

    // Type a reply
    await tester.enterText(find.byType(TextField), 'Chào Alice!');
    await tester.pump();

    // Tap send button
    await tester.tap(find.byTooltip('Gửi tin nhắn'));
    await tester.pump();

    // Verify both messages are in the UI
    expect(find.text('Chào Alice!'), findsOneWidget);
  });

  testWidgets('MessagesPage renders active conversations and new friends', (WidgetTester tester) async {
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

    final stubChatApiService = StubChatApiService();
    stubChatApiService.conversationsToReturn = [
      ConversationModel(
        id: 'conv_alice',
        type: ConversationType.direct,
        otherUser: const ConversationUser(userId: 'u_alice', username: 'alice', displayName: 'Alice'),
        lastMessage: MessageModel(
          id: 'm1',
          conversationId: 'conv_alice',
          senderId: 'u_alice',
          senderUsername: 'alice',
          senderDisplayName: 'Alice',
          content: 'Gặp nhau nhé!',
          status: MessageStatus.sent,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        unreadCount: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final friendsController = FriendsController(friendService: stubFriendService);
    final conversationsController = ConversationsController(
      apiService: stubChatApiService,
      wsService: StubChatWebSocketService(),
    );

    await tester.pumpWidget(
      AuthScope(
        controller: authController,
        child: MaterialApp(
          home: MessagesPage(
            friendsController: friendsController,
            conversationsController: conversationsController,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Active conversation
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Alice: Gặp nhau nhé!'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // unread badge

    // New friend
    expect(find.text('Bob The Builder'), findsOneWidget);
    expect(find.text('Bạn mới'), findsOneWidget);
  });
}
