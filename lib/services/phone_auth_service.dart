import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthException implements Exception {
  PhoneAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Phone + 6-digit-code sign-in (Firebase). Create one instance per flow and
/// pass the same instance from the login/register page to OtpPage, because it
/// remembers the verification id.
class PhoneAuthService {
  PhoneAuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  static const countryCode = '+977';

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String? _verificationId;
  int? _resendToken;
  String? _lastPhone;

  /// Does an account exist for this 10-digit number?
  ///
  /// Firebase phone auth can't tell login from sign-up, so this looks the
  /// number up in `users` (see saveProfile). IMPORTANT: this runs before the
  /// person is signed in, so your Firestore rules (or a Cloud Function you
  /// call instead) must allow it. Replace this body if you check differently.
  Future<bool> isRegistered(String localNumber) async {
    try {
      final snap = await _db
          .collection('users')
          .where('phoneNumber', isEqualTo: '$countryCode$localNumber')
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw PhoneAuthException(_friendly(e));
    }
  }

  /// Sends the 6-digit SMS code. Completes once the SMS has been sent.
  Future<void> sendCode(String localNumber, {bool resend = false}) {
    final completer = Completer<void>();
    _lastPhone = '$countryCode$localNumber';

    _auth.verifyPhoneNumber(
      phoneNumber: _lastPhone!,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resend ? _resendToken : null,
      // Android can auto-read the SMS; we always let the person confirm the
      // code themselves so both platforms behave the same.
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
      return await _auth.signInWithCredential(
        PhoneAuthProvider.credential(verificationId: id, smsCode: code),
      );
    } on FirebaseAuthException catch (e) {
      throw PhoneAuthException(_friendly(e));
    }
  }

  /// Called after a successful *register* verification.
  Future<void> saveProfile(UserCredential cred) async {
    final user = cred.user;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({
      'phoneNumber': user.phoneNumber ?? _lastPhone,
      'ageConfirmed': true,
      'acceptedGuidelinesAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      case 'permission-denied':
        return 'Could not check this number. Please try again later.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}