import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../data/models/user_search_models.dart';
import '../controllers/user_search_controller.dart';

class UserSearchResultsView extends StatelessWidget {
  final UserSearchController controller;
  final ValueChanged<UserSearchResult>? onUserTap;
  final Widget? emptyPlaceholder;

  const UserSearchResultsView({
    super.key,
    required this.controller,
    this.onUserTap,
    this.emptyPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (controller.isLoading && controller.results.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.errorMessage != null && controller.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.hasQuery && controller.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
              ),
              const SizedBox(height: 12),
              Text(
                'Không tìm thấy người dùng phù hợp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Thử tìm với tên hiển thị hoặc username khác',
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

    if (controller.results.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: controller.results.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 68,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final user = controller.results[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedUser,
                color: theme.colorScheme.primary,
                size: 22.0,
              ),
            ),
            title: Text(
              user.displayName.isNotEmpty ? user.displayName : user.username,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              '@${user.username}',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
              size: 18.0,
            ),
            onTap: () => onUserTap?.call(user),
          );
        },
      );
    }

    return emptyPlaceholder ?? const SizedBox.shrink();
  }
}
