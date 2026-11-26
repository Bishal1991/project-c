import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/auth_widgets.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, this.data = const {}});

  /// Current profile values from Firestore (may be empty for a new account).
  final Map<String, dynamic> data;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const _defaultLanguages = [
    'Nepali',
    'English',
    'Newari',
    'Maithili',
    'Bhojpuri',
    'Tamang',
    'Gurung',
    'Hindi',
  ];

  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _city;
  late final TextEditingController _area;
  late final Set<String> _languages;

  bool _saving = false;
  bool _submitted = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _name = TextEditingController(text: (d['name'] as String?) ?? '');
    _age = TextEditingController(text: d['age']?.toString() ?? '');
    _city = TextEditingController(text: (d['city'] as String?) ?? '');
    _area = TextEditingController(text: (d['area'] as String?) ?? '');
    _languages = {
      ...((d['languages'] as List?)?.map((e) => e.toString()) ?? <String>[]),
    };
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _city.dispose();
    _area.dispose();
    super.dispose();
  }

  int? get _ageValue => int.tryParse(_age.text.trim());
  bool get _nameOk => _name.text.trim().length >= 2;
  bool get _ageOk => _ageValue != null && _ageValue! >= 18 && _ageValue! <= 99;
  bool get _cityOk => _city.text.trim().isNotEmpty;
  bool get _langOk => _languages.isNotEmpty;
  bool get _valid => _nameOk && _ageOk && _cityOk && _langOk;

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
        'city': _city.text.trim(),
        'area': _area.text.trim(),
        'languages': _languages.toList(),
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

  @override
  Widget build(BuildContext context) {
    final options = {..._defaultLanguages, ..._languages}.toList();

    return AuthScaffold(
      title: 'Edit profile',
      subtitle: 'This is what the people you match with will see.',
      children: [
        _LabeledField(
          label: 'Name',
          controller: _name,
          enabled: !_saving,
          textCapitalization: TextCapitalization.words,
          error: _submitted && !_nameOk ? 'Enter your name.' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        _LabeledField(
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
        _LabeledField(
          label: 'City',
          controller: _city,
          enabled: !_saving,
          textCapitalization: TextCapitalization.words,
          helper: 'Other people see only your city.',
          error: _submitted && !_cityOk ? 'Enter your city.' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        _LabeledField(
          label: 'Area (optional)',
          controller: _area,
          enabled: !_saving,
          textCapitalization: TextCapitalization.words,
          helper: 'Shown only after you both say namaste.',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 22),
        const Text('Languages', style: AuthText.label),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final lang in options)
              FilterChip(
                label: Text(lang),
                selected: _languages.contains(lang),
                showCheckmark: false,
                onSelected: _saving
                    ? null
                    : (on) => setState(() {
                  on ? _languages.add(lang) : _languages.remove(lang);
                }),
                backgroundColor: Colors.white,
                selectedColor: AuthColors.primary.withValues(alpha: 0.14),
                side: BorderSide(
                  color: _languages.contains(lang)
                      ? AuthColors.primary
                      : AuthColors.border,
                ),
                shape: const StadiumBorder(),
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: _languages.contains(lang)
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: _languages.contains(lang)
                      ? AuthColors.primary
                      : AuthColors.ink,
                ),
              ),
          ],
        ),
        if (_submitted && !_langOk) const ErrorLine('Pick at least one language.'),
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.enabled = true,
    this.error,
    this.helper,
    this.keyboardType,
    this.formatters,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? error;
  final String? helper;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: width),
  );

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final color = hasError ? AuthColors.error : AuthColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AuthText.label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: AuthColors.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: _border(color, hasError ? 1.5 : 1),
            enabledBorder: _border(color, hasError ? 1.5 : 1),
            disabledBorder: _border(AuthColors.border, 1),
            focusedBorder: _border(
              hasError ? AuthColors.error : AuthColors.primary,
              1.8,
            ),
          ),
        ),
        if (hasError)
          ErrorLine(error!)
        else if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              helper!,
              style: const TextStyle(fontSize: 12, color: AuthColors.muted),
            ),
          ),
      ],
    );
  }
}