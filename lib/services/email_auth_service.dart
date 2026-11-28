import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthException implements Exception {
  AuthException(this.message, {this.field});

  final String message;

  /// Which form field the problem belongs to: 'username', 'email',
  /// 'password', or null for a general error.
  final String? field;

  @override
  String toString() => message;
}

/// Email + password sign-in with a unique username (Firebase).
class EmailAuthService {
  EmailAuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static final _usernameRe = RegExp(r'^[a-zA-Z0-9_.]{3,20}$');
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool validUsername(String v) => _usernameRe.hasMatch(v);
  static bool validEmail(String v) => _emailRe.hasMatch(v);

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('signIn: ${e.code} ${e.message}');
      throw AuthException(_friendly(e), field: _fieldFor(e));
    }
  }

  /// Creates the account, then claims the username. If the username is
  /// taken, the new account is removed again so nothing is left behind.
  Future<UserCredential> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('register: ${e.code} ${e.message}');
      throw AuthException(_friendly(e), field: _fieldFor(e));
    }

    final user = cred.user!;
    final key = username.toLowerCase();

    try {
      await _db.runTransaction((tx) async {
        final nameRef = _db.collection('usernames').doc(key);
        if ((await tx.get(nameRef)).exists) {
          throw AuthException(
            'That username is taken. Try another.',
            field: 'username',
          );
        }
        tx.set(nameRef, {'uid': user.uid});
        tx.set(
          _db.collection('users').doc(user.uid),
          {
            'username': username,
            'email': email.trim(),
            'ageConfirmed': true,
            'acceptedGuidelinesAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } on AuthException {
      await _discard(user);
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('register save: ${e.code} ${e.message}');
      await _discard(user);
      throw AuthException(_friendly(e));
    } catch (e) {
      debugPrint('register save: $e');
      await _discard(user);
      throw AuthException('Could not create your account. Please try again.');
    }

    return cred;
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e), field: 'email');
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

  Future<void> _discard(User user) async {
    try {
      await user.delete();
    } catch (e) {
      debugPrint('discard: $e');
    }
    await _auth.signOut();
  }

  String? _fieldFor(FirebaseException e) {
    switch (e.code) {
      case 'invalid-email':
      case 'email-already-in-use':
      case 'user-not-found':
        return 'email';
      case 'weak-password':
        return 'password';
      default:
        return null;
    }
  }

  String _friendly(FirebaseException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is not right.';
      case 'email-already-in-use':
        return 'This email already has an account. Log in instead.';
      case 'weak-password':
        return 'Use at least 8 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is turned off. Enable Email/Password in Firebase under Authentication.';
      case 'permission-denied':
        return 'Could not save your username. Check your Firestore rules.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}