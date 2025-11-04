import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../AuthPage.dart';
import '../Home/Homepage.dart';
import '../onboardingScreen.dart'; // Assuming this path

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // This future function checks the necessary prerequisites (like SharedPreferences)
  Future<bool> _hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // The OnboardingScreen should set 'seenOnboarding' to true when completed.
      return prefs.getBool('seenOnboarding') ?? false;
    } catch (e) {
      // Handle potential SharedPreferences errors gracefully
      print("Error loading SharedPreferences: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Initial Check: Has the user completed Onboarding?
    return FutureBuilder<bool>(
      future: _hasSeenOnboarding(),
      builder: (context, snapshot) {
        // Show a loading indicator while checking the shared preferences flag
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5))),
          );
        }

        final bool seenOnboarding = snapshot.data ?? false;

        if (!seenOnboarding) {
          // If onboarding is not seen, show the OnboardingScreen first.
          // The OnboardingScreen will handle setting the flag and then routing to AuthWrapper.
          return const OnboardingScreen();
        }

        // 2. Second Check: If onboarding is seen, check Authentication Status.
        // This is the standard AuthWrapper behavior.
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            // Show a loading indicator while Firebase is checking the user's session
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5))),
              );
            }

            // User is logged in
            if (authSnapshot.hasData && authSnapshot.data != null) {
              // Ensure email is verified before going to the main app (optional security step)
              if (authSnapshot.data!.emailVerified) {
                return const Homepage();
              } else {
                // If not verified, route to a verification check screen or back to AuthPage with a message.
                // For simplicity, we route to the AuthPage.
                return const AuthPage();
              }
            }

            // User is logged out
            return const AuthPage();
          },
        );
      },
    );
  }
}