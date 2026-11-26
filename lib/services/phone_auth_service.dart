import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../supabase_config.dart';

class PhoneAuthException implements Exception {
  PhoneAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Phone number + 6-digit code sign-in (Firebase Auth) backed by Supabase PostgreSQL (`public.users`).
class PhoneAuthService {
  PhoneAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  static const countryCode = '+977';

  final FirebaseAuth _auth;

  String? _verificationId;
  int? _resendToken;
  String? _lastPhone;

  /// true = has an account in Supabase `public.users`, false = no account, null = couldn't check.
  Future<bool?> isRegistered(String localNumber) async {
    try {
      final res = await SupabaseConfig.client.rpc(
        'is_phone_registered',
        params: {'p_phone': '$countryCode$localNumber'},
      );
      if (res is bool) return res;
      return null;
    } catch (e) {
      debugPrint('isRegistered could not check: $e');
      return null;
    }
  }

  /// Sends the 6-digit SMS code. Completes once the SMS has been sent.
  Future<void> sendCode(String localNumber, {bool resend = false}) {
    final completer = Completer<void>();
    _lastPhone = '$countryCode$localNumber';

    _auth
        .verifyPhoneNumber(
          phoneNumber: _lastPhone!,
          timeout: const Duration(seconds: 60),
          forceResendingToken: resend ? _resendToken : null,
          verificationCompleted: (_) {},
          verificationFailed: (e) {
            debugPrint('verificationFailed: ${e.code} ${e.message}');
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
        )
        .catchError((Object e) {
          debugPrint('verifyPhoneNumber error: $e');
          if (!completer.isCompleted) {
            completer.completeError(
              PhoneAuthException(
                e is FirebaseException
                    ? _friendly(e)
                    : 'Could not send the code. Try again.',
              ),
            );
          }
        });

    return completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw PhoneAuthException(
        'Could not send the code. Check your connection and try again.',
      ),
    );
  }

  Future<UserCredential> verifyCode(String code) async {
    final id = _verificationId;
    if (id == null) {
      throw PhoneAuthException('This code has expired. Request a new one.');
    }
    try {
      return await _auth.signInWithCredential(
        PhoneAuthProvider.credential(verificationId: id, smsCode: code),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('verifyCode: ${e.code} ${e.message}');
      throw PhoneAuthException(_friendly(e));
    }
  }

  /// Login with a number that has no account: Firebase just created one,
  /// so remove it again and sign out.
  Future<void> discardNewUser(UserCredential cred) async {
    try {
      await cred.user?.delete();
    } catch (e) {
      debugPrint('discardNewUser: $e');
    }
    await _auth.signOut();
  }

  /// Called after a successful register verification.
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

  /// Ensures the phone number is synced on the user's Supabase profile row.
  Future<void> indexPhone(UserCredential cred) async {
    await saveProfile(cred);
  }

  /// Checks whether the user has completed their profile onboarding in Supabase `public.users`.
  Future<bool> isProfileComplete(String uid) async {
    try {
      final res = await SupabaseConfig.client.rpc(
        'get_user_profile',
        params: {'p_uid': uid},
      );
      if (res is Map) {
        final onboarded = res['is_onboarded'] == true;
        final hasRegion =
            (res['region'] as String?)?.trim().isNotEmpty == true ||
            (res['city'] as String?)?.trim().isNotEmpty == true;
        return onboarded && hasRegion;
      }
      return false;
    } catch (e) {
      debugPrint('isProfileComplete: $e');
      return true;
    }
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
      case 'quota-exceeded':
        return 'SMS limit reached. Use a test number or try again later.';
      case 'operation-not-allowed':
        return 'Phone sign-in is turned off. Enable it in Firebase under Authentication.';
      case 'app-not-authorized':
      case 'missing-client-identifier':
        return 'This app is not set up for phone sign-in yet. Add your SHA keys in Firebase.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
