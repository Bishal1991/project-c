import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/chat_list_widget.dart';
import 'profilePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _authService.syncUserProfile();
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const Center(
          child: Text(
            'Home Page',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      case 1:
        return const ChatListWidget();
      case 2:
        return const Center(
          child: Text(
            'Bonds',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      case 3:
        return const Center(
          child: Text(
            'Events',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      case 4:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTabTitle(_currentIndex)),
        elevation: 1,
      ),
      body: _buildTab(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Bonds',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Chat';
      case 2:
        return 'Bonds';
      case 3:
        return 'Events';
      case 4:
        return 'Profile';
      default:
        return '';
    }
  }
}
