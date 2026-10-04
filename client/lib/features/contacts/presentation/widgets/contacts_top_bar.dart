import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ContactsTopBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onGroupManagementPressed;
  final VoidCallback? onFriendRequestsPressed;

  const ContactsTopBar({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.onGroupManagementPressed,
    this.onFriendRequestsPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final searchBgColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainerHighest.withAlpha(120);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Search Input Field
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: searchBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
                      size: 18.0,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant
                                .withAlpha(140),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Group Management Button
            Tooltip(
              message: 'Quản lý nhóm',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onGroupManagementPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: searchBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedUserGroup,
                      color: theme.colorScheme.primary,
                      size: 20.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Friend Requests Button
            Tooltip(
              message: 'Lời mời kết bạn',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onFriendRequestsPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: searchBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedMailAdd01,
                      color: theme.colorScheme.primary,
                      size: 20.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
