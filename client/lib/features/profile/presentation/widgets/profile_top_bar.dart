import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ProfileTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSettingsPressed;

  const ProfileTopBar({
    super.key,
    this.onSettingsPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final buttonBgColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainerHighest.withAlpha(120);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Spacer(),
            // Settings Icon Button on the right edge
            Tooltip(
              message: 'Cài đặt',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSettingsPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: buttonBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSettings01,
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
