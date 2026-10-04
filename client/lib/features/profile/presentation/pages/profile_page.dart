import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: ProfileTopBar(
        onSettingsPressed: _onSettingsPressed,
      ),
      body: const SafeArea(
        top: false,
        child: SizedBox.expand(),
      ),
    );
  }
}
