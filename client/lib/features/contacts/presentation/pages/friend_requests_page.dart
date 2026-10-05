import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/auth/auth_scope.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../friends/data/models/friend_models.dart';
import '../../../friends/presentation/controllers/friend_requests_controller.dart';
import '../../../profile/presentation/pages/user_profile_page.dart';

class FriendRequestsPage extends StatefulWidget {
  final FriendRequestsController? controller;

  const FriendRequestsPage({
    super.key,
    this.controller,
  });

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage>
    with SingleTickerProviderStateMixin {
  late final FriendRequestsController _controller;
  late final bool _isInternalController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isInternalController = false;
    } else {
      _controller = FriendRequestsController();
      _isInternalController = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _loadData() {
    final token = AuthScope.of(context).accessToken;
    _controller.fetchRequests(token: token);
  }

  void _onAccept(FriendRequestItem item) async {
    final token = AuthScope.of(context).accessToken;
    final success = await _controller.acceptRequest(
      requestId: item.requestId,
      token: token,
    );
    if (mounted && success) {
      AppToast.showSuccess(
        context,
        'Đã chấp nhận kết bạn với ${item.displayName.isNotEmpty ? item.displayName : item.username}',
      );
    }
  }

  void _onReject(FriendRequestItem item) async {
    final token = AuthScope.of(context).accessToken;
    final success = await _controller.rejectRequest(
      requestId: item.requestId,
      token: token,
    );
    if (mounted && success) {
      AppToast.showInfo(
        context,
        'Đã từ chối lời mời của ${item.displayName.isNotEmpty ? item.displayName : item.username}',
      );
    }
  }

  void _onCancel(FriendRequestItem item) async {
    final token = AuthScope.of(context).accessToken;
    final success = await _controller.cancelRequest(
      requestId: item.requestId,
      token: token,
    );
    if (mounted && success) {
      AppToast.showInfo(
        context,
        'Đã hủy lời mời kết bạn gửi đến ${item.displayName.isNotEmpty ? item.displayName : item.username}',
      );
    }
  }

  void _onOpenProfile(FriendRequestItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          username: item.username,
          initialDisplayName: item.displayName,
          initialUserId: item.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lời mời kết bạn'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đã nhận'),
            Tab(text: 'Đã gửi'),
          ],
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading &&
                _controller.receivedRequests.isEmpty &&
                _controller.sentRequests.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                // Received Tab
                RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: _controller.receivedRequests.isEmpty
                      ? _buildEmptyState(
                          theme,
                          HugeIcons.strokeRoundedMail01,
                          'Không có lời mời kết bạn nào',
                          'Khi có người gửi lời mời, bạn sẽ thấy ở đây',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: _controller.receivedRequests.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            indent: 68,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, index) {
                            final item = _controller.receivedRequests[index];
                            return ListTile(
                              leading: GestureDetector(
                                onTap: () => _onOpenProfile(item),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedUser,
                                    color: theme.colorScheme.primary,
                                    size: 24.0,
                                  ),
                                ),
                              ),
                              title: Text(
                                item.displayName.isNotEmpty
                                    ? item.displayName
                                    : item.username,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '@${item.username}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FilledButton(
                                    onPressed: () => _onAccept(item),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Đồng ý'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () => _onReject(item),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              ),
                              onTap: () => _onOpenProfile(item),
                            );
                          },
                        ),
                ),

                // Sent Tab
                RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: _controller.sentRequests.isEmpty
                      ? _buildEmptyState(
                          theme,
                          HugeIcons.strokeRoundedMailSend01,
                          'Không có lời mời đã gửi',
                          'Các lời mời kết bạn bạn đã gửi sẽ hiển thị ở đây',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: _controller.sentRequests.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            indent: 68,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, index) {
                            final item = _controller.sentRequests[index];
                            return ListTile(
                              leading: GestureDetector(
                                onTap: () => _onOpenProfile(item),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: theme.colorScheme.secondaryContainer,
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedUser,
                                    color: theme.colorScheme.secondary,
                                    size: 24.0,
                                  ),
                                ),
                              ),
                              title: Text(
                                item.displayName.isNotEmpty
                                    ? item.displayName
                                    : item.username,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '@${item.username}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: OutlinedButton(
                                onPressed: () => _onCancel(item),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Hủy'),
                              ),
                              onTap: () => _onOpenProfile(item),
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

  Widget _buildEmptyState(
    ThemeData theme,
    List<List<dynamic>> icon,
    String title,
    String subtitle,
  ) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: icon,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
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
}
