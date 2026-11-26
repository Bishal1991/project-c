import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/auth_widgets.dart';
import 'home_page.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  static const _titles = [
    'The basics',
    'What do you love?',
    'One optional question',
  ];
  static const _regions = [
    'Hill (Pahad)',
    'Mountain (Himal)',
    'Terai (Madhesh)',
    'Kathmandu Valley',
    'Outside Nepal',
  ];
  static const _interestOptions = [
    'Photography',
    'Hiking',
    'Music',
    'Football',
    'Cooking',
    'Travel',
    'Reading',
    'Movies',
    'Art',
    'Dancing',
  ];
  static const _festivalOptions = [
    'Lhosar',
    'Dashain',
    'Tihar',
    'Holi',
    'Teej',
    'Chhath',
    'Eid',
    'Buddha Jayanti',
    'Christmas',
  ];
  static const _preferNot = 'Prefer not to say';
  static const _communities = [
    _preferNot,
    'Brahmin',
    'Chhetri',
    'Newar',
    'Gurung',
    'Magar',
    'Tamang',
    'Rai',
    'Limbu',
    'Tharu',
    'Madhesi',
    'Muslim',
    'Other',
  ];

  final _name = TextEditingController();
  final _age = TextEditingController();
  final _college = TextEditingController();
  String? _region;
  final Set<String> _interests = {};
  final Set<String> _festivals = {};
  String _ethnic = _preferNot;

  int _step = 0;
  bool _tried1 = false;
  bool _tried2 = false;
  bool _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _college.dispose();
    super.dispose();
  }

  int? get _ageValue => int.tryParse(_age.text.trim());
  bool get _nameOk => _name.text.trim().length >= 2;
  bool get _ageOk => _ageValue != null && _ageValue! >= 18 && _ageValue! <= 99;
  bool get _collegeOk => _college.text.trim().isNotEmpty;
  bool get _regionOk => _region != null;

  void _next1() {
    setState(() => _tried1 = true);
    if (_nameOk && _ageOk && _collegeOk && _regionOk) {
      FocusScope.of(context).unfocus();
      setState(() => _step = 1);
    }
  }

  void _next2() {
    setState(() => _tried2 = true);
    if (_interests.isNotEmpty) setState(() => _step = 2);
  }

  Future<void> _finish({required bool skip}) async {
    if (_saving) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _saveError = 'You are logged out. Please log in again.');
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _name.text.trim(),
        'age': _ageValue,
        'college': _college.text.trim(),
        'homeRegion': _region,
        'interests': _interests.toList(),
        'festivals': _festivals.toList(),
        'ethnicGroup': (skip || _ethnic == _preferNot) ? null : _ethnic,
        'profileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() =>
        _saveError = e.message ?? 'Could not save. Please try again.');
      }
    } catch (e) {
      debugPrint('Save profile failed: $e');
      if (mounted) {
        setState(() => _saveError = 'Could not save. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Widget> _stepOne() => [
    DarkField(
      label: 'Name',
      controller: _name,
      capitalization: TextCapitalization.words,
      error: _tried1 && !_nameOk ? 'Enter your name.' : null,
      onChanged: (_) {
        if (_tried1) setState(() {});
      },
    ),
    const SizedBox(height: 18),
    DarkField(
      label: 'Age',
      controller: _age,
      keyboardType: TextInputType.number,
      formatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      error: _tried1 && !_ageOk ? 'Enter an age between 18 and 99.' : null,
      onChanged: (_) {
        if (_tried1) setState(() {});
      },
    ),
    const SizedBox(height: 18),
    DarkField(
      label: 'College',
      controller: _college,
      capitalization: TextCapitalization.words,
      error: _tried1 && !_collegeOk ? 'Enter your college.' : null,
      onChanged: (_) {
        if (_tried1) setState(() {});
      },
    ),
    const SizedBox(height: 18),
    DarkDropdown(
      label: 'Home region',
      value: _region,
      items: _regions,
      hint: 'Select your region',
      error: _tried1 && !_regionOk ? 'Pick your home region.' : null,
      onChanged: (v) => setState(() => _region = v),
    ),
    const SizedBox(height: 28),
    PrimaryButton(label: 'Continue', onPressed: _next1),
  ];

  Widget _chips(List<String> options, Set<String> selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          _SelectChip(
            label: option,
            selected: selected.contains(option),
            onTap: () => setState(() {
              selected.contains(option)
                  ? selected.remove(option)
                  : selected.add(option);
            }),
          ),
      ],
    );
  }

  List<Widget> _stepTwo() => [
    const Text('Interests & hobbies', style: AuthText.label),
    const SizedBox(height: 10),
    _chips(_interestOptions, _interests),
    if (_tried2 && _interests.isEmpty)
      const ErrorLine('Pick at least one interest.'),
    const SizedBox(height: 24),
    const Text('Festivals you celebrate', style: AuthText.label),
    const SizedBox(height: 10),
    _chips(_festivalOptions, _festivals),
    const SizedBox(height: 28),
    PrimaryButton(label: 'Continue', onPressed: _next2),
  ];

  List<Widget> _stepThree() => [
    DarkDropdown(
      label: 'Ethnic group / community',
      labelSuffix: ' (optional)',
      value: _ethnic,
      items: _communities,
      onChanged: (v) => setState(() => _ethnic = v ?? _preferNot),
    ),
    const SizedBox(height: 12),
    const Text(
      "We ask this only so we can introduce you to people from backgrounds different from yours — it's never shown publicly, ranked, or required.",
      style: TextStyle(fontSize: 14, height: 1.45, color: AuthColors.muted),
    ),
    const SizedBox(height: 24),
    if (_saveError != null) ...[
      ErrorLine(_saveError!),
      const SizedBox(height: 12),
    ],
    PrimaryButton(
      label: 'Finish & see matches',
      loading: _saving,
      onPressed: () => _finish(skip: false),
    ),
    const SizedBox(height: 8),
    TextLinkButton(
      'Skip this question',
      onPressed: _saving ? null : () => _finish(skip: true),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final body = _step == 0
        ? _stepOne()
        : _step == 1
        ? _stepTwo()
        : _stepThree();

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) setState(() => _step--);
      },
      child: AuthScaffold(
        top: _Progress(step: _step),
        title: _titles[_step],
        children: body,
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: BoxDecoration(
                color: i <= step ? AuthColors.primary : AuthColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AuthColors.primary : AuthColors.field,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AuthColors.primary : AuthColors.border,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : AuthColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}