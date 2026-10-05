import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

enum MessagesMenuAction {
  addFriend,
  createGroup,
}

class MessagesTopBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClearSearch;
  final VoidCallback? onAddFriend;
  final VoidCallback? onCreateGroup;

  const MessagesTopBar({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.onClearSearch,
    this.onAddFriend,
    this.onCreateGroup,
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

            // Plus Menu Button
            Theme(
              data: theme.copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color: theme.colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isDark
                          ? theme.colorScheme.outlineVariant.withAlpha(80)
                          : theme.colorScheme.outlineVariant.withAlpha(40),
                    ),
                  ),
                  elevation: 6,
                ),
              ),
              child: PopupMenuButton<MessagesMenuAction>(
                offset: const Offset(0, 48),
                onSelected: (action) {
                  switch (action) {
                    case MessagesMenuAction.addFriend:
                      onAddFriend?.call();
                      break;
                    case MessagesMenuAction.createGroup:
                      onCreateGroup?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<MessagesMenuAction>(
                    value: MessagesMenuAction.addFriend,
                    height: 44,
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedUserAdd01,
                          color: theme.colorScheme.onSurface,
                          size: 18.0,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Thêm bạn',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem<MessagesMenuAction>(
                    value: MessagesMenuAction.createGroup,
                    height: 44,
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedUserGroup,
                          color: theme.colorScheme.onSurface,
                          size: 18.0,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Tạo nhóm',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: searchBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedAdd01,
                    color: theme.colorScheme.primary,
                    size: 20.0,
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
