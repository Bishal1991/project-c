import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '910361176882-7mqvjmdtlthdug9kf5hjb3i6ko0gumg1.apps.googleusercontent.com',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Upsert user profile into Firestore so other users can search by email or phone
  Future<void> syncUserProfile({String? displayName, String? phoneNumber}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnap = await docRef.get();

    String resolvedName = displayName ?? '';
    if (resolvedName.isEmpty) {
      if (docSnap.exists && docSnap.data()?['displayName'] != null) {
        resolvedName = docSnap.data()!['displayName'] as String;
      } else if (user.displayName != null && user.displayName!.isNotEmpty) {
        resolvedName = user.displayName!;
      } else if (user.email != null && user.email!.isNotEmpty) {
        resolvedName = user.email!.split('@')[0];
      } else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        resolvedName = user.phoneNumber!;
      } else {
        resolvedName = 'User';
      }
    }

    final userModel = UserModel(
      uid: user.uid,
      displayName: resolvedName,
      email: user.email,
      phoneNumber: phoneNumber ?? user.phoneNumber,
      photoUrl: user.photoURL,
    );

    await docRef.set(userModel.toMap(), SetOptions(merge: true));
  }

  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name);
    await _firestore.collection('users').doc(user.uid).update({
      'displayName': name,
    });
  }

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      await syncUserProfile(displayName: userCred.user?.displayName);
      return userCred;
    } on FirebaseAuthException catch (e) {
      throw _getHumanReadableError(e);
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      throw 'Google Sign-In failed: $e';
    }
  }

  // Email & Password Sign-In
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await syncUserProfile();
      return userCred;
    } on FirebaseAuthException catch (e) {
      throw _getHumanReadableError(e);
    }
  }

  // Email & Password Sign-Up
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await syncUserProfile();
      return userCred;
    } on FirebaseAuthException catch (e) {
      throw _getHumanReadableError(e);
    }
  }

  // Phone Number Authentication
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final userCred = await _auth.signInWithCredential(credential);
      await syncUserProfile(phoneNumber: userCred.user?.phoneNumber);
      return userCred;
    } on FirebaseAuthException catch (e) {
      throw _getHumanReadableError(e);
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _getHumanReadableError(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  String _getHumanReadableError(FirebaseAuthException e) {
    debugPrint('FirebaseAuthException: [${e.code}] ${e.message}');
    switch (e.code) {
      case 'internal-error':
        if (e.message?.contains('CONFIGURATION_NOT_FOUND') ?? false) {
          return 'Authentication is not activated in Firebase Console. Go to Console > Authentication and click "Get started".';
        }
        return 'Internal Firebase error. Please check if Authentication is enabled in Firebase Console.';
      case 'operation-not-allowed':
        return 'This sign-in provider is disabled in Firebase Console. Please enable it in Authentication > Sign-in method.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'invalid-phone-number':
        return 'The provided phone number is not valid. Please enter a valid number like +977 98XXXXXXXX.';
      case 'invalid-verification-code':
        return 'Incorrect SMS code entered. Please check and try again.';
      case 'invalid-verification-id':
        return 'Verification session expired. Please request a new OTP.';
      case 'session-expired':
        return 'The SMS code has expired. Please request a new code.';
      case 'quota-exceeded':
        return 'SMS quota exceeded for today. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'An unexpected authentication error occurred.';
    }
  }
}
