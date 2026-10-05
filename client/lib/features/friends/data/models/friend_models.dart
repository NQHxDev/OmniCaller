enum FriendshipStatus {
  none,
  pendingSent,
  pendingReceived,
  accepted,
  rejected,
  blocked;

  static FriendshipStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending_sent':
        return FriendshipStatus.pendingSent;
      case 'pending_received':
      case 'pending':
        return FriendshipStatus.pendingReceived;
      case 'accepted':
        return FriendshipStatus.accepted;
      case 'rejected':
        return FriendshipStatus.rejected;
      case 'blocked':
        return FriendshipStatus.blocked;
      default:
        return FriendshipStatus.none;
    }
  }

  String toServerString() {
    switch (this) {
      case FriendshipStatus.pendingSent:
        return 'pending_sent';
      case FriendshipStatus.pendingReceived:
        return 'pending_received';
      case FriendshipStatus.accepted:
        return 'accepted';
      case FriendshipStatus.rejected:
        return 'rejected';
      case FriendshipStatus.blocked:
        return 'blocked';
      case FriendshipStatus.none:
        return 'none';
    }
  }
}

class FriendUser {
  final String userId;
  final String username;
  final String displayName;
  final String? createdAt;
  final String? friendshipId;
  final String? requestedAt;
  final String? respondedAt;
  final bool? isNewFriend;

  const FriendUser({
    required this.userId,
    required this.username,
    required this.displayName,
    this.createdAt,
    this.friendshipId,
    this.requestedAt,
    this.respondedAt,
    this.isNewFriend,
  });

  bool get isNew {
    if (isNewFriend != null) return isNewFriend!;
    final dateStr = respondedAt ?? createdAt ?? requestedAt;
    if (dateStr == null || dateStr.isEmpty) return true;
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return true;
    return DateTime.now().toUtc().difference(dt.toUtc()).inDays <= 7;
  }

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] as Map<String, dynamic>?;
    return FriendUser(
      userId: userObj?['user_id'] as String? ??
          userObj?['id'] as String? ??
          json['user_id'] as String? ??
          json['friend_user_id'] as String? ??
          json['id'] as String? ??
          '',
      username: userObj?['username'] as String? ?? json['username'] as String? ?? '',
      displayName: userObj?['display_name'] as String? ?? json['display_name'] as String? ?? '',
      createdAt: json['created_at'] as String?,
      friendshipId: json['friendship_id'] as String? ?? json['id'] as String?,
      requestedAt: json['requested_at'] as String?,
      respondedAt: json['responded_at'] as String?,
      isNewFriend: json['is_new'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'display_name': displayName,
    if (createdAt != null) 'created_at': createdAt,
    if (friendshipId != null) 'friendship_id': friendshipId,
    if (requestedAt != null) 'requested_at': requestedAt,
    if (respondedAt != null) 'responded_at': respondedAt,
    if (isNewFriend != null) 'is_new': isNewFriend,
  };
}

class FriendRequestItem {
  final String requestId;
  final String userId;
  final String username;
  final String displayName;
  final String requestedAt;
  final String? status;

  const FriendRequestItem({
    required this.requestId,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.requestedAt,
    this.status,
  });

  factory FriendRequestItem.fromJson(Map<String, dynamic> json) {
    // Supports either flat format or nested user object format
    final userObj = json['user'] as Map<String, dynamic>?;
    return FriendRequestItem(
      requestId: json['id'] as String? ??
          json['request_id'] as String? ??
          json['friendship_id'] as String? ??
          '',
      userId: userObj?['user_id'] as String? ??
          userObj?['id'] as String? ??
          json['user_id'] as String? ??
          json['friend_id'] as String? ??
          json['requester_user_id'] as String? ??
          json['friend_user_id'] as String? ??
          '',
      username: userObj?['username'] as String? ?? json['username'] as String? ?? '',
      displayName: userObj?['display_name'] as String? ?? json['display_name'] as String? ?? '',
      requestedAt: json['requested_at'] as String? ?? json['created_at'] as String? ?? '',
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': requestId,
    'user_id': userId,
    'username': username,
    'display_name': displayName,
    'requested_at': requestedAt,
    if (status != null) 'status': status,
  };
}

class FriendshipStatusData {
  final FriendshipStatus status;
  final String? requestId;

  const FriendshipStatusData({
    required this.status,
    this.requestId,
  });

  factory FriendshipStatusData.fromJson(Map<String, dynamic> json) {
    return FriendshipStatusData(
      status: FriendshipStatus.fromString(json['status'] as String?),
      requestId: json['request_id'] as String? ??
          json['friendship_id'] as String? ??
          json['id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.toServerString(),
    if (requestId != null) 'request_id': requestId,
  };
}
