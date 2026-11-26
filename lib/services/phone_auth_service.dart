import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../supabase_config.dart';

class PhoneAuthException implements Exception {
  PhoneAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Phone + 6-digit-code sign-in (Firebase Auth) with profile lookup & storage in Supabase PostgreSQL.
class PhoneAuthService {
  PhoneAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  static const countryCode = '+977';

  final FirebaseAuth _auth;

  String? _verificationId;
  int? _resendToken;
  String? _lastPhone;

  /// Checks if an account exists for this 10-digit number in Supabase `public.users`.
  Future<bool> isRegistered(String localNumber) async {
    try {
      final res = await SupabaseConfig.client.rpc(
        'is_phone_registered',
        params: {'p_phone': '$countryCode$localNumber'},
      );
      return res == true;
    } catch (e) {
      throw PhoneAuthException('Could not check this number. Please try again.');
    }
  }

  /// Sends the 6-digit SMS code via Firebase Auth.
  Future<void> sendCode(String localNumber, {bool resend = false}) {
    final completer = Completer<void>();
    _lastPhone = '$countryCode$localNumber';

    _auth.verifyPhoneNumber(
      phoneNumber: _lastPhone!,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resend ? _resendToken : null,
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(PhoneAuthException(_friendly(e)));
        }
      },
      codeSent: (id, token) {
        _verificationId = id;
        _resendToken = token;
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (id) => _verificationId = id,
    );

    return completer.future;
  }

  Future<UserCredential> verifyCode(String code) async {
    final id = _verificationId;
    if (id == null) {
      throw PhoneAuthException('This code has expired. Request a new one.');
    }
    try {
      final cred = await _auth.signInWithCredential(
        PhoneAuthProvider.credential(verificationId: id, smsCode: code),
      );
      await saveProfile(cred);
      return cred;
    } on FirebaseAuthException catch (e) {
      throw PhoneAuthException(_friendly(e));
    }
  }

  /// Syncs the authenticated phone user to Supabase `public.users`.
  Future<void> saveProfile(UserCredential cred) async {
    final user = cred.user;
    if (user == null) return;
    final phone = user.phoneNumber ?? _lastPhone;
    await SupabaseConfig.client.rpc(
      'upsert_user_profile',
      params: {
        'p_uid': user.uid,
        'p_display_name': user.displayName ?? phone ?? 'User',
        'p_phone_number': phone,
      },
    );
    SupabaseConfig.notifyRefresh();
  }

  String _friendly(FirebaseException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Enter a 10-digit mobile number.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      case 'invalid-verification-code':
        return 'That code is not right. Check it and try again.';
      case 'session-expired':
      case 'code-expired':
        return 'This code has expired. Request a new one.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
