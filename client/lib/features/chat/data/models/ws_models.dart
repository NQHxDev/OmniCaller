import 'package:client/features/calls/data/models/call_event_model.dart';
import 'chat_models.dart';

abstract class WsClientEvent {
  Map<String, dynamic> toJson();
}

class WsSendMessageEvent implements WsClientEvent {
  final String conversationId;
  final String content;
  final String? replyToMessageId;

  const WsSendMessageEvent({
    required this.conversationId,
    required this.content,
    this.replyToMessageId,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'send_message',
    'conversation_id': conversationId,
    'content': content,
    if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
  };
}

class WsTypingStartEvent implements WsClientEvent {
  final String conversationId;

  const WsTypingStartEvent({required this.conversationId});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'typing_start',
    'conversation_id': conversationId,
  };
}

class WsTypingStopEvent implements WsClientEvent {
  final String conversationId;

  const WsTypingStopEvent({required this.conversationId});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'typing_stop',
    'conversation_id': conversationId,
  };
}

class WsMessageDeliveredEvent implements WsClientEvent {
  final String messageId;

  const WsMessageDeliveredEvent({required this.messageId});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'message_delivered',
    'message_id': messageId,
  };
}

class WsMessageReadEvent implements WsClientEvent {
  final String messageId;

  const WsMessageReadEvent({required this.messageId});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'message_read',
    'message_id': messageId,
  };
}

// Server -> Client Events
abstract class WsServerEvent {
  static WsServerEvent? fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'connected':
        return WsConnectedEvent(userId: json['user_id'] as String? ?? '');
      case 'message_new':
        return WsMessageNewEvent(
          message: MessageModel.fromJson(json['message'] as Map<String, dynamic>),
        );
      case 'message_status':
        return WsMessageStatusEvent(
          messageId: json['message_id'] as String? ?? '',
          status: MessageStatus.fromString(json['status'] as String?),
        );
      case 'typing_start':
        return WsUserTypingStartEvent(
          conversationId: json['conversation_id'] as String? ?? '',
          userId: json['user_id'] as String? ?? '',
          username: json['username'] as String? ?? '',
        );
      case 'typing_stop':
        return WsUserTypingStopEvent(
          conversationId: json['conversation_id'] as String? ?? '',
          userId: json['user_id'] as String? ?? '',
        );
      case 'incoming_call':
      case 'IncomingCall':
        return WsIncomingCallServerEvent(
          event: WsIncomingCallEvent.fromJson(json),
        );
      case 'call_status_update':
      case 'CallStatusUpdate':
        return WsCallStatusUpdateServerEvent(
          event: WsCallStatusUpdateEvent.fromJson(json),
        );
      case 'participant_joined':
      case 'ParticipantJoined':
        return WsParticipantJoinedServerEvent(
          event: WsParticipantJoinedEvent.fromJson(json),
        );
      case 'participant_left':
      case 'ParticipantLeft':
        return WsParticipantLeftServerEvent(
          event: WsParticipantLeftEvent.fromJson(json),
        );
      case 'call_ended':
      case 'CallEnded':
        return WsCallEndedServerEvent(
          event: WsCallEndedEvent.fromJson(json),
        );
      case 'presence_update':
      case 'PresenceUpdate':
        return WsPresenceUpdateServerEvent(
          event: WsPresenceUpdateEvent.fromJson(json),
        );
      case 'error':
        return WsErrorEvent(message: json['message'] as String? ?? 'Unknown error');
      default:
        return null;
    }
  }
}

class WsConnectedEvent extends WsServerEvent {
  final String userId;
  WsConnectedEvent({required this.userId});
}

class WsMessageNewEvent extends WsServerEvent {
  final MessageModel message;
  WsMessageNewEvent({required this.message});
}

class WsMessageStatusEvent extends WsServerEvent {
  final String messageId;
  final MessageStatus status;
  WsMessageStatusEvent({required this.messageId, required this.status});
}

class WsUserTypingStartEvent extends WsServerEvent {
  final String conversationId;
  final String userId;
  final String username;
  WsUserTypingStartEvent({
    required this.conversationId,
    required this.userId,
    required this.username,
  });
}

class WsUserTypingStopEvent extends WsServerEvent {
  final String conversationId;
  final String userId;
  WsUserTypingStopEvent({required this.conversationId, required this.userId});
}

class WsIncomingCallServerEvent extends WsServerEvent {
  final WsIncomingCallEvent event;
  WsIncomingCallServerEvent({required this.event});
}

class WsCallStatusUpdateServerEvent extends WsServerEvent {
  final WsCallStatusUpdateEvent event;
  WsCallStatusUpdateServerEvent({required this.event});
}

class WsParticipantJoinedServerEvent extends WsServerEvent {
  final WsParticipantJoinedEvent event;
  WsParticipantJoinedServerEvent({required this.event});
}

class WsParticipantLeftServerEvent extends WsServerEvent {
  final WsParticipantLeftEvent event;
  WsParticipantLeftServerEvent({required this.event});
}

class WsCallEndedServerEvent extends WsServerEvent {
  final WsCallEndedEvent event;
  WsCallEndedServerEvent({required this.event});
}

class WsPresenceUpdateServerEvent extends WsServerEvent {
  final WsPresenceUpdateEvent event;
  WsPresenceUpdateServerEvent({required this.event});
}

class WsErrorEvent extends WsServerEvent {
  final String message;
  WsErrorEvent({required this.message});
}
