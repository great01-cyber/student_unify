import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Home/Homepage.dart';
import '../onboardingScreen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Only check authentication status - onboarding is already handled by main.dart
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Show loading indicator while checking auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
            ),
          );
        }

        // User is logged in
        if (authSnapshot.hasData && authSnapshot.data != null) {
          return Homepage(); // Go to Homepage when logged in
        }

        // User is NOT logged in - show OnboardingScreen (Student/Non-Student page)
        return const OnboardingScreen();
      },
    );
  }
}
