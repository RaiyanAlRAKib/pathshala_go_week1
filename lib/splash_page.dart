import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_service.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _decideNextScreen();
    });
  }

  Future<void> _decideNextScreen() async {
    final auth = AuthService();
    Widget next = const LoginPage();
    if (auth.isLoggedIn) {
      try {
        next = await auth.homeForCurrentUser();
      } catch (_) {
        next = const LoginPage();
      }
    }
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}