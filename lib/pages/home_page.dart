import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/bonds_widget.dart';
import '../widgets/chat_list_widget.dart';
import 'login_page.dart';

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

  void _showEditNameDialog() {
    final nameController = TextEditingController(
      text: _authService.currentUser?.displayName ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await _authService.updateDisplayName(newName);
                await _authService.syncUserProfile(displayName: newName);
                if (mounted) setState(() {});
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Widget _buildProfileTab() {
    final user = _authService.currentUser;
    final name = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'User';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        CircleAvatar(
          radius: 36,
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        if (user?.email != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(user!.email!, style: const TextStyle(color: Colors.grey)),
          ),
        ],
        if (user?.phoneNumber != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              user!.phoneNumber!,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Edit Display Name'),
          onTap: _showEditNameDialog,
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          onTap: _handleLogout,
        ),
      ],
    );
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
        return const BondsWidget();
      case 3:
        return const Center(
          child: Text(
            'Events',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      case 4:
        return _buildProfileTab();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBondsTab = _currentIndex == 2;
    return Scaffold(
      backgroundColor: isBondsTab ? const Color(0xFF0F0D1D) : null,
      appBar: AppBar(
        title: Text(
          isBondsTab ? 'Your bonds' : _getTabTitle(_currentIndex),
          style: isBondsTab
              ? const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )
              : null,
        ),
        backgroundColor: isBondsTab ? const Color(0xFF0F0D1D) : null,
        elevation: isBondsTab ? 0 : 1,
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
