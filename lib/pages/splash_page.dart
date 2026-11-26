import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/phone_auth_service.dart';
import '../widgets/brand.dart';
import 'intro_page.dart';
import 'main_navigation_page.dart';
import 'profile_setup_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _authService = AuthService();
  final _phoneService = PhoneAuthService();

  @override
  void initState() {
    super.initState();
    _next();
  }

  Future<void> _next() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    Widget target = const IntroPage();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      target = const MainNavigationPage();
      try {
        await _authService.syncUserProfile();
        final complete = await _phoneService.isProfileComplete(user.uid);
        if (!complete) {
          target = const ProfileSetupPage();
        }
      } catch (e) {
        debugPrint('Splash profile check failed: $e');
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => target,
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Brand.purple,
        body: Center(child: BrandMark()),
      ),
    );
  }
}
