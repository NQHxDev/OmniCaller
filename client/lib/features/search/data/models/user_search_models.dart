class UserSearchResult {
  final String userId;
  final String username;
  final String displayName;

  const UserSearchResult({
    required this.userId,
    required this.username,
    required this.displayName,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      userId: json['user_id'] as String? ?? '',
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

class SearchPagination {
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  const SearchPagination({
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory SearchPagination.fromJson(Map<String, dynamic> json) {
    return SearchPagination(
      currentPage: json['current_page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 10,
      totalItems: json['total_items'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'current_page': currentPage,
    'page_size': pageSize,
    'total_items': totalItems,
    'total_pages': totalPages,
  };
}

class SearchUsersResponse {
  final List<UserSearchResult> users;
  final SearchPagination pagination;

  const SearchUsersResponse({
    required this.users,
    required this.pagination,
  });

  factory SearchUsersResponse.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['users'] as List<dynamic>?;
    final usersList = rawUsers
            ?.map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <UserSearchResult>[];

    final rawPagination = json['pagination'] as Map<String, dynamic>?;
    final pagination = rawPagination != null
        ? SearchPagination.fromJson(rawPagination)
        : const SearchPagination(
            currentPage: 1,
            pageSize: 10,
            totalItems: 0,
            totalPages: 0,
          );

    return SearchUsersResponse(
      users: usersList,
      pagination: pagination,
    );
  }
}

class UserPublicProfile {
  final String userId;
  final String username;
  final String displayName;
  final String createdAt;

  const UserPublicProfile({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.createdAt,
  });

  factory UserPublicProfile.fromJson(Map<String, dynamic> json) {
    return UserPublicProfile(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'display_name': displayName,
    'created_at': createdAt,
  };
}
