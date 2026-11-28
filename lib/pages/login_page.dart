import 'package:flutter/material.dart';

import '../services/email_auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'home_page.dart';
import 'profile_setup_page.dart';
import 'register_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _email;
  final _password = TextEditingController();
  final _service = EmailAuthService();

  bool _loading = false;
  bool _submitted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _emailOk => EmailAuthService.validEmail(_email.text.trim());
  bool get _passwordOk => _password.text.isNotEmpty;

  Future<void> _login() async {
    if (_loading) return;
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_emailOk || !_passwordOk) return;

    setState(() => _loading = true);
    try {
      final cred = await _service.signIn(
        email: _email.text,
        password: _password.text,
      );
      final uid = cred.user?.uid;
      final done = uid == null ? false : await _service.isProfileComplete(uid);
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => done ? const HomePage() : const ProfileSetupPage(),
        ),
            (route) => false,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      debugPrint('Login failed: $e');
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _email.text.trim());

    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuthColors.field,
        title: const Text('Reset password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email and we will send you a reset link.',
              style: TextStyle(color: AuthColors.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              cursorColor: AuthColors.primary,
              style: const TextStyle(color: AuthColors.ink),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: const TextStyle(color: AuthColors.muted),
                filled: true,
                fillColor: AuthColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AuthColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AuthColors.primary,
                    width: 1.8,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send link'),
          ),
        ],
      ),
    );

    if (send != true || !mounted) return;
    final email = controller.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (!EmailAuthService.validEmail(email)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }

    try {
      await _service.sendPasswordReset(email);
      messenger.showSnackBar(
        const SnackBar(content: Text('Reset link sent. Check your email.')),
      );
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('Reset failed: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Log in with your email and password.',
      children: [
        DarkField(
          label: 'Email',
          controller: _email,
          enabled: !_loading,
          keyboardType: TextInputType.emailAddress,
          action: TextInputAction.next,
          hints: const [AutofillHints.email],
          error: _submitted && !_emailOk ? 'Enter a valid email address.' : null,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 18),
        PasswordField(
          controller: _password,
          enabled: !_loading,
          error: _submitted && !_passwordOk ? 'Enter your password.' : null,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _login(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _loading ? null : _forgotPassword,
            style: TextButton.styleFrom(foregroundColor: AuthColors.primary),
            child: const Text(
              'Forgot password?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (_error != null) ErrorLine(_error!),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Log in', loading: _loading, onPressed: _login),
        const SizedBox(height: 12),
        TextLinkButton(
          'New here? Create account',
          onPressed: _loading
              ? null
              : () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterPage()),
          ),
        ),
      ],
    );
  }
}