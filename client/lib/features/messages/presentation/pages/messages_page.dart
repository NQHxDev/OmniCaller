import 'package:flutter/material.dart';
import '../widgets/messages_top_bar.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onAddFriend() {
    // Action handler for Add Friend
  }

  void _onCreateGroup() {
    // Action handler for Create Group
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: MessagesTopBar(
        searchController: _searchController,
        onSearchChanged: (query) {
          // Search query handler
        },
        onAddFriend: _onAddFriend,
        onCreateGroup: _onCreateGroup,
      ),
      body: const SafeArea(
        top: false,
        child: SizedBox.expand(),
      ),
    );
  }
}
