import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/auth/auth_scope.dart';
import '../../../../core/theme/theme_scope.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
              AuthScope.of(context).logout();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = ThemeScope.of(context);
    final isDarkMode = themeController.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            // Dark / Light Theme Toggle Switch
            SwitchListTile.adaptive(
              secondary: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedMoon02,
                  color: theme.colorScheme.primary,
                  size: 20.0,
                ),
              ),
              title: const Text(
                'Giao diện tối',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              value: isDarkMode,
              onChanged: (value) {
                themeController.toggleTheme(value);
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            // Logout Option
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedLogout01,
                  color: theme.colorScheme.error,
                  size: 20.0,
                ),
              ),
              title: Text(
                'Đăng xuất',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}
