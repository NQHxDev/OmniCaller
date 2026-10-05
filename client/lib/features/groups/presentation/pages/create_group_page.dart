import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/auth/auth_scope.dart';
import '../../../friends/data/models/friend_models.dart';
import '../../../friends/presentation/controllers/friends_controller.dart';

class CreateGroupPage extends StatefulWidget {
  final FriendsController? friendsController;
  final void Function(String name, List<String> memberIds)? onCreateGroup;

  const CreateGroupPage({super.key, this.friendsController, this.onCreateGroup});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchFriendController = TextEditingController();
  late final FriendsController _friendsController;
  late final bool _isInternalFriendsController;

  final Set<String> _selectedFriendIds = <String>{};
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _groupNameController.addListener(_onGroupNameChanged);
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

  void _onGroupNameChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _groupNameController.removeListener(_onGroupNameChanged);
    _groupNameController.dispose();
    _searchFriendController.dispose();
    if (_isInternalFriendsController) {
      _friendsController.dispose();
    }
    super.dispose();
  }

  bool get _canCreateGroup => _groupNameController.text.trim().isNotEmpty && _selectedFriendIds.length >= 2;

  void _handleCreateGroup() {
    if (!_canCreateGroup) return;
    if (widget.onCreateGroup != null) {
      widget.onCreateGroup!(_groupNameController.text.trim(), _selectedFriendIds.toList());
    }
  }

  void _loadData() {
    final token = AuthScope.of(context).accessToken;
    _friendsController.fetchFriends(token: token);
  }

  void _toggleFriendSelection(String friendId) {
    setState(() {
      if (_selectedFriendIds.contains(friendId)) {
        _selectedFriendIds.remove(friendId);
      } else {
        _selectedFriendIds.add(friendId);
      }
    });
  }

  void _onPickAvatar() {
    // Placeholder for picking group avatar
  }

  List<FriendUser> _getFilteredFriends(List<FriendUser> allFriends) {
    if (_searchFilter.trim().isEmpty) {
      return allFriends;
    }
    final q = _searchFilter.trim().toLowerCase();
    return allFriends.where((friend) {
      final name = friend.displayName.toLowerCase();
      final username = friend.username.toLowerCase();
      return name.contains(q) || username.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhóm mới', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              'Đã mời: ${_selectedFriendIds.length}',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _canCreateGroup ? _handleCreateGroup : null,
              child: const Text('Tạo mới', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _friendsController,
          builder: (context, _) {
            final allFriends = _friendsController.friends;
            final displayedFriends = _getFilteredFriends(allFriends);

            return Column(
              children: [
                // Group Name and Avatar Picker Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _onPickAvatar,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withAlpha(140),
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.primary.withAlpha(60), width: 1.2),
                              ),
                              child: Center(
                                child: HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: theme.colorScheme.primary, size: 24.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _groupNameController,
                          style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Đặt tên nhóm',
                            hintStyle: TextStyle(fontSize: 15, color: theme.colorScheme.onSurfaceVariant.withAlpha(140)),
                            border: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100))),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.8)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Friends Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surfaceContainerHigh : theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: theme.colorScheme.onSurfaceVariant.withAlpha(160), size: 18.0),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchFriendController,
                            onChanged: (val) {
                              setState(() {
                                _searchFilter = val;
                              });
                            },
                            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm bạn bè...',
                              hintStyle: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant.withAlpha(140)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchFriendController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchFriendController.clear();
                              setState(() {
                                _searchFilter = '';
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Icon(Icons.close_rounded, size: 18.0, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 16),

                // Friends List Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Danh sách bạn bè',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                      if (allFriends.isNotEmpty)
                        Text('${displayedFriends.length} bạn bè', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),

                // Friend List Content
                Expanded(
                  child: _friendsController.isLoading && allFriends.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : displayedFriends.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(icon: HugeIcons.strokeRoundedContact01, size: 40, color: theme.colorScheme.onSurfaceVariant.withAlpha(120)),
                              const SizedBox(height: 12),
                              Text(
                                _searchFilter.isNotEmpty ? 'Không tìm thấy bạn bè nào' : 'Chưa có bạn bè nào để tạo nhóm',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: displayedFriends.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, indent: 72, endIndent: 16),
                          itemBuilder: (context, index) {
                            final friend = displayedFriends[index];
                            final isSelected = _selectedFriendIds.contains(friend.userId);
                            final displayName = friend.displayName.isNotEmpty ? friend.displayName : friend.username;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: theme.colorScheme.primary, size: 22.0),
                              ),
                              title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                              subtitle: Text('@${friend.username}', style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant)),
                              trailing: Checkbox(
                                value: isSelected,
                                shape: const CircleBorder(),
                                activeColor: theme.colorScheme.primary,
                                onChanged: (_) => _toggleFriendSelection(friend.userId),
                              ),
                              onTap: () => _toggleFriendSelection(friend.userId),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
