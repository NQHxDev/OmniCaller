import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/auth/auth_scope.dart';
import '../../../chat/data/models/chat_models.dart';
import '../../../chat/presentation/controllers/conversations_controller.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../friends/data/models/friend_models.dart';
import '../../../friends/presentation/controllers/friends_controller.dart';
import '../../../groups/presentation/pages/create_group_page.dart';
import '../../../profile/presentation/pages/user_profile_page.dart';
import '../../../search/presentation/controllers/user_search_controller.dart';
import '../../../search/presentation/widgets/user_search_results_view.dart';
import '../widgets/messages_top_bar.dart';

sealed class _MessageListItem {
  final DateTime timestamp;
  const _MessageListItem(this.timestamp);
}

class _ConversationListItem extends _MessageListItem {
  final ConversationModel conversation;
  _ConversationListItem(this.conversation)
      : super(conversation.lastMessage?.createdAt ?? conversation.updatedAt);
}

class _NewFriendListItem extends _MessageListItem {
  final FriendUser friend;
  _NewFriendListItem(this.friend) : super(friend.timestamp);
}

class MessagesPage extends StatefulWidget {
  final UserSearchController? searchController;
  final FriendsController? friendsController;
  final ConversationsController? conversationsController;

  const MessagesPage({
    super.key,
    this.searchController,
    this.friendsController,
    this.conversationsController,
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
  late final ConversationsController _conversationsController;
  late final bool _isInternalConversationsController;

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

    if (widget.conversationsController != null) {
      _conversationsController = widget.conversationsController!;
      _isInternalConversationsController = false;
    } else {
      _conversationsController = ConversationsController();
      _isInternalConversationsController = true;
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
    if (_isInternalConversationsController) {
      _conversationsController.dispose();
    }
    super.dispose();
  }

  void _loadData() {
    final auth = AuthScope.maybeOf(context);
    final token = auth?.accessToken;
    if (token != null && token.isNotEmpty) {
      _friendsController.fetchFriends(token: token);
      _conversationsController.fetchConversations(
        token: token,
        currentUserId: auth?.currentUser?.id,
        currentUsername: auth?.currentUser?.username,
      );
    }
  }

  void _onAddFriend() {
    // Action handler for Add Friend
  }

  void _onCreateGroup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateGroupPage(
          friendsController: _friendsController,
        ),
      ),
    );
  }

  void _onOpenChat({
    String? conversationId,
    required String username,
    String? displayName,
    String? userId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: conversationId,
          username: username,
          displayName: displayName,
          userId: userId,
        ),
      ),
    ).then((_) => _loadData());
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays < 7) {
      const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      return days[dateTime.weekday % 7];
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final authController = AuthScope.maybeOf(context);
    final token = authController?.accessToken;

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
          listenable: Listenable.merge([
            _searchController,
            _friendsController,
            _conversationsController,
          ]),
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
                  ).then((_) => _loadData());
                },
              );
            }

            final isLoading = (_conversationsController.isLoading || _friendsController.isLoading) &&
                _conversationsController.conversations.isEmpty &&
                _friendsController.friends.isEmpty;

            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Existing conversations
            final existingConvs = _conversationsController.conversations;

            // Collect friend usernames who already have a conversation
            final existingUsernames = existingConvs
                .where((c) => c.otherUser != null)
                .map((c) => c.otherUser!.username.toLowerCase())
                .toSet();

            // Friends who do not yet have an active conversation listed
            final newFriendsWithoutConv = _friendsController.friends
                .where((f) => !existingUsernames.contains(f.username.toLowerCase()))
                .toList();

            final isEmpty = existingConvs.isEmpty && newFriendsWithoutConv.isEmpty;

            if (isEmpty) {
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

            // Merge conversations and new friends into a unified timeline sorted by timestamp descending
            final List<_MessageListItem> timelineItems = [
              ...existingConvs.map((c) => _ConversationListItem(c)),
              ...newFriendsWithoutConv.map((f) => _NewFriendListItem(f)),
            ];

            timelineItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: timelineItems.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final item = timelineItems[index];

                  if (item is _ConversationListItem) {
                    final conv = item.conversation;
                    final title = conv.displayName;
                    final currentUserId = authController?.currentUser?.id ?? '';
                    final currentUsername = authController?.currentUser?.username ?? '';
                    final subtitle = conv.formatSubtitle(currentUserId, currentUsername);
                    final isLastMessageMine = conv.lastMessage?.isMine(currentUserId, currentUsername) ?? false;
                    final hasUnread = conv.unreadCount > 0 && !isLastMessageMine;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: HugeIcon(
                          icon: conv.type == ConversationType.group
                              ? HugeIcons.strokeRoundedUserGroup
                              : HugeIcons.strokeRoundedUser,
                          color: theme.colorScheme.primary,
                          size: 24.0,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(item.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                  color: hasUnread
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (hasUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      onTap: () => _onOpenChat(
                        conversationId: conv.id,
                        username: conv.otherUser?.username ?? '',
                        displayName: conv.otherUser?.displayName,
                        userId: conv.otherUser?.userId,
                      ),
                    );
                  } else if (item is _NewFriendListItem) {
                    final friend = item.friend;
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
                  }
                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
