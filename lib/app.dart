import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finansa_new/core/constants/app_colors.dart';
import 'package:finansa_new/features/auth/presentation/login_screen.dart';
import 'package:finansa_new/features/onboarding/presentation/onboarding_screen.dart';
import 'package:finansa_new/navigation/app_router.dart';

class FinansaApp extends StatelessWidget {
  const FinansaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FINANSA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPurple,
          primary: AppColors.primaryPurple,
          secondary: AppColors.secondaryPurple,
          surface: AppColors.surfaceLavender,
        ),
      ),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();

  Future<Widget> _getStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    // Belum onboarding → tampilkan onboarding
    if (!onboardingDone) return const OnboardingScreen();

    // Sudah onboarding, cek login
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return const AppRouter();

    // Belum login → tampilkan login
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💰', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text(
                    'FINANSA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: AppColors.primaryPurple),
                ],
              ),
            ),
          );
        }
        return snapshot.data ?? const LoginScreen();
      },
    );
  }
}
