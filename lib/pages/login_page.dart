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
  final _service = PhoneAuthService();
  final _authService = AuthService();

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
    super.dispose();
  }

  bool get _valid => RegExp(r'^\d{10}$').hasMatch(_phone.text);

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
      if (!exists) {
        if (mounted) {
          setState(() {
            _notRegistered = true;
            _error =
                "We don't have an account for this number. Check it, or create an account.";
          });
        }
        return;
      }

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
      subtitle: 'Enter your mobile number. We will text you a 6-digit code.',
      children: [
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
