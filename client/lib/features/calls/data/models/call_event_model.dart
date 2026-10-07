import 'call_model.dart';

abstract class CallWsEvent {
  static CallWsEvent? fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'incoming_call':
      case 'IncomingCall':
        return WsIncomingCallEvent.fromJson(json);
      case 'call_status_update':
      case 'CallStatusUpdate':
        return WsCallStatusUpdateEvent.fromJson(json);
      case 'participant_joined':
      case 'ParticipantJoined':
        return WsParticipantJoinedEvent.fromJson(json);
      case 'participant_left':
      case 'ParticipantLeft':
        return WsParticipantLeftEvent.fromJson(json);
      case 'call_ended':
      case 'CallEnded':
        return WsCallEndedEvent.fromJson(json);
      case 'presence_update':
      case 'PresenceUpdate':
        return WsPresenceUpdateEvent.fromJson(json);
      default:
        return null;
    }
  }
}

class WsIncomingCallEvent implements CallWsEvent {
  final String callId;
  final String roomName;
  final CallType callType;
  final CallMode mode;
  final String initiatedBy;
  final String initiatorName;
  final String? conversationId;

  const WsIncomingCallEvent({
    required this.callId,
    required this.roomName,
    required this.callType,
    required this.mode,
    required this.initiatedBy,
    required this.initiatorName,
    this.conversationId,
  });

  factory WsIncomingCallEvent.fromJson(Map<String, dynamic> json) {
    return WsIncomingCallEvent(
      callId: json['call_id'] as String? ?? '',
      roomName: json['room_name'] as String? ?? '',
      callType: CallType.fromString(json['call_type'] as String?),
      mode: CallMode.fromString(json['mode'] as String?),
      initiatedBy: json['initiated_by'] as String? ?? '',
      initiatorName: json['initiator_name'] as String? ?? 'Caller',
      conversationId: json['conversation_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'incoming_call',
    'call_id': callId,
    'room_name': roomName,
    'call_type': callType.toJson(),
    'mode': mode.toJson(),
    'initiated_by': initiatedBy,
    'initiator_name': initiatorName,
    if (conversationId != null) 'conversation_id': conversationId,
  };
}

class WsCallStatusUpdateEvent implements CallWsEvent {
  final String callId;
  final CallStatus status;

  const WsCallStatusUpdateEvent({
    required this.callId,
    required this.status,
  });

  factory WsCallStatusUpdateEvent.fromJson(Map<String, dynamic> json) {
    return WsCallStatusUpdateEvent(
      callId: json['call_id'] as String? ?? '',
      status: CallStatus.fromString(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'call_status_update',
    'call_id': callId,
    'status': status.toJson(),
  };
}

class WsParticipantJoinedEvent implements CallWsEvent {
  final String callId;
  final String userId;
  final String username;

  const WsParticipantJoinedEvent({
    required this.callId,
    required this.userId,
    required this.username,
  });

  factory WsParticipantJoinedEvent.fromJson(Map<String, dynamic> json) {
    return WsParticipantJoinedEvent(
      callId: json['call_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'participant_joined',
    'call_id': callId,
    'user_id': userId,
    'username': username,
  };
}

class WsParticipantLeftEvent implements CallWsEvent {
  final String callId;
  final String userId;
  final String username;

  const WsParticipantLeftEvent({
    required this.callId,
    required this.userId,
    required this.username,
  });

  factory WsParticipantLeftEvent.fromJson(Map<String, dynamic> json) {
    return WsParticipantLeftEvent(
      callId: json['call_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'participant_left',
    'call_id': callId,
    'user_id': userId,
    'username': username,
  };
}

class WsCallEndedEvent implements CallWsEvent {
  final String callId;
  final String endedBy;
  final int? duration;

  const WsCallEndedEvent({
    required this.callId,
    required this.endedBy,
    this.duration,
  });

  factory WsCallEndedEvent.fromJson(Map<String, dynamic> json) {
    return WsCallEndedEvent(
      callId: json['call_id'] as String? ?? '',
      endedBy: json['ended_by'] as String? ?? '',
      duration: json['duration'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'call_ended',
    'call_id': callId,
    'ended_by': endedBy,
    if (duration != null) 'duration': duration,
  };
}

class WsPresenceUpdateEvent implements CallWsEvent {
  final String userId;
  final String status;

  const WsPresenceUpdateEvent({
    required this.userId,
    required this.status,
  });

  factory WsPresenceUpdateEvent.fromJson(Map<String, dynamic> json) {
    return WsPresenceUpdateEvent(
      userId: json['user_id'] as String? ?? '',
      status: json['status'] as String? ?? 'offline',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'presence_update',
    'user_id': userId,
    'status': status,
  };
}
