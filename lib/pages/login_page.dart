import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/phone_auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'main_navigation_page.dart';
import 'otp_page.dart';
import 'profile_setup_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _phone;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _service = PhoneAuthService();
  final _authService = AuthService();

  bool _useEmailMode = false;
  bool _loading = false;
  bool _googleLoading = false;
  bool _notRegistered = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _phone.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _valid => RegExp(r'^\d{10}$').hasMatch(_phone.text);

  void _showNotRegistered() {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _notRegistered = true;
      _error =
          "We don't have an account for this number. Check it, or create an account.";
    });
  }

  Future<void> _sendCode() async {
    if (_loading) return;
    if (!_valid) {
      setState(() => _error = 'Enter a 10-digit mobile number.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _notRegistered = false;
    });

    try {
      final exists = await _service.isRegistered(_phone.text);
      if (exists == false) {
        _showNotRegistered();
        return;
      }
      await _service.sendCode(_phone.text);
    } on PhoneAuthException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
      return;
    } catch (e) {
      debugPrint('Send code failed: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Something went wrong. Try again.';
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() => _loading = false);

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => OtpPage(
          phone: _phone.text,
          service: _service,
          mode: AuthMode.login,
        ),
      ),
    );

    if (result == 'not_registered') _showNotRegistered();
  }

  Future<void> _handleEmailLogin() async {
    if (_loading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter both your email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cred = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      final done =
          uid == null ? true : await _service.isProfileComplete(uid);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              done ? const MainNavigationPage() : const ProfileSetupPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final cred = await _authService.signInWithGoogle();
      if (cred != null && mounted) {
        final uid = cred.user?.uid;
        final done =
            uid == null ? true : await _service.isProfileComplete(uid);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                done ? const MainNavigationPage() : const ProfileSetupPage(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      if (mounted) {
        setState(() => _error = 'Google Sign-In failed. Try again.');
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterPage(initialPhone: _phone.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: _useEmailMode
          ? 'Sign in with your Firebase email and password.'
          : 'Enter your mobile number. We will text you a 6-digit code.',
      children: [
        // Toggle between Phone OTP and Email/Password in dark theme
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Phone OTP')),
                selected: !_useEmailMode,
                showCheckmark: false,
                selectedColor: AuthColors.primary,
                backgroundColor: AuthColors.field,
                labelStyle: TextStyle(
                  color: !_useEmailMode ? Colors.white : AuthColors.muted,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() {
                  _useEmailMode = false;
                  _error = null;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Email & Password')),
                selected: _useEmailMode,
                showCheckmark: false,
                selectedColor: AuthColors.primary,
                backgroundColor: AuthColors.field,
                labelStyle: TextStyle(
                  color: _useEmailMode ? Colors.white : AuthColors.muted,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() {
                  _useEmailMode = true;
                  _error = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (!_useEmailMode) ...[
          PhoneField(
            controller: _phone,
            hasError: _error != null,
            enabled: !_loading,
            onChanged: (_) {
              if (_error != null || _notRegistered) {
                setState(() {
                  _error = null;
                  _notRegistered = false;
                });
              }
            },
            onSubmitted: (_) => _sendCode(),
          ),
          if (_error != null) ErrorLine(_error!),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Send code',
            loading: _loading,
            onPressed: _sendCode,
          ),
          const SizedBox(height: 12),
          if (_notRegistered)
            SecondaryButton(label: 'Create account', onPressed: _goToRegister)
          else
            TextLinkButton(
              'New here? Create account',
              onPressed: _loading ? null : _goToRegister,
            ),
        ] else ...[
          DarkField(
            label: 'Email address',
            controller: _emailController,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 16),
          DarkField(
            label: 'Password',
            controller: _passwordController,
            enabled: !_loading,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          if (_error != null) ErrorLine(_error!),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Sign in with Email',
            loading: _loading,
            onPressed: _handleEmailLogin,
          ),
        ],

        const SizedBox(height: 18),
        Row(
          children: const [
            Expanded(child: Divider(color: AuthColors.border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or',
                style: TextStyle(color: AuthColors.muted, fontSize: 13),
              ),
            ),
            Expanded(child: Divider(color: AuthColors.border)),
          ],
        ),
        const SizedBox(height: 18),
        SecondaryButton(
          label: _googleLoading ? 'Signing in...' : 'Continue with Google',
          onPressed: (_loading || _googleLoading)
              ? null
              : () => _handleGoogleSignIn(),
        ),
      ],
    );
  }
}
