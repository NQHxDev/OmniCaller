import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/auth/auth_scope.dart';
import '../widgets/profile_top_bar.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _onSettingsPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final authController = AuthScope.of(context);
    final user = authController.currentUser;

    return Scaffold(
      appBar: ProfileTopBar(
        onSettingsPressed: _onSettingsPressed,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                // User Avatar
                CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedUser,
                    color: theme.colorScheme.primary,
                    size: 40.0,
                  ),
                ),
                const SizedBox(height: 16),
                // Display Name
                Text(
                  user?.displayName.isNotEmpty == true
                      ? user!.displayName
                      : 'Người dùng',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
