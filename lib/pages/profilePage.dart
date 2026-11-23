import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'LoginPage.dart';

/// Profile content only. No Scaffold, app bar or bottom nav:
/// your parent page already provides those.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();

  // Neutral tokens only (no accent colors). Match _bg to your app background.
  static const _bg = Color(0xFF0F1526);
  static const _card = Color(0xFF161D31);
  static const _border = Color(0xFF2A3350);
  static const _textMuted = Color(0xFF9AA3BD);

  // ---- Sample data: replace with your real user data ----
  final String _name = 'Asmita Lama';
  final int _age = 21;
  final String _university = 'Tribhuvan University';
  final String _city = 'Kathmandu';
  final String _homeRegion = 'Hill (Pahad)';
  final String _community = 'Prefer not to say';
  final List<String> _interests = ['Photography', 'Hiking'];
  final int _bonds = 12;
  final int _events = 5;

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You will need to log in again to use the app.',
          style: TextStyle(color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _authService.signOut(); // make sure AuthService has signOut()
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Loginpage()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                // TODO: open edit profile page
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStats(),
          const SizedBox(height: 16),
          _buildAboutCard(),
          const SizedBox(height: 16),
          _buildInterestsCard(),
          const SizedBox(height: 28),
          const Text(
            'Settings',
            style: TextStyle(
              color: _textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          _settingsTile(
            icon: Icons.shield_outlined,
            label: 'Privacy & safety',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _settingsTile(
            icon: Icons.notifications_none_rounded,
            label: 'Notification preferences',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _settingsTile(
            icon: Icons.logout_rounded,
            label: 'Log out',
            showChevron: false,
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }

  // ---------- Sections ----------

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _border, width: 2),
          ),
          child: CircleAvatar(
            radius: 52,
            backgroundColor: const Color(0xFFEFF2F8),
            child: Text(
              _name.isNotEmpty ? _name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: _bg,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$_name, $_age',
          style: const TextStyle(
            fontFamily: 'serif',
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 16, color: _textMuted),
            const SizedBox(width: 6),
            Text(
              '$_university · $_city',
              style: const TextStyle(color: _textMuted, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _stat('$_bonds', 'Bonds'),
          Container(width: 1, height: 32, color: _border),
          _stat('$_events', 'Events'),
          Container(width: 1, height: 32, color: _border),
          _stat('${_interests.length}', 'Interests'),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(Icons.landscape_outlined, 'Home region'),
          const SizedBox(height: 10),
          _chip(_homeRegion),
          const SizedBox(height: 20),
          _fieldLabel(Icons.groups_2_outlined, 'Ethnic group / community'),
          const SizedBox(height: 10),
          _chip(_community),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.lock_outline_rounded, size: 14, color: _textMuted),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Only you can see this unless you choose to share it.',
                  style: TextStyle(color: _textMuted, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(Icons.interests_outlined, 'Interests'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _interests.map(_chip).toList(),
          ),
        ],
      ),
    );
  }

  // ---------- Reusable pieces ----------

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: _card,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: _border),
  );

  Widget _fieldLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _textMuted),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: _textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showChevron)
                const Icon(Icons.chevron_right_rounded, color: _textMuted),
            ],
          ),
        ),
      ),
    );
  }
}