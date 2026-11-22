import 'package:flutter/material.dart';
import '../widgets/chat_list_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    // Home tab (empty as requested)
    const Center(
      child: Text(
        'Home Page',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    ),
    // Chat tab
    const ChatListWidget(),
    // Bonds tab
    const Center(
      child: Text(
        'Bonds',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    ),
    // Events tab
    const Center(
      child: Text(
        'Events',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    ),
    // Profile tab
    const Center(
      child: Text(
        'Profile',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTabTitle(_currentIndex)),
        elevation: 1,
      ),
      body: _pages[_currentIndex],
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
