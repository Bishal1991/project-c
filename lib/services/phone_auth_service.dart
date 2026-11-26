import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PhoneAuthException implements Exception {
  PhoneAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Phone number + 6-digit code sign-in (Firebase). Use one instance per flow
/// and pass it from the login/register page to OtpPage, because it remembers
/// the verification id.
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

  /// true = has an account, false = no account, null = couldn't check
  /// (for example Firestore rules not published yet). When null, the app
  /// carries on and checks again right after the code is verified.
  Future<bool?> isRegistered(String localNumber) async {
    try {
      final doc = await _db
          .collection('phoneIndex')
          .doc('$countryCode$localNumber')
          .get();
      return doc.exists;
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
      // Android may read the SMS by itself; we always let the person
      // confirm the code so both platforms behave the same.
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
        completer.completeError(PhoneAuthException(
          e is FirebaseException
              ? _friendly(e)
              : 'Could not send the code. Try again.',
        ));
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
    final isNew = cred.additionalUserInfo?.isNewUser ?? false;

    await _db.collection('users').doc(user.uid).set({
      'phoneNumber': phone,
      'ageConfirmed': true,
      'acceptedGuidelinesAt': FieldValue.serverTimestamp(),
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await indexPhone(cred);
  }

  /// Lets the login page tell whether a number has an account.
  Future<void> indexPhone(UserCredential cred) async {
    final user = cred.user;
    final phone = user?.phoneNumber ?? _lastPhone;
    if (user == null || phone == null) return;
    try {
      await _db.collection('phoneIndex').doc(phone).set({'uid': user.uid});
    } catch (e) {
      // Already indexed (rules only allow creating it once), or rules not set.
      debugPrint('indexPhone skipped: $e');
    }
  }

  Future<bool> isProfileComplete(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['profileComplete'] == true;
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