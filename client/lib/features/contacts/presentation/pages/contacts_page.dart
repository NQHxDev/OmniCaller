import 'package:flutter/material.dart';
import '../widgets/contacts_top_bar.dart';
import 'friend_requests_page.dart';
import 'groups_management_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onGroupManagementPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GroupsManagementPage(),
      ),
    );
  }

  void _onFriendRequestsPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FriendRequestsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: ContactsTopBar(
        searchController: _searchController,
        onSearchChanged: (query) {
          // Search query handler
        },
        onGroupManagementPressed: _onGroupManagementPressed,
        onFriendRequestsPressed: _onFriendRequestsPressed,
      ),
      body: const SafeArea(
        top: false,
        child: SizedBox.expand(),
      ),
    );
  }
}
