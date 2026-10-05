import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/auth/auth_scope.dart';
import '../../../friends/presentation/controllers/friend_requests_controller.dart';
import '../../../friends/presentation/controllers/friends_controller.dart';
import '../../../profile/presentation/pages/user_profile_page.dart';
import '../../../search/presentation/controllers/user_search_controller.dart';
import '../../../search/presentation/widgets/user_search_results_view.dart';
import '../widgets/contacts_top_bar.dart';
import 'friend_requests_page.dart';
import 'groups_management_page.dart';

class ContactsPage extends StatefulWidget {
  final UserSearchController? searchController;
  final FriendsController? friendsController;
  final FriendRequestsController? requestsController;

  const ContactsPage({
    super.key,
    this.searchController,
    this.friendsController,
    this.requestsController,
  });

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _textController = TextEditingController();
  late final UserSearchController _searchController;
  late final bool _isInternalSearchController;
  late final FriendsController _friendsController;
  late final bool _isInternalFriendsController;
  late final FriendRequestsController _requestsController;
  late final bool _isInternalRequestsController;

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

    if (widget.requestsController != null) {
      _requestsController = widget.requestsController!;
      _isInternalRequestsController = false;
    } else {
      _requestsController = FriendRequestsController();
      _isInternalRequestsController = true;
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
    if (_isInternalRequestsController) {
      _requestsController.dispose();
    }
    super.dispose();
  }

  void _loadData() {
    final token = AuthScope.of(context).accessToken;
    _friendsController.fetchFriends(token: token);
    _requestsController.fetchRequests(token: token);
  }

  void _onGroupManagementPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GroupsManagementPage(),
      ),
    );
  }

  void _onFriendRequestsPressed() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FriendRequestsPage(
          controller: _requestsController,
        ),
      ),
    );
    // Reload friends and requests when returning from FriendRequestsPage
    _loadData();
  }

  void _onOpenUserProfile({
    required String username,
    String? displayName,
    String? userId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          username: username,
          initialDisplayName: displayName,
          initialUserId: userId,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final authController = AuthScope.of(context);
    final token = authController.accessToken;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: ListenableBuilder(
          listenable: _requestsController,
          builder: (context, _) {
            return ContactsTopBar(
              searchController: _textController,
              pendingRequestsCount: _requestsController.pendingCount,
              onSearchChanged: (query) {
                _searchController.onQueryChanged(query, token: token);
              },
              onClearSearch: () {
                _textController.clear();
                _searchController.clear();
              },
              onGroupManagementPressed: _onGroupManagementPressed,
              onFriendRequestsPressed: _onFriendRequestsPressed,
            );
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([_searchController, _friendsController, _requestsController]),
          builder: (context, _) {
            if (_searchController.hasQuery) {
              return UserSearchResultsView(
                controller: _searchController,
                onUserTap: (user) {
                  _onOpenUserProfile(
                    username: user.username,
                    displayName: user.displayName,
                    userId: user.userId,
                  );
                },
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withAlpha(120),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedUserGroup,
                        color: theme.colorScheme.primary,
                        size: 22.0,
                      ),
                    ),
                    title: const Text(
                      'Quản lý nhóm',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    trailing: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                      size: 18.0,
                    ),
                    onTap: _onGroupManagementPressed,
                  ),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withAlpha(120),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedMailAdd01,
                        color: theme.colorScheme.secondary,
                        size: 22.0,
                      ),
                    ),
                    title: const Text(
                      'Lời mời kết bạn',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_requestsController.pendingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_requestsController.pendingCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                          size: 18.0,
                        ),
                      ],
                    ),
                    onTap: _onFriendRequestsPressed,
                  ),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Danh bạ (${_friendsController.friendCount})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  if (_friendsController.isLoading && _friendsController.friends.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_friendsController.friends.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedContact01,
                              size: 40,
                              color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có liên hệ nào',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tìm kiếm người dùng ở thanh trên để kết bạn',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._friendsController.friends.map((friend) {
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedUser,
                            color: theme.colorScheme.primary,
                            size: 20.0,
                          ),
                        ),
                        title: Text(
                          friend.displayName.isNotEmpty
                              ? friend.displayName
                              : friend.username,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '@${friend.username}',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: HugeIcon(
                          icon: HugeIcons.strokeRoundedMessage01,
                          color: theme.colorScheme.primary,
                          size: 20.0,
                        ),
                        onTap: () => _onOpenUserProfile(
                          username: friend.username,
                          displayName: friend.displayName,
                          userId: friend.userId,
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
