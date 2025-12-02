import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_unify_app/services/Authwrapper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:student_unify_app/welcome.dart';

import 'firebase_options.dart';
import 'onboardingScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Activate Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity, // Android
     //iosProvider: IOSProvider.deviceCheck, // optional for iOS
  );

  // Get initial push message (optional)
  await FirebaseMessaging.instance.getInitialMessage();

  // Shared preferences to check onboarding
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  // Run the app
  runApp(MyApp(seenOnboarding: seenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;
  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // If user hasn't seen onboarding -> show OnboardingScreen, otherwise AuthWrapper
      home: seenOnboarding ? const AuthWrapper() : WelcomePage(),
    );
  }
}
