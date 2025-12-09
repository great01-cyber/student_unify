import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:student_unify_app/services/notification.dart';
import 'package:flutter/cupertino.dart';

import 'firebase_options.dart';
import 'onboardingScreen.dart';
import 'welcome.dart';
import 'services/Authwrapper.dart';


// ---------------------------------------------------
// 1. BACKGROUND FCM HANDLER (REQUIRED)
// ---------------------------------------------------
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------
  // 2. Initialize Firebase
  // ---------------------------------------------------
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ---------------------------------------------------
  // 3. Activate Firebase App Check
  // ---------------------------------------------------
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  // ---------------------------------------------------
  // 4. Register background message handler
  // ---------------------------------------------------
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ---------------------------------------------------
  // 5. Request Notification Permission
  // ---------------------------------------------------
  requestPermissionAndListenForToken();

  // ---------------------------------------------------
  // 6. Initialize Local Notifications
  // ---------------------------------------------------
  await initInfo();

  // ---------------------------------------------------
  // 7. Save this device's FCM token in Firestore
  // ---------------------------------------------------
  await saveUserFCMToken();

  // ---------------------------------------------------
  // 8. Check onboarding screen
  // ---------------------------------------------------
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  // ---------------------------------------------------
  // 9. Run App
  // ---------------------------------------------------
  runApp(MyApp(seenOnboarding: seenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;
  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: seenOnboarding ? const AuthWrapper() : WelcomePage(),
    );
  }
}
