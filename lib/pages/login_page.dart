import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/phone_auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'main_navigation_page.dart';
import 'otp_page.dart';
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
  bool _obscurePassword = true;
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

  bool get _validPhone => RegExp(r'^\d{10}$').hasMatch(_phone.text);

  Future<void> _sendCode() async {
    if (_loading) return;
    if (!_validPhone) {
      setState(() => _error = 'Enter a 10-digit mobile number.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _notRegistered = false;
    });

    try {
      await _service.sendCode(_phone.text);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(
            phone: _phone.text,
            service: _service,
            mode: AuthMode.login,
          ),
        ),
      );
    } on PhoneAuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      debugPrint('Send code failed: $e');
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationPage()),
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationPage()),
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
        // Toggle between Phone OTP and Email/Password
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Phone OTP')),
                selected: !_useEmailMode,
                showCheckmark: false,
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
                onSelected: (_) => setState(() {
                  _useEmailMode = true;
                  _error = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

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
          TextField(
            controller: _emailController,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email address',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            enabled: !_loading,
            obscureText: _obscurePassword,
            onSubmitted: (_) => _handleEmailLogin(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_error != null) ErrorLine(_error!),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Sign in with Email',
            loading: _loading,
            onPressed: _handleEmailLogin,
          ),
        ],

        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: (_loading || _googleLoading) ? null : _handleGoogleSignIn,
          icon: _googleLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.g_mobiledata_rounded, size: 26),
          label: const Text('Continue with Google'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}
