import 'package:client/features/contacts/presentation/pages/contacts_page.dart';
import 'package:client/features/friends/presentation/controllers/friends_controller.dart';
import 'package:client/features/messages/presentation/pages/messages_page.dart';
import 'package:client/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  final FriendsController? friendsController;

  const HomePage({
    super.key,
    this.friendsController,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final FriendsController _friendsController;
  late final bool _isInternalFriendsController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    if (widget.friendsController != null) {
      _friendsController = widget.friendsController!;
      _isInternalFriendsController = false;
    } else {
      _friendsController = FriendsController();
      _isInternalFriendsController = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (_isInternalFriendsController) {
      _friendsController.dispose();
    }
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          MessagesPage(friendsController: _friendsController),
          ContactsPage(friendsController: _friendsController),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
