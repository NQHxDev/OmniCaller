import 'dart:async';
import 'package:client/features/chat/data/models/chat_models.dart';
import 'package:client/features/chat/data/models/ws_models.dart';
import 'package:client/features/chat/data/services/chat_api_service.dart';
import 'package:client/features/chat/data/services/chat_websocket_service.dart';
import 'package:client/features/chat/presentation/controllers/chat_controller.dart';
import 'package:client/features/chat/presentation/controllers/conversations_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeChatApiService implements IChatApiService {
  List<ConversationModel> conversations = [];
  List<MessageModel> messages = [];

  @override
  Future<ConversationModel> createOrGetDirectConversation({required String friendUsername, required String token}) async {
    return ConversationModel(
      id: 'conv_resolved',
      type: ConversationType.direct,
      otherUser: ConversationUser(userId: 'u_f', username: friendUsername, displayName: friendUsername),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<ConversationModel>> getConversations({required String token}) async => conversations;

  @override
  Future<MessagesResponse> getMessages({required String conversationId, required String token, String? cursor, int limit = 30}) async {
    return MessagesResponse(messages: messages, nextCursor: null, hasMore: false);
  }

  @override
  Future<MessageModel> sendMessage({required String conversationId, required String content, String? replyToMessageId, required String token}) async {
    return MessageModel(
      id: 'msg_rest_1',
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

class FakeChatWebSocketService implements IChatWebSocketService {
  final StreamController<WsServerEvent> _streamController = StreamController<WsServerEvent>.broadcast();
  final List<WsClientEvent> sentEvents = [];
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
  void send(WsClientEvent event) {
    sentEvents.add(event);
  }

  void emit(WsServerEvent event) {
    _streamController.add(event);
  }
}

void main() {
  group('ChatController & ConversationsController Tests', () {
    late FakeChatApiService fakeApi;
    late FakeChatWebSocketService fakeWs;

    setUp(() {
      fakeApi = FakeChatApiService();
      fakeWs = FakeChatWebSocketService();
    });

    test('ChatController initializes and fetches messages', () async {
      fakeApi.messages = [
        MessageModel(
          id: 'm1',
          conversationId: 'conv_1',
          senderId: 'u2',
          senderUsername: 'alice',
          senderDisplayName: 'Alice',
          content: 'Hello Bob!',
          status: MessageStatus.sent,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final controller = ChatController(
        conversationId: 'conv_1',
        token: 'test_token',
        currentUserId: 'u1',
        apiService: fakeApi,
        wsService: fakeWs,
      );

      await controller.initialize();

      expect(controller.isLoading, isFalse);
      expect(controller.messages.length, 1);
      expect(controller.messages.first.content, 'Hello Bob!');
      expect(fakeWs.isConnected, isTrue);
    });

    test('ChatController sends message and does not duplicate when server broadcasts self message', () async {
      final controller = ChatController(
        conversationId: 'conv_1',
        token: 'test_token',
        currentUserId: 'u1',
        currentUsername: 'bob',
        apiService: fakeApi,
        wsService: fakeWs,
      );

      await controller.initialize();

      // 1. Send message: Creates 1 optimistic message
      final sent = await controller.sendMessage('Hello back!');
      expect(sent, isTrue);
      expect(controller.messages.length, 1);
      expect(controller.messages.first.id.startsWith('temp_'), isTrue);
      expect(controller.messages.first.content, 'Hello back!');
      expect(fakeWs.sentEvents.any((e) => e is WsSendMessageEvent), isTrue);

      // 2. Server broadcasts the confirmed message back to all conversation members (including sender)
      final serverConfirmedMsg = MessageModel(
        id: 'server_msg_uuid_123',
        conversationId: 'conv_1',
        senderId: 'u1',
        senderUsername: 'bob',
        senderDisplayName: 'Bob',
        content: 'Hello back!',
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      fakeWs.emit(WsMessageNewEvent(message: serverConfirmedMsg));
      await Future.delayed(const Duration(milliseconds: 10));

      // 3. Sender MUST NOT have duplicate messages (length remains 1, replaced temp with server ID)
      expect(controller.messages.length, 1);
      expect(controller.messages.first.id, 'server_msg_uuid_123');
      expect(controller.messages.first.content, 'Hello back!');

      // 4. Sender must NOT send delivered or read events for their own message
      final deliveredOrReadSent = fakeWs.sentEvents.any((e) =>
          (e is WsMessageDeliveredEvent && e.messageId == 'server_msg_uuid_123') ||
          (e is WsMessageReadEvent && e.messageId == 'server_msg_uuid_123'));
      expect(deliveredOrReadSent, isFalse);
    });

    test('ChatController receives incoming message from other user and marks as read/delivered', () async {
      final controller = ChatController(
        conversationId: 'conv_1',
        token: 'test_token',
        currentUserId: 'u1',
        currentUsername: 'bob',
        apiService: fakeApi,
        wsService: fakeWs,
      );

      await controller.initialize();

      final incoming = MessageModel(
        id: 'm_realtime_2',
        conversationId: 'conv_1',
        senderId: 'u2',
        senderUsername: 'alice',
        senderDisplayName: 'Alice',
        content: 'How is it going?',
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      fakeWs.emit(WsMessageNewEvent(message: incoming));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(controller.messages.length, 1);
      expect(controller.messages.first.id, 'm_realtime_2');
      expect(controller.messages.first.content, 'How is it going?');

      // Delivered & Read events should be sent for incoming message from friend
      expect(fakeWs.sentEvents.any((e) => e is WsMessageDeliveredEvent && e.messageId == 'm_realtime_2'), isTrue);
      expect(fakeWs.sentEvents.any((e) => e is WsMessageReadEvent && e.messageId == 'm_realtime_2'), isTrue);
    });

    test('ChatController handles typing indicators', () async {
      final controller = ChatController(
        conversationId: 'conv_1',
        token: 'test_token',
        currentUserId: 'u1',
        apiService: fakeApi,
        wsService: fakeWs,
      );

      await controller.initialize();
      expect(controller.isOtherUserTyping, isFalse);

      // Other user typing start
      fakeWs.emit(WsUserTypingStartEvent(conversationId: 'conv_1', userId: 'u2', username: 'alice'));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.isOtherUserTyping, isTrue);

      // Other user typing stop
      fakeWs.emit(WsUserTypingStopEvent(conversationId: 'conv_1', userId: 'u2'));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.isOtherUserTyping, isFalse);
    });

    test('ConversationsController fetches list and reorders on new message without incrementing unread for self message', () async {
      final conv1 = ConversationModel(
        id: 'c1',
        type: ConversationType.direct,
        otherUser: const ConversationUser(userId: 'u2', username: 'alice', displayName: 'Alice'),
        lastMessage: MessageModel(
          id: 'm1',
          conversationId: 'c1',
          senderId: 'u2',
          senderUsername: 'alice',
          senderDisplayName: 'Alice',
          content: 'Hey',
          status: MessageStatus.sent,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      final conv2 = ConversationModel(
        id: 'c2',
        type: ConversationType.direct,
        otherUser: const ConversationUser(userId: 'u3', username: 'charlie', displayName: 'Charlie'),
        lastMessage: MessageModel(
          id: 'm2',
          conversationId: 'c2',
          senderId: 'u3',
          senderUsername: 'charlie',
          senderDisplayName: 'Charlie',
          content: 'Hi!',
          status: MessageStatus.sent,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      fakeApi.conversations = [conv2, conv1];

      final conversationsCtrl = ConversationsController(
        currentUserId: 'u1',
        currentUsername: 'bob',
        apiService: fakeApi,
        wsService: fakeWs,
      );

      await conversationsCtrl.fetchConversations(token: 'token');
      expect(conversationsCtrl.conversations.length, 2);
      expect(conversationsCtrl.conversations[0].id, 'c2');
      expect(conversationsCtrl.conversations[1].id, 'c1');

      // 1. Message sent by self (bob) -> moves c1 to top but does NOT increase unread count
      final selfMsg = MessageModel(
        id: 'm_self',
        conversationId: 'c1',
        senderId: 'u1',
        senderUsername: 'bob',
        senderDisplayName: 'Bob',
        content: 'I sent this',
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      fakeWs.emit(WsMessageNewEvent(message: selfMsg));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(conversationsCtrl.conversations[0].id, 'c1');
      expect(conversationsCtrl.conversations[0].lastMessage?.content, 'I sent this');
      expect(conversationsCtrl.conversations[0].unreadCount, 0);

      // 2. Incoming new message from friend (alice) -> should increment unreadCount
      final friendMsg = MessageModel(
        id: 'm_friend',
        conversationId: 'c1',
        senderId: 'u2',
        senderUsername: 'alice',
        senderDisplayName: 'Alice',
        content: 'New message for c1',
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      fakeWs.emit(WsMessageNewEvent(message: friendMsg));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(conversationsCtrl.conversations[0].id, 'c1');
      expect(conversationsCtrl.conversations[0].lastMessage?.content, 'New message for c1');
      expect(conversationsCtrl.conversations[0].unreadCount, 1);
    });
  });
}
