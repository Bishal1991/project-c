import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();

  static const _bg = Color(0xFF110E20);
  static const _cardBg = Color(0xFF1B162E);
  static const _cardBorder = Color(0xFF2E2846);
  static const _purple = Color(0xFF7B5CFA);
  static const _mutedText = Color(0xFF9C96B3);

  Future<void> _edit(Map<String, dynamic> data) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(data: data)),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated in Supabase.'),
          backgroundColor: _purple,
        ),
      );
    }
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon.')),
    );
  }

  void _goToLogin() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: const Text(
          'Log out?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You can sign back in anytime with your phone number or Google account.',
          style: TextStyle(color: _mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _mutedText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _authService.signOut();
    if (!mounted) return;
    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: user == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'You are logged out.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _goToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Log in'),
                      ),
                    ],
                  ),
                ),
              )
            : StreamBuilder<Map<String, dynamic>>(
                stream: _authService.getUserProfileStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: _purple),
                    );
                  }
                  final data = snap.data ?? <String, dynamic>{};
                  return _content(user, data);
                },
              ),
      ),
    );
  }

  Widget _content(User user, Map<String, dynamic> data) {
    final name =
        (data['display_name'] as String?)?.trim() ??
        user.displayName ??
        'Miteri User';
    final username = (data['username'] as String?)?.trim() ?? '';
    final handle = username.isNotEmpty
        ? '@$username'
        : '@${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';
    final age = data['age']?.toString() ?? '';
    final community = (data['community'] as String?)?.trim() ?? '';
    final city =
        (data['city'] as String?)?.trim() ??
        (data['region'] as String?)?.trim() ??
        '';
    final area = (data['area'] as String?)?.trim() ?? '';
    final phone =
        (data['phone_number'] as String?)?.trim() ?? user.phoneNumber ?? '';
    final languages =
        (data['languages'] as List?)?.map((e) => e.toString()).toList() ??
        <String>[];

    final details = [
      if (age.isNotEmpty) '$age yrs',
      if (community.isNotEmpty) community,
      if (city.isNotEmpty) city,
      if (area.isNotEmpty) area,
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My profile',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            TextButton.icon(
              onPressed: () => _edit(data),
              icon: const Icon(Icons.edit_outlined, size: 18, color: _purple),
              label: const Text(
                'Edit',
                style: TextStyle(
                  color: _purple,
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Profile summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: _purple.withValues(alpha: 0.25),
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFCDBDFF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: handle));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied Miteri ID $handle'),
                                backgroundColor: _purple,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ID: $handle',
                                style: const TextStyle(
                                  color: Color(0xFFBBA8FF),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: Color(0xFFBBA8FF),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          details.isEmpty
                              ? 'Tap Edit to add your community, city & age'
                              : details,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: _mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (phone.isNotEmpty || (user.email?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 14),
                const Divider(color: _cardBorder, height: 1),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    if (phone.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 15,
                            color: _mutedText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            phone,
                            style: const TextStyle(
                              color: _mutedText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    if (user.email != null && user.email!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 15,
                            color: _mutedText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.email!,
                            style: const TextStyle(
                              color: _mutedText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Details & Settings Card
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NavRow(
                icon: Icons.translate_rounded,
                title: 'Languages spoken',
                trailing: languages.isEmpty ? 'Add' : languages.join(', '),
                onTap: () => _edit(data),
              ),
              const Divider(color: _cardBorder, height: 1),
              _NavRow(
                icon: Icons.people_outline_rounded,
                title: 'Cultural community',
                trailing: community.isEmpty ? 'Add' : community,
                onTap: () => _edit(data),
              ),
              const Divider(color: _cardBorder, height: 1),
              _NavRow(
                icon: Icons.shield_outlined,
                title: 'Privacy & safety',
                onTap: _comingSoon,
              ),
              const Divider(color: _cardBorder, height: 1),
              _NavRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notification preferences',
                onTap: _comingSoon,
              ),
              const Divider(color: _cardBorder, height: 1),
              InkWell(
                onTap: _logout,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.only(top: 16, left: 4, right: 4),
          child: Text(
            'Friends can search your Miteri ID handle or phone number to send a Chinari bond request. Your neighborhood area is shown only after you both obtain Chinari.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: _mutedText,
            ),
          ),
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF9C96B3), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15.5, color: Colors.white),
              ),
            ),
            if (trailing != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    trailing!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9C96B3),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9C96B3),
            ),
          ],
        ),
      ),
    );
  }
}
