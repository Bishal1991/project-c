import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/auth_widgets.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, this.data = const {}});

  /// Current profile values from Firestore (may be empty).
  final Map<String, dynamic> data;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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

  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _college;
  late String? _region;
  late String _ethnic;
  late final Set<String> _interests;
  late final Set<String> _festivals;

  bool _saving = false;
  bool _submitted = false;
  String? _saveError;

  List<String> _list(dynamic v) =>
      (v as List?)?.map((e) => e.toString()).toList() ?? <String>[];

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _name = TextEditingController(text: (d['name'] as String?) ?? '');
    _age = TextEditingController(text: d['age']?.toString() ?? '');
    _college = TextEditingController(text: (d['college'] as String?) ?? '');
    _region = d['homeRegion'] as String?;
    _ethnic = (d['ethnicGroup'] as String?) ?? _preferNot;
    _interests = {..._list(d['interests'])};
    _festivals = {..._list(d['festivals'])};
  }

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
  bool get _interestsOk => _interests.isNotEmpty;
  bool get _valid =>
      _nameOk && _ageOk && _collegeOk && _regionOk && _interestsOk;

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _submitted = true;
      _saveError = null;
    });
    if (!_valid) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _saveError = 'You are logged out. Please log in again.');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _name.text.trim(),
        'age': _ageValue,
        'college': _college.text.trim(),
        'homeRegion': _region,
        'interests': _interests.toList(),
        'festivals': _festivals.toList(),
        'ethnicGroup': _ethnic == _preferNot ? null : _ethnic,
        'profileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) Navigator.pop(context, true);
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

  Widget _chips(List<String> defaults, Set<String> selected) {
    final options = {...defaults, ...selected}.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          _SelectChip(
            label: option,
            selected: selected.contains(option),
            onTap: _saving
                ? null
                : () => setState(() {
              selected.contains(option)
                  ? selected.remove(option)
                  : selected.add(option);
            }),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final regionItems = {
      ..._regions,
      if (_region != null) _region!,
    }.toList();
    final communityItems = {..._communities, _ethnic}.toList();

    return AuthScaffold(
      title: 'Edit profile',
      subtitle: 'This is what the people you match with will see.',
      children: [
        DarkField(
          label: 'Name',
          controller: _name,
          enabled: !_saving,
          capitalization: TextCapitalization.words,
          error: _submitted && !_nameOk ? 'Enter your name.' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        DarkField(
          label: 'Age',
          controller: _age,
          enabled: !_saving,
          keyboardType: TextInputType.number,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          error: _submitted && !_ageOk ? 'Enter an age between 18 and 99.' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        DarkField(
          label: 'College',
          controller: _college,
          enabled: !_saving,
          capitalization: TextCapitalization.words,
          error: _submitted && !_collegeOk ? 'Enter your college.' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        DarkDropdown(
          label: 'Home region',
          value: _region,
          items: regionItems,
          hint: 'Select your region',
          error: _submitted && !_regionOk ? 'Pick your home region.' : null,
          onChanged: _saving ? null : (v) => setState(() => _region = v),
        ),
        const SizedBox(height: 24),
        const Text('Interests & hobbies', style: AuthText.label),
        const SizedBox(height: 10),
        _chips(_interestOptions, _interests),
        if (_submitted && !_interestsOk)
          const ErrorLine('Pick at least one interest.'),
        const SizedBox(height: 24),
        const Text('Festivals you celebrate', style: AuthText.label),
        const SizedBox(height: 10),
        _chips(_festivalOptions, _festivals),
        const SizedBox(height: 24),
        DarkDropdown(
          label: 'Ethnic group / community',
          labelSuffix: ' (optional)',
          value: _ethnic,
          items: communityItems,
          onChanged: _saving
              ? null
              : (v) => setState(() => _ethnic = v ?? _preferNot),
        ),
        const SizedBox(height: 6),
        const Text(
          'Never shown publicly, ranked, or required.',
          style: TextStyle(fontSize: 12, color: AuthColors.muted),
        ),
        const SizedBox(height: 28),
        if (_saveError != null) ...[
          ErrorLine(_saveError!),
          const SizedBox(height: 12),
        ],
        PrimaryButton(
          label: 'Save changes',
          loading: _saving,
          looksDisabled: !_valid,
          onPressed: _save,
        ),
        const SizedBox(height: 8),
        TextLinkButton(
          'Cancel',
          onPressed: _saving ? null : () => Navigator.pop(context),
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
  final VoidCallback? onTap;

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