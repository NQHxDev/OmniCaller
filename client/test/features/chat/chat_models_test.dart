import 'package:client/features/chat/data/models/chat_models.dart';
import 'package:client/features/chat/data/models/ws_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatModels Tests', () {
    test('MessageType parsing and toJson', () {
      expect(MessageType.fromString('text'), MessageType.text);
      expect(MessageType.fromString('image'), MessageType.image);
      expect(MessageType.fromString('file'), MessageType.file);
      expect(MessageType.fromString('system'), MessageType.system);
      expect(MessageType.fromString('unknown'), MessageType.text);
      expect(MessageType.text.toJson(), 'text');
    });

    test('MessageStatus parsing and toJson', () {
      expect(MessageStatus.fromString('sending'), MessageStatus.sending);
      expect(MessageStatus.fromString('sent'), MessageStatus.sent);
      expect(MessageStatus.fromString('delivered'), MessageStatus.delivered);
      expect(MessageStatus.fromString('read'), MessageStatus.read);
      expect(MessageStatus.fromString('failed'), MessageStatus.failed);
      expect(MessageStatus.fromString('unknown'), MessageStatus.sent);
      expect(MessageStatus.sent.toJson(), 'sent');
    });

    test('ConversationType parsing and toJson', () {
      expect(ConversationType.fromString('direct'), ConversationType.direct);
      expect(ConversationType.fromString('group'), ConversationType.group);
      expect(ConversationType.direct.toJson(), 'direct');
    });

    test('MessageModel serialization & deserialization', () {
      final json = {
        'id': 'msg_1',
        'conversation_id': 'conv_1',
        'sender_id': 'usr_1',
        'sender_username': 'john',
        'sender_display_name': 'John Doe',
        'reply_to_message_id': 'msg_0',
        'message_type': 'text',
        'content': 'Hello there!',
        'status': 'read',
        'created_at': '2026-10-05T10:00:00.000Z',
        'updated_at': '2026-10-05T10:00:00.000Z',
      };

      final model = MessageModel.fromJson(json);
      expect(model.id, 'msg_1');
      expect(model.conversationId, 'conv_1');
      expect(model.senderId, 'usr_1');
      expect(model.senderUsername, 'john');
      expect(model.senderDisplayName, 'John Doe');
      expect(model.replyToMessageId, 'msg_0');
      expect(model.content, 'Hello there!');
      expect(model.status, MessageStatus.read);
      expect(model.isMine('usr_1'), isTrue);
      expect(model.isMine('usr_2'), isFalse);

      final serialized = model.toJson();
      expect(serialized['id'], 'msg_1');
      expect(serialized['content'], 'Hello there!');
      expect(serialized['status'], 'read');
    });

    test('ConversationModel serialization & deserialization and formatSubtitle', () {
      final json = {
        'id': 'conv_1',
        'type': 'direct',
        'title': null,
        'other_user': {
          'user_id': 'u2',
          'username': 'jane',
          'display_name': 'Nhi',
        },
        'last_message': {
          'id': 'msg_1',
          'conversation_id': 'conv_1',
          'sender_id': 'u2',
          'sender_username': 'jane',
          'sender_display_name': 'Nhi',
          'content': 'Hi!',
          'status': 'sent',
          'created_at': '2026-10-05T10:00:00.000Z',
          'updated_at': '2026-10-05T10:00:00.000Z',
        },
        'unread_count': 3,
        'created_at': '2026-10-05T09:00:00.000Z',
        'updated_at': '2026-10-05T10:00:00.000Z',
      };

      final conv = ConversationModel.fromJson(json);
      expect(conv.id, 'conv_1');
      expect(conv.type, ConversationType.direct);
      expect(conv.displayName, 'Nhi');
      expect(conv.formatSubtitle('u1', 'john'), 'Nhi: Hi!');
      expect(ConversationModel.extractShortName('Trần Thị Tuyết Nhi'), 'Nhi');
      expect(ConversationModel.extractShortName('Nguyễn Văn A'), 'A');
      expect(ConversationModel.extractShortName('Nhi'), 'Nhi');
      expect(conv.formatSubtitle('u2', 'jane'), 'Tôi: Hi!');
      expect(conv.unreadCount, 3);
      expect(conv.otherUser?.username, 'jane');
    });

    test('WsServerEvent parsing from JSON', () {
      final connectedJson = {
        'type': 'connected',
        'user_id': 'u_123',
      };
      final connEvent = WsServerEvent.fromJson(connectedJson);
      expect(connEvent, isA<WsConnectedEvent>());
      expect((connEvent as WsConnectedEvent).userId, 'u_123');

      final msgNewJson = {
        'type': 'message_new',
        'message': {
          'id': 'm1',
          'conversation_id': 'c1',
          'sender_id': 'u1',
          'sender_username': 'user1',
          'sender_display_name': 'User 1',
          'content': 'New message',
          'status': 'sent',
          'created_at': '2026-10-05T10:00:00.000Z',
          'updated_at': '2026-10-05T10:00:00.000Z',
        }
      };
      final msgEvent = WsServerEvent.fromJson(msgNewJson);
      expect(msgEvent, isA<WsMessageNewEvent>());
      expect((msgEvent as WsMessageNewEvent).message.content, 'New message');

      final typingJson = {
        'type': 'typing_start',
        'conversation_id': 'c1',
        'user_id': 'u1',
        'username': 'user1',
      };
      final typingEvent = WsServerEvent.fromJson(typingJson);
      expect(typingEvent, isA<WsUserTypingStartEvent>());
    });
  });
}
