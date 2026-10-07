class CreateGroupRequest {
  final String name;
  final String? description;
  final String? avatarUrl;
  final String? bannerUrl;
  final List<String> memberIds;

  const CreateGroupRequest({
    required this.name,
    this.description,
    this.avatarUrl,
    this.bannerUrl,
    required this.memberIds,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bannerUrl != null) 'banner_url': bannerUrl,
        'member_ids': memberIds,
      };
}

class GroupProfileResponse {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? pinnedMessageId;
  final String createdBy;
  final int memberCount;
  final String createdAt;

  const GroupProfileResponse({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.bannerUrl,
    this.pinnedMessageId,
    required this.createdBy,
    required this.memberCount,
    required this.createdAt,
  });

  factory GroupProfileResponse.fromJson(Map<String, dynamic> json) {
    return GroupProfileResponse(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      pinnedMessageId: json['pinned_message_id'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      memberCount: json['member_count'] is int
          ? json['member_count'] as int
          : (json['member_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'avatar_url': avatarUrl,
        'banner_url': bannerUrl,
        'pinned_message_id': pinnedMessageId,
        'created_by': createdBy,
        'member_count': memberCount,
        'created_at': createdAt,
      };
}
