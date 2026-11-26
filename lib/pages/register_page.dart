import 'package:flutter/material.dart';

import '../services/phone_auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'login_page.dart';
import 'otp_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final TextEditingController _phone;
  final _phoneFocus = FocusNode();
  final _service = PhoneAuthService();

  bool _age = false;
  bool _terms = false;
  bool _loading = false;
  bool _phoneTouched = false;
  bool _submitted = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.initialPhone);
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus && _phone.text.isNotEmpty) {
        setState(() => _phoneTouched = true);
      }
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  bool get _phoneValid => RegExp(r'^\d{10}$').hasMatch(_phone.text);
  bool get _formValid => _phoneValid && _age && _terms;

  String? get _phoneError {
    if (_serverError != null) return _serverError;
    if ((_submitted || _phoneTouched) && !_phoneValid) {
      return 'Enter a 10-digit mobile number.';
    }
    return null;
  }

  Future<void> _createAccount() async {
    if (_loading) return;
    if (!_formValid) {
      // Reveal everything that is still missing.
      setState(() => _submitted = true);
      return;
    }

    setState(() {
      _loading = true;
      _serverError = null;
    });

    try {
      if (await _service.isRegistered(_phone.text)) {
        if (mounted) {
          setState(() => _serverError =
          'This number already has an account. Log in instead.');
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
            mode: AuthMode.register,
          ),
        ),
      );
    } on PhoneAuthException catch (e) {
      if (mounted) setState(() => _serverError = e.message);
    } catch (e) {
      debugPrint('Register failed: $e');
      if (mounted) {
        setState(() => _serverError = 'Something went wrong. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneError = _phoneError;

    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Verify your number so the people you match with can reach you.',
      children: [
        PhoneField(
          controller: _phone,
          focusNode: _phoneFocus,
          hasError: phoneError != null,
          enabled: !_loading,
          onChanged: (_) => setState(() => _serverError = null),
        ),
        if (phoneError != null) ErrorLine(phoneError),
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
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Create account',
          loading: _loading,
          looksDisabled: !_formValid,
          onPressed: _createAccount,
        ),
        const SizedBox(height: 12),
        TextLinkButton(
          'Already have an account? Log in',
          onPressed: _loading
              ? null
              : () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LoginPage(initialPhone: _phone.text),
            ),
          ),
        ),
      ],
    );
  }
}