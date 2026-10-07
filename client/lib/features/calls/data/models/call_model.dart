enum CallType {
  voice,
  video;

  static CallType fromString(String? type) {
    if (type?.toLowerCase() == 'video') {
      return CallType.video;
    }
    return CallType.voice;
  }

  String toJson() => name;
}

enum CallMode {
  direct,
  group;

  static CallMode fromString(String? mode) {
    if (mode?.toLowerCase() == 'group') {
      return CallMode.group;
    }
    return CallMode.direct;
  }

  String toJson() => name;
}

enum CallStatus {
  ringing,
  active,
  completed,
  rejected,
  missed,
  cancelled,
  unknown;

  static CallStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'ringing':
        return CallStatus.ringing;
      case 'active':
        return CallStatus.active;
      case 'completed':
        return CallStatus.completed;
      case 'rejected':
        return CallStatus.rejected;
      case 'missed':
        return CallStatus.missed;
      case 'cancelled':
        return CallStatus.cancelled;
      default:
        return CallStatus.unknown;
    }
  }

  String toJson() => name;
}

class CallParticipantModel {
  final String id;
  final String userId;
  final String status;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final int? duration;

  const CallParticipantModel({
    required this.id,
    required this.userId,
    required this.status,
    this.joinedAt,
    this.leftAt,
    this.duration,
  });

  factory CallParticipantModel.fromJson(Map<String, dynamic> json) {
    return CallParticipantModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      joinedAt: json['joined_at'] != null ? DateTime.tryParse(json['joined_at'].toString()) : null,
      leftAt: json['left_at'] != null ? DateTime.tryParse(json['left_at'].toString()) : null,
      duration: json['duration'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'status': status,
    if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
    if (leftAt != null) 'left_at': leftAt!.toIso8601String(),
    if (duration != null) 'duration': duration,
  };
}

class CallModel {
  final String id;
  final String roomName;
  final CallType callType;
  final CallMode mode;
  final String? conversationId;
  final String initiatedBy;
  final CallStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? duration;
  final List<CallParticipantModel> participants;

  const CallModel({
    required this.id,
    required this.roomName,
    required this.callType,
    required this.mode,
    this.conversationId,
    required this.initiatedBy,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.duration,
    this.participants = const [],
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'] as List<dynamic>? ?? [];
    return CallModel(
      id: json['id'] as String? ?? '',
      roomName: json['room_name'] as String? ?? '',
      callType: CallType.fromString(json['call_type'] as String?),
      mode: CallMode.fromString(json['mode'] as String?),
      conversationId: json['conversation_id'] as String?,
      initiatedBy: json['initiated_by'] as String? ?? '',
      status: CallStatus.fromString(json['status'] as String?),
      startedAt: json['started_at'] != null
          ? (DateTime.tryParse(json['started_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      endedAt: json['ended_at'] != null ? DateTime.tryParse(json['ended_at'].toString()) : null,
      duration: json['duration'] as int?,
      participants: rawParticipants
          .whereType<Map<String, dynamic>>()
          .map((p) => CallParticipantModel.fromJson(p))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'room_name': roomName,
    'call_type': callType.toJson(),
    'mode': mode.toJson(),
    if (conversationId != null) 'conversation_id': conversationId,
    'initiated_by': initiatedBy,
    'status': status.toJson(),
    'started_at': startedAt.toIso8601String(),
    if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
    if (duration != null) 'duration': duration,
    'participants': participants.map((p) => p.toJson()).toList(),
  };

  bool get isVideo => callType == CallType.video;
  bool get isVoice => callType == CallType.voice;
  bool get isGroup => mode == CallMode.group;
  bool get isDirect => mode == CallMode.direct;
}

class InitiateCallRequest {
  final CallType callType;
  final CallMode mode;
  final String? conversationId;
  final List<String> participantIds;

  const InitiateCallRequest({
    required this.callType,
    required this.mode,
    this.conversationId,
    required this.participantIds,
  });

  Map<String, dynamic> toJson() => {
    'call_type': callType.toJson(),
    'mode': mode.toJson(),
    if (conversationId != null) 'conversation_id': conversationId,
    'participant_ids': participantIds,
  };
}

class InitiateCallResponse {
  final CallModel call;
  final String token;

  const InitiateCallResponse({
    required this.call,
    required this.token,
  });

  factory InitiateCallResponse.fromJson(Map<String, dynamic> json) {
    return InitiateCallResponse(
      call: CallModel.fromJson(json['call'] as Map<String, dynamic>? ?? {}),
      token: json['token'] as String? ?? '',
    );
  }
}

class JoinCallResponse {
  final CallModel call;
  final String token;

  const JoinCallResponse({
    required this.call,
    required this.token,
  });

  factory JoinCallResponse.fromJson(Map<String, dynamic> json) {
    return JoinCallResponse(
      call: CallModel.fromJson(json['call'] as Map<String, dynamic>? ?? {}),
      token: json['token'] as String? ?? '',
    );
  }
}

class CallHistoryResponse {
  final List<CallModel> calls;
  final int total;

  const CallHistoryResponse({
    required this.calls,
    required this.total,
  });

  factory CallHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawCalls = json['calls'] as List<dynamic>? ?? [];
    return CallHistoryResponse(
      calls: rawCalls
          .whereType<Map<String, dynamic>>()
          .map((c) => CallModel.fromJson(c))
          .toList(),
      total: json['total'] as int? ?? 0,
    );
  }
}

class ActiveCallsResponse {
  final List<CallModel> calls;

  const ActiveCallsResponse({
    required this.calls,
  });

  factory ActiveCallsResponse.fromJson(Map<String, dynamic> json) {
    final rawCalls = json['calls'] as List<dynamic>? ?? [];
    return ActiveCallsResponse(
      calls: rawCalls
          .whereType<Map<String, dynamic>>()
          .map((c) => CallModel.fromJson(c))
          .toList(),
    );
  }
}

class UserPresenceModel {
  final String userId;
  final String status;
  final DateTime lastSeenAt;

  const UserPresenceModel({
    required this.userId,
    required this.status,
    required this.lastSeenAt,
  });

  factory UserPresenceModel.fromJson(Map<String, dynamic> json) {
    return UserPresenceModel(
      userId: json['user_id'] as String? ?? '',
      status: json['status'] as String? ?? 'offline',
      lastSeenAt: json['last_seen_at'] != null
          ? (DateTime.tryParse(json['last_seen_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'status': status,
    'last_seen_at': lastSeenAt.toIso8601String(),
  };
}
