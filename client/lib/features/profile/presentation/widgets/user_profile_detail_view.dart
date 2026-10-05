import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../friends/data/models/friend_models.dart';
import '../../../search/data/models/user_search_models.dart';

class UserProfileDetailView extends StatelessWidget {
  final UserPublicProfile profile;
  final FriendshipStatus friendshipStatus;
  final bool isSelf;
  final bool isActionLoading;
  final VoidCallback? onSendMessage;
  final VoidCallback? onAddFriend;
  final VoidCallback? onCancelRequest;
  final VoidCallback? onAcceptRequest;
  final VoidCallback? onRejectRequest;
  final VoidCallback? onUnfriend;
  final List<Widget>? customActions;

  const UserProfileDetailView({
    super.key,
    required this.profile,
    this.friendshipStatus = FriendshipStatus.none,
    this.isSelf = false,
    this.isActionLoading = false,
    this.onSendMessage,
    this.onAddFriend,
    this.onCancelRequest,
    this.onAcceptRequest,
    this.onRejectRequest,
    this.onUnfriend,
    this.customActions,
  });

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return 'Chưa rõ';
    try {
      final parsed = DateTime.parse(rawDate).toLocal();
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = parsed.year.toString();
      return '$day/$month/$year';
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainerHighest.withAlpha(100);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User Avatar
            CircleAvatar(
              radius: 52,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedUser,
                color: theme.colorScheme.primary,
                size: 52.0,
              ),
            ),
            const SizedBox(height: 18),

            // Display Name
            Text(
              profile.displayName.isNotEmpty
                  ? profile.displayName
                  : profile.username,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Username
            Text(
              '@${profile.username}',
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendar03,
                        color: theme.colorScheme.primary,
                        size: 20.0,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ngày tham gia',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(profile.createdAt),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (customActions != null)
              ...customActions!
            else if (!isSelf)
              _buildFriendshipActions(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendshipActions(BuildContext context, ThemeData theme) {
    if (isActionLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    switch (friendshipStatus) {
      case FriendshipStatus.accepted:
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onSendMessage,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedMessage01,
                  color: Colors.white,
                  size: 18.0,
                ),
                label: const Text('Nhắn tin'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onUnfriend,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedUserRemove01,
                  color: theme.colorScheme.error,
                  size: 18.0,
                ),
                label: Text(
                  'Hủy kết bạn',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      case FriendshipStatus.pendingSent:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCancelRequest,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  color: theme.colorScheme.error,
                  size: 18.0,
                ),
                label: Text(
                  'Hủy lời mời',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      case FriendshipStatus.pendingReceived:
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onAcceptRequest,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                  color: Colors.white,
                  size: 18.0,
                ),
                label: const Text('Đồng ý'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRejectRequest,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 18.0,
                ),
                label: const Text('Từ chối'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      case FriendshipStatus.none:
      case FriendshipStatus.rejected:
      case FriendshipStatus.blocked:
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onAddFriend,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUserAdd01,
                  color: Colors.white,
                  size: 18.0,
                ),
                label: const Text('Kết bạn'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}
