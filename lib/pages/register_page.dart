import 'package:flutter/material.dart';

import '../services/email_auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'login_page.dart';
import 'profile_setup_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _service = EmailAuthService();

  bool _age = false;
  bool _terms = false;
  bool _loading = false;
  bool _submitted = false;
  String? _serverError;
  String? _serverField;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _usernameOk => EmailAuthService.validUsername(_username.text.trim());
  bool get _emailOk => EmailAuthService.validEmail(_email.text.trim());
  bool get _passwordOk => _password.text.length >= 8;
  bool get _formValid => _usernameOk && _emailOk && _passwordOk && _age && _terms;

  String? _fieldError(String field, bool ok, String message) {
    if (_serverField == field) return _serverError;
    return _submitted && !ok ? message : null;
  }

  void _clearServerError() {
    if (_serverError != null) {
      setState(() {
        _serverError = null;
        _serverField = null;
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _create() async {
    if (_loading) return;
    if (!_formValid) {
      setState(() => _submitted = true);
      return;
    }

    setState(() {
      _loading = true;
      _serverError = null;
      _serverField = null;
    });

    try {
      await _service.register(
        username: _username.text.trim(),
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
            (route) => false,
      );
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _serverError = e.message;
          _serverField = e.field ?? 'general';
        });
      }
    } catch (e) {
      debugPrint('Register failed: $e');
      if (mounted) {
        setState(() {
          _serverError = 'Something went wrong. Try again.';
          _serverField = 'general';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      subtitle:
      'Pick a username so the people you match with know what to call you.',
      children: [
        DarkField(
          label: 'Username',
          controller: _username,
          enabled: !_loading,
          action: TextInputAction.next,
          hints: const [AutofillHints.newUsername],
          helper: '3–20 letters, numbers, _ or .',
          error: _fieldError(
            'username',
            _usernameOk,
            'Use 3–20 letters, numbers, _ or .',
          ),
          onChanged: (_) => _clearServerError(),
        ),
        const SizedBox(height: 18),
        DarkField(
          label: 'Email',
          controller: _email,
          enabled: !_loading,
          keyboardType: TextInputType.emailAddress,
          action: TextInputAction.next,
          hints: const [AutofillHints.email],
          error: _fieldError('email', _emailOk, 'Enter a valid email address.'),
          onChanged: (_) => _clearServerError(),
        ),
        const SizedBox(height: 18),
        PasswordField(
          controller: _password,
          enabled: !_loading,
          newPassword: true,
          helper: 'At least 8 characters.',
          error: _fieldError(
            'password',
            _passwordOk,
            'Use at least 8 characters.',
          ),
          onChanged: (_) => _clearServerError(),
        ),
        const SizedBox(height: 20),
        AuthCheckbox(
          value: _age,
          label: 'I am 18 or older',
          error: _submitted && !_age ? 'Confirm your age to continue.' : null,
          onChanged: (v) => setState(() => _age = v),
        ),
        const SizedBox(height: 8),
        AuthCheckbox(
          value: _terms,
          label: 'I agree to the Community Guidelines and Privacy Policy',
          error: _submitted && !_terms
              ? 'Agree to the Community Guidelines and Privacy Policy to continue.'
              : null,
          onChanged: (v) => setState(() => _terms = v),
        ),
        if (_serverField == 'general' && _serverError != null)
          ErrorLine(_serverError!),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Create account',
          loading: _loading,
          looksDisabled: !_formValid,
          onPressed: _create,
        ),
        const SizedBox(height: 12),
        TextLinkButton(
          'Already have an account? Log in',
          onPressed: _loading
              ? null
              : () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  LoginPage(initialEmail: _email.text.trim()),
            ),
          ),
        ),
      ],
    );
  }
}