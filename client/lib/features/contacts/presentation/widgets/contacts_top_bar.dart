import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ContactsTopBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClearSearch;
  final VoidCallback? onGroupManagementPressed;
  final VoidCallback? onFriendRequestsPressed;
  final int pendingRequestsCount;

  const ContactsTopBar({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.onClearSearch,
    this.onGroupManagementPressed,
    this.onFriendRequestsPressed,
    this.pendingRequestsCount = 0,
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
                    if (searchController != null)
                      ListenableBuilder(
                        listenable: searchController!,
                        builder: (context, _) {
                          if (searchController!.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return GestureDetector(
                            onTap: onClearSearch,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18.0,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
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

            // Friend Requests Button with optional Badge
            Tooltip(
              message: 'Lời mời kết bạn',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onFriendRequestsPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
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
                      if (pendingRequestsCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              pendingRequestsCount > 99
                                  ? '99+'
                                  : '$pendingRequestsCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
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
