import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, this.data = const {}});

  /// Current profile values from Supabase `public.users`.
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
    'Rai',
    'Limbu',
    'Sherpa',
    'Tharu',
    'Hindi',
  ];

  static const _bg = Color(0xFF110E20);
  static const _navBg = Color(0xFF120F21);
  static const _cardBg = Color(0xFF1B162E);
  static const _cardBorder = Color(0xFF2E2846);
  static const _purple = Color(0xFF7B5CFA);
  static const _mutedText = Color(0xFF9C96B3);

  final _authService = AuthService();

  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _community;
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
    _name = TextEditingController(
      text: (d['display_name'] ?? d['name'] ?? '') as String,
    );
    _username = TextEditingController(
      text: (d['username'] as String?) ?? '',
    );
    _community = TextEditingController(
      text: (d['community'] as String?) ?? '',
    );
    _age = TextEditingController(text: d['age']?.toString() ?? '');
    _city = TextEditingController(
      text: ((d['city'] ?? d['region']) as String?) ?? '',
    );
    _area = TextEditingController(text: (d['area'] as String?) ?? '');
    _languages = {
      ...((d['languages'] as List?)?.map((e) => e.toString()) ?? <String>[]),
    };
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _community.dispose();
    _age.dispose();
    _city.dispose();
    _area.dispose();
    super.dispose();
  }

  int? get _ageValue => int.tryParse(_age.text.trim());
  bool get _nameOk => _name.text.trim().length >= 2;
  bool get _ageOk =>
      _age.text.trim().isEmpty ||
      (_ageValue != null && _ageValue! >= 18 && _ageValue! <= 99);
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

    setState(() => _saving = true);
    try {
      await _authService.saveUserProfileDetails(
        displayName: _name.text.trim(),
        username: _username.text.trim().replaceAll('@', ''),
        community: _community.text.trim(),
        age: _ageValue,
        city: _city.text.trim(),
        area: _area.text.trim(),
        languages: _languages.toList(),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Save profile failed: $e');
      if (mounted) {
        setState(() => _saveError = 'Could not save profile: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = {..._defaultLanguages, ..._languages}.toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit profile',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const Text(
            'This is what people across communities will see when connecting with you.',
            style: TextStyle(color: _mutedText, fontSize: 14),
          ),
          const SizedBox(height: 20),
          _DarkField(
            label: 'Display Name',
            controller: _name,
            enabled: !_saving,
            textCapitalization: TextCapitalization.words,
            error: _submitted && !_nameOk ? 'Enter your name.' : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _DarkField(
            label: 'Miteri ID Handle (Username)',
            controller: _username,
            enabled: !_saving,
            helper: 'Others can search this ID to send you a bond request.',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _DarkField(
            label: 'Cultural Community (e.g. Rai, Newar, Sherpa, Tharu)',
            controller: _community,
            enabled: !_saving,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _DarkField(
            label: 'Age',
            controller: _age,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            error: _submitted && !_ageOk
                ? 'Enter an age between 18 and 99.'
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _DarkField(
            label: 'City / Region',
            controller: _city,
            enabled: !_saving,
            textCapitalization: TextCapitalization.words,
            helper: 'Other people see your city or region on your card.',
            error: _submitted && !_cityOk ? 'Enter your city or region.' : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _DarkField(
            label: 'Neighborhood Area (optional)',
            controller: _area,
            enabled: !_saving,
            textCapitalization: TextCapitalization.words,
            helper: 'Shown only after you both obtain Chinari.',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 22),
          const Text(
            'Languages',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
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
                  backgroundColor: _cardBg,
                  selectedColor: _purple.withValues(alpha: 0.28),
                  side: BorderSide(
                    color: _languages.contains(lang) ? _purple : _cardBorder,
                  ),
                  shape: const StadiumBorder(),
                  labelStyle: TextStyle(
                    fontSize: 13.5,
                    fontWeight: _languages.contains(lang)
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _languages.contains(lang)
                        ? const Color(0xFFD6C9FF)
                        : _mutedText,
                  ),
                ),
            ],
          ),
          if (_submitted && !_langOk)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Pick at least one language.',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          const SizedBox(height: 28),
          if (_saveError != null) ...[
            Text(
              _saveError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13.5),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _mutedText, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  const _DarkField({
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

  static const _cardBg = Color(0xFF1B162E);
  static const _cardBorder = Color(0xFF2E2846);
  static const _purple = Color(0xFF7B5CFA);
  static const _mutedText = Color(0xFF9C96B3);

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final borderColor = hasError ? Colors.redAccent : _cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: Colors.white),
          cursorColor: _purple,
          decoration: InputDecoration(
            filled: true,
            fillColor: _cardBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: _border(borderColor, hasError ? 1.5 : 1),
            enabledBorder: _border(borderColor, hasError ? 1.5 : 1),
            disabledBorder: _border(_cardBorder, 1),
            focusedBorder: _border(
              hasError ? Colors.redAccent : _purple,
              1.6,
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
            ),
          )
        else if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              helper!,
              style: const TextStyle(fontSize: 12, color: _mutedText),
            ),
          ),
      ],
    );
  }
}
