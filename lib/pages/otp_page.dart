import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/phone_auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'home_page.dart';

enum AuthMode { login, register }

class OtpPage extends StatefulWidget {
  const OtpPage({
    super.key,
    required this.phone,
    required this.service,
    required this.mode,
  });

  final String phone;
  final PhoneAuthService service;
  final AuthMode mode;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  static const _length = 6;

  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _seconds = 30;
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _verify() async {
    if (_code.text.length != _length || _verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final cred = await widget.service.verifyCode(_code.text);
      if (widget.mode == AuthMode.register) {
        await widget.service.saveProfile(cred);
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
      );
    } on PhoneAuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _code.clear();
        });
      }
    } catch (e) {
      debugPrint('Verify failed: $e');
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Try again.';
          _code.clear();
        });
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await widget.service.sendCode(widget.phone, resend: true);
      if (!mounted) return;
      setState(() => _seconds = 30);
      _startTimer();
    } on PhoneAuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      debugPrint('Resend failed: $e');
      if (mounted) setState(() => _error = 'Could not resend. Try again.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Widget _boxes() {
    final text = _code.text;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focus.requestFocus(),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_length, (i) {
              final active = i == text.length && _focus.hasFocus;
              final color = _error != null
                  ? AuthColors.error
                  : active
                  ? AuthColors.primary
                  : AuthColors.border;
              return Container(
                width: 46,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color,
                    width: active || _error != null ? 1.8 : 1,
                  ),
                ),
                child: Text(
                  i < text.length ? text[i] : '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AuthColors.ink,
                  ),
                ),
              );
            }),
          ),
          // Invisible field that actually receives the typing / SMS autofill.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _code,
                focusNode: _focus,
                autofocus: true,
                enabled: !_verifying,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                enableInteractiveSelection: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_length),
                ],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
                onChanged: (v) {
                  setState(() => _error = null);
                  if (v.length == _length) _verify();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Enter the code',
      subtitle: 'We sent a 6-digit code to +977 ${widget.phone}.',
      children: [
        _boxes(),
        if (_error != null) ErrorLine(_error!),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Verify',
          loading: _verifying,
          looksDisabled: _code.text.length != _length,
          onPressed: _verify,
        ),
        const SizedBox(height: 12),
        Center(
          child: _seconds > 0
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Resend code in 0:${_seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 14,
                color: AuthColors.muted,
              ),
            ),
          )
              : TextButton(
            onPressed: _resending ? null : _resend,
            style: TextButton.styleFrom(
              foregroundColor: AuthColors.primary,
            ),
            child: Text(
              _resending ? 'Sending...' : 'Resend code',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        TextLinkButton(
          'Use a different number',
          onPressed: () => Navigator.maybePop(context),
        ),
      ],
    );
  }
}