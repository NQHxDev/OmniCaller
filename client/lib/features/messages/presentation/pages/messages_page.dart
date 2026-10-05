import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/auth/auth_scope.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../friends/presentation/controllers/friends_controller.dart';
import '../../../groups/presentation/pages/create_group_page.dart';
import '../../../profile/presentation/pages/user_profile_page.dart';
import '../../../search/presentation/controllers/user_search_controller.dart';
import '../../../search/presentation/widgets/user_search_results_view.dart';
import '../widgets/messages_top_bar.dart';

class MessagesPage extends StatefulWidget {
  final UserSearchController? searchController;
  final FriendsController? friendsController;

  const MessagesPage({
    super.key,
    this.searchController,
    this.friendsController,
  });

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _textController = TextEditingController();
  late final UserSearchController _searchController;
  late final bool _isInternalSearchController;
  late final FriendsController _friendsController;
  late final bool _isInternalFriendsController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.searchController != null) {
      _searchController = widget.searchController!;
      _isInternalSearchController = false;
    } else {
      _searchController = UserSearchController();
      _isInternalSearchController = true;
    }

    if (widget.friendsController != null) {
      _friendsController = widget.friendsController!;
      _isInternalFriendsController = false;
    } else {
      _friendsController = FriendsController();
      _isInternalFriendsController = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    if (_isInternalSearchController) {
      _searchController.dispose();
    }
    if (_isInternalFriendsController) {
      _friendsController.dispose();
    }
    super.dispose();
  }

  void _loadData() {
    final token = AuthScope.of(context).accessToken;
    _friendsController.fetchFriends(token: token);
  }

  void _onAddFriend() {
    // Action handler for Add Friend
  }

  void _onCreateGroup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateGroupPage(),
      ),
    );
  }

  void _onOpenChat({
    required String username,
    String? displayName,
    String? userId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          username: username,
          displayName: displayName,
          userId: userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final authController = AuthScope.of(context);
    final token = authController.accessToken;

    return Scaffold(
      appBar: MessagesTopBar(
        searchController: _textController,
        onSearchChanged: (query) {
          _searchController.onQueryChanged(query, token: token);
        },
        onClearSearch: () {
          _textController.clear();
          _searchController.clear();
        },
        onAddFriend: _onAddFriend,
        onCreateGroup: _onCreateGroup,
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([_searchController, _friendsController]),
          builder: (context, _) {
            if (_searchController.hasQuery) {
              return UserSearchResultsView(
                controller: _searchController,
                onUserTap: (user) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(
                        username: user.username,
                        initialDisplayName: user.displayName,
                        initialUserId: user.userId,
                      ),
                    ),
                  );
                },
              );
            }

            if (_friendsController.isLoading && _friendsController.friends.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (_friendsController.friends.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withAlpha(120),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedMessage01,
                          color: theme.colorScheme.primary,
                          size: 32.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có cuộc trò chuyện nào',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tìm kiếm bạn bè ở thanh trên để bắt đầu trò chuyện',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _friendsController.friends.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final friend = _friendsController.friends[index];
                  final displayName = friend.displayName.isNotEmpty
                      ? friend.displayName
                      : friend.username;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedUser,
                        color: theme.colorScheme.primary,
                        size: 24.0,
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (friend.isNew) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withAlpha(200),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: theme.colorScheme.primary.withAlpha(60),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedSparkles,
                                  size: 11.0,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Bạn mới',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        'Các bạn đã trở thành bạn bè. Hãy gửi lời chào ngay!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    trailing: HugeIcon(
                      icon: HugeIcons.strokeRoundedMessage01,
                      color: theme.colorScheme.primary.withAlpha(180),
                      size: 18.0,
                    ),
                    onTap: () => _onOpenChat(
                      username: friend.username,
                      displayName: friend.displayName,
                      userId: friend.userId,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
