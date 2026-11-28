import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/auth_widgets.dart';
import 'editprofilepage.dart';
import 'welcome_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _edit(BuildContext context, Map<String, dynamic> data) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(data: data)),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    }
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon.')),
    );
  }

  void _goToWelcome(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
          (route) => false,
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuthColors.field,
        title: const Text('Log out?'),
        content: const Text(
          'You will need your phone number and a new code to log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: AuthColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    _goToWelcome(context);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: SafeArea(
        child: uid == null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'You are logged out.',
                  style: TextStyle(color: AuthColors.ink),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Log in',
                  onPressed: () => _goToWelcome(context),
                ),
              ],
            ),
          ),
        )
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Could not load your profile. Check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AuthColors.muted),
                  ),
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AuthColors.primary,
                ),
              );
            }
            return _content(context, snap.data!.data() ?? {});
          },
        ),
      ),
    );
  }

  List<String> _list(dynamic v) =>
      (v as List?)?.map((e) => e.toString()).toList() ?? <String>[];

  Widget _content(BuildContext context, Map<String, dynamic> data) {
    final name = (data['name'] as String?)?.trim() ?? '';
    final age = data['age']?.toString() ?? '';
    final college = (data['college'] as String?)?.trim() ?? '';
    final region = (data['homeRegion'] as String?)?.trim() ?? '';
    final interests = _list(data['interests']);
    final festivals = _list(data['festivals']);

    final details =
    [age, college, region].where((s) => s.isNotEmpty).join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        Row(
          children: [
            const Expanded(child: Text('My profile', style: AuthText.heading)),
            TextButton(
              onPressed: () => _edit(context, data),
              style: TextButton.styleFrom(foregroundColor: AuthColors.primary),
              child: const Text(
                'Edit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFF2A2350),
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC9B8F5),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Add your name' : name,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AuthColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details.isEmpty ? 'Tap Edit to finish your profile' : details,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AuthColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _SectionLabel('About you'),
        _NavRow(
          title: 'Interests',
          trailing: interests.isEmpty ? 'Add' : interests.join(', '),
          onTap: () => _edit(context, data),
        ),
        const _Line(),
        _NavRow(
          title: 'Festivals',
          trailing: festivals.isEmpty ? 'Add' : festivals.join(', '),
          onTap: () => _edit(context, data),
        ),
        const _Line(),
        const _SectionLabel('Privacy'),
        _NavRow(
          title: 'Privacy & safety',
          onTap: () => _comingSoon(context),
        ),
        const _Line(),
        const _SectionLabel('Settings'),
        _NavRow(
          title: 'Notification preferences',
          onTap: () => _comingSoon(context),
        ),
        const _Line(),
        InkWell(
          onTap: () => _logout(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'Log out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AuthColors.error,
              ),
            ),
          ),
        ),
        const _Line(),
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Others see only your region. Your place is shown only after you both say namaste.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AuthColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AuthColors.ink,
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.title, this.trailing, required this.onTap});

  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: AuthColors.ink),
            ),
            if (trailing != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    trailing!,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AuthColors.muted,
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AuthColors.muted),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AuthColors.border);
  }
}