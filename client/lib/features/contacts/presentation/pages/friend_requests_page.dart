import 'package:flutter/material.dart';

class FriendRequestsPage extends StatelessWidget {
  const FriendRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lời mời kết bạn'),
        centerTitle: false,
      ),
      body: const SafeArea(
        child: SizedBox.expand(),
      ),
    );
  }
}
