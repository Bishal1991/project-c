import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/bond_service.dart';
import '../widgets/chat_list_widget.dart';
import 'bond_page.dart';
import 'events_page.dart';
import 'home_page.dart';
import 'profilePage.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final _authService = AuthService();
  final _bondService = BondService();
  int _currentIndex = 1; // Default to Bonds tab so user sees their Mit Journey

  static const _darkBg = Color(0xFF110E20);
  static const _navBg = Color(0xFF120F21);
  static const _navBorder = Color(0xFF262238);
  static const _purple = Color(0xFF7B5CFA);
  static const _muted = Color(0xFF9C96B3);

  @override
  void initState() {
    super.initState();
    _authService.syncUserProfile();
  }



  // Order matches design: 0=Home, 1=Bonds, 2=Events, 3=Chat, 4=Me
  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return const BondPage();
      case 2:
        return const EventsPage();
      case 3:
        return const ChatListWidget();
      case 4:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Your bonds';
      case 2:
        return 'Events';
      case 3:
        return 'Chat';
      case 4:
        return 'Me';
      default:
        return '';
    }
  }

  Widget _badgedIcon(IconData iconData, int count) {
    if (count <= 0) return Icon(iconData);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(iconData),
        Positioned(
          right: -9,
          top: -5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
            decoration: BoxDecoration(
              color: _purple,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCustomHeaderTab = _currentIndex >= 0 && _currentIndex <= 3;
    return Scaffold(
      backgroundColor: isCustomHeaderTab ? _darkBg : null,
      appBar: isCustomHeaderTab
          ? null
          : AppBar(
              title: Text(_getTabTitle(_currentIndex)),
              elevation: 1,
            ),
      body: _buildTab(_currentIndex),
      bottomNavigationBar: StreamBuilder<Map<String, int>>(
        stream: _bondService.getNavBadgesStream(),
        builder: (context, badgeSnap) {
          final eventsCount = badgeSnap.data?['eventsCount'] ?? 0;
          final chatsCount = badgeSnap.data?['chatsCount'] ?? 0;

          return Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _navBorder, width: 1)),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: _navBg,
              selectedItemColor: _purple,
              unselectedItemColor: _muted,
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border),
                  activeIcon: Icon(Icons.favorite_border),
                  label: 'Bonds',
                ),
                BottomNavigationBarItem(
                  icon: _badgedIcon(
                    Icons.calendar_today_outlined,
                    eventsCount,
                  ),
                  activeIcon: _badgedIcon(Icons.calendar_today, eventsCount),
                  label: 'Events',
                ),
                BottomNavigationBarItem(
                  icon: _badgedIcon(Icons.chat_bubble_outline, chatsCount),
                  activeIcon: _badgedIcon(Icons.chat_bubble, chatsCount),
                  label: 'Chat',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Me',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
