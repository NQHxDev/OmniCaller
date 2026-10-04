import 'package:flutter/material.dart';

class GroupsManagementPage extends StatelessWidget {
  const GroupsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý nhóm'),
        centerTitle: false,
      ),
      body: const SafeArea(
        child: SizedBox.expand(),
      ),
    );
  }
}
