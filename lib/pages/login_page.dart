import 'package:flutter/material.dart';

import '../services/phone_auth_service.dart';
import '../widgets/auth_widgets.dart';
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

  bool _loading = false;
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
      if (mounted) setState(() {
        _loading = false;
        _error = e.message;
      });
      return;
    } catch (e) {
      debugPrint('Send code failed: $e');
      if (mounted) setState(() {
        _loading = false;
        _error = 'Something went wrong. Try again.';
      });
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

    // The code page found out this number has no account.
    if (result == 'not_registered') _showNotRegistered();
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
      ],
    );
  }
}