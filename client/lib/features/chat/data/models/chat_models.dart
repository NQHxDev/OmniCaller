enum MessageType {
  text,
  image,
  file,
  system;

  static MessageType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      case 'text':
      default:
        return MessageType.text;
    }
  }

  String toJson() => name;
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  static MessageStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  String toJson() => name;
}

enum ConversationType {
  direct,
  group;

  static ConversationType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'group':
        return ConversationType.group;
      case 'direct':
      default:
        return ConversationType.direct;
    }
  }

  String toJson() => name;
}

class ConversationUser {
  final String userId;
  final String username;
  final String displayName;

  const ConversationUser({
    required this.userId,
    required this.username,
    required this.displayName,
  });

  factory ConversationUser.fromJson(Map<String, dynamic> json) {
    return ConversationUser(
      userId: json['user_id'] as String? ?? json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'display_name': displayName,
  };
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderUsername;
  final String senderDisplayName;
  final String? replyToMessageId;
  final MessageType messageType;
  final String content;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    required this.senderDisplayName,
    this.replyToMessageId,
    this.messageType = MessageType.text,
    required this.content,
    this.status = MessageStatus.sent,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isMine(String currentUserId, [String? currentUsername]) {
    if (currentUserId.isNotEmpty && senderId.isNotEmpty) {
      return senderId == currentUserId;
    }
    if (currentUsername != null && currentUsername.isNotEmpty) {
      return senderUsername.toLowerCase() == currentUsername.toLowerCase();
    }
    return false;
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderUsername,
    String? senderDisplayName,
    String? replyToMessageId,
    MessageType? messageType,
    String? content,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderUsername: json['sender_username'] as String? ?? '',
      senderDisplayName: json['sender_display_name'] as String? ?? '',
      replyToMessageId: json['reply_to_message_id'] as String?,
      messageType: MessageType.fromString(json['message_type'] as String?),
      content: json['content'] as String? ?? '',
      status: MessageStatus.fromString(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'sender_username': senderUsername,
    'sender_display_name': senderDisplayName,
    if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
    'message_type': messageType.toJson(),
    'content': content,
    'status': status.toJson(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
}

class ConversationModel {
  final String id;
  final ConversationType type;
  final String? title;
  final String? avatarUrl;
  final ConversationUser? otherUser;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.type,
    this.title,
    this.avatarUrl,
    this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName {
    if (title != null && title!.isNotEmpty) return title!;
    if (otherUser != null) {
      return otherUser!.displayName.isNotEmpty ? otherUser!.displayName : otherUser!.username;
    }
    return 'Cuộc trò chuyện';
  }

  static String extractShortName(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    return parts.last;
  }

  String formatSubtitle(String currentUserId, [String? currentUsername]) {
    if (lastMessage == null || lastMessage!.content.isEmpty) {
      return 'Hãy bắt đầu cuộc trò chuyện!';
    }
    final isMine = lastMessage!.isMine(currentUserId, currentUsername);
    if (isMine) {
      return 'Tôi: ${lastMessage!.content}';
    }

    String rawSender = '';
    if (type == ConversationType.group) {
      rawSender = lastMessage!.senderDisplayName.isNotEmpty
          ? lastMessage!.senderDisplayName
          : lastMessage!.senderUsername;
    } else {
      rawSender = lastMessage!.senderDisplayName.isNotEmpty
          ? lastMessage!.senderDisplayName
          : (otherUser?.displayName.isNotEmpty == true
              ? otherUser!.displayName
              : (otherUser?.username ?? lastMessage!.senderUsername));
    }

    final shortName = extractShortName(rawSender);
    return shortName.isNotEmpty ? '$shortName: ${lastMessage!.content}' : lastMessage!.content;
  }

  String get displaySubtitle {
    if (lastMessage != null && lastMessage!.content.isNotEmpty) {
      return lastMessage!.content;
    }
    return 'Hãy bắt đầu cuộc trò chuyện!';
  }

  ConversationModel copyWith({
    String? id,
    ConversationType? type,
    String? title,
    String? avatarUrl,
    ConversationUser? otherUser,
    MessageModel? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String? ?? '',
      type: ConversationType.fromString(json['type'] as String?),
      title: json['title'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      otherUser: json['other_user'] != null
          ? ConversationUser.fromJson(json['other_user'] as Map<String, dynamic>)
          : null,
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toJson(),
    if (title != null) 'title': title,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (otherUser != null) 'other_user': otherUser!.toJson(),
    if (lastMessage != null) 'last_message': lastMessage!.toJson(),
    'unread_count': unreadCount,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
}

class MessagesResponse {
  final List<MessageModel> messages;
  final String? nextCursor;
  final bool hasMore;

  const MessagesResponse({
    required this.messages,
    this.nextCursor,
    this.hasMore = false,
  });

  factory MessagesResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['messages'] as List<dynamic>?) ?? [];
    return MessagesResponse(
      messages: list.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList(),
      nextCursor: json['next_cursor'] as String?,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
