import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:geolocator/geolocator.dart';

import 'SimpleEmailSignupModal.dart';
import '../Home/Homepage.dart'; // Add your correct import path

class SocialSignInModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const SocialSignInModalContent();
      },
    );
  }
}

class SocialSignInModalContent extends StatefulWidget {
  const SocialSignInModalContent({super.key});

  @override
  State<SocialSignInModalContent> createState() =>
      _SocialSignInModalContentState();
}

class _SocialSignInModalContentState extends State<SocialSignInModalContent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  static const Color primaryColor = Color(0xFFFF6786);
  static const Color secondaryColor = Color(0xFFFFF0F3);
  static const Color textColor = Color(0xFF2D3142);

  bool get _shouldShowAppleSignIn {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  void _showMessage(String message, {bool isError = true}) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade700 : Colors.green.shade600,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Mont',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }

  Future<void> _handleSignIn(BuildContext context, String method) async {
    if (method == 'Google') {
      await _signInWithGoogle(context);
    } else if (method == 'Apple') {
      await _signInWithApple(context);
    } else if (method == 'Facebook') {
      _showMessage('Facebook sign-in coming soon!');
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    try {
      if (!mounted) return;

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Apple');
      }

      await _finalizeUserInFirestore(firebaseUser);

      if (!mounted) return;

      // ✅ Navigate to Homepage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => Homepage()),
      );

      _showMessage('Welcome to Stunify!', isError: false);

    } on FirebaseAuthException catch (e) {
      _showMessage('Apple Authentication failed: ${e.message}');
    } catch (e) {
      debugPrint('Apple Sign-In Error: $e');
      if (!e.toString().toLowerCase().contains('canceled')) {
        _showMessage('Sign-in failed. Please try again.');
      }
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      if (!mounted) return;

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // cancelled

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Google');
      }

      await _finalizeUserInFirestore(firebaseUser);

      if (!mounted) return;

      // ✅ Navigate to Homepage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => Homepage()),
      );

      _showMessage('Welcome to Stunify!', isError: false);

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
          'An account already exists with this email using a different sign-in method.';
          break;
        case 'invalid-credential':
          errorMessage = 'The credential is invalid. Please try again.';
          break;
        default:
          errorMessage = 'Authentication failed: ${e.message}';
      }
      _showMessage(errorMessage);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      _showMessage('Sign-in failed. Please try again.');
    }
  }

  Future<Position?> _tryGetLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// ✅ Ensures user doc exists and is marked as NON-STUDENT.
  Future<void> _finalizeUserInFirestore(User firebaseUser) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final userRef = usersRef.doc(firebaseUser.uid);

    final userDoc = await userRef.get();
    final fcmToken = await FirebaseMessaging.instance.getToken();
    final position = await _tryGetLocation();

    if (!userDoc.exists) {
      // ✅ New user (Non-student)
      await userRef.set({
        'email': firebaseUser.email ?? '',
        'displayName': firebaseUser.displayName,
        'photoUrl': firebaseUser.photoURL,
        'emailVerified': firebaseUser.emailVerified,

        // ✅ Role for your UI logic
        'role': 'nonStudent',
        'roleEffective': 'nonStudent', // ✅ Added roleEffective

        // Non-students don't have uni details
        'university': '',
        'graduationYear': null,

        // optional, can be filled by SimpleEmailSignupModal later
        'personalEmail': null,

        'fcmTokens': fcmToken != null ? [fcmToken] : <String>[],
        'latitude': position?.latitude,
        'longitude': position?.longitude,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // ✅ Existing user: update token, verification, and ensure role exists
      final data = userDoc.data() ?? {};
      final existingRole = (data['role'] ?? '').toString();

      final updateData = <String, dynamic>{
        'emailVerified': firebaseUser.emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (fcmToken != null && fcmToken.isNotEmpty) {
        updateData['fcmTokens'] = FieldValue.arrayUnion([fcmToken]);
      }

      if (position != null) {
        updateData['latitude'] = position.latitude;
        updateData['longitude'] = position.longitude;
      }

      // Only set role if missing (don't overwrite a verified student accidentally)
      if (existingRole.isEmpty) {
        updateData['role'] = 'nonStudent';
        updateData['roleEffective'] = 'nonStudent'; // ✅ Added roleEffective
      }

      await userRef.update(updateData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sign in to Stunify',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Mont',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _shouldShowAppleSignIn
                    ? "Choose your preferred sign-in method"
                    : "Sign in with your preferred method",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontFamily: 'Mont',
                ),
              ),
              const SizedBox(height: 32),

              if (_shouldShowAppleSignIn) ...[
                ElevatedButton.icon(
                  onPressed: () => _handleSignIn(context, 'Apple'),
                  icon: const Icon(Icons.apple, color: Colors.white, size: 24),
                  label: const Text(
                    'Continue with Apple',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mont',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontFamily: 'Mont',
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              OutlinedButton.icon(
                onPressed: () => _handleSignIn(context, 'Google'),
                icon: Image.asset('assets/images/google.png', height: 24.0),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Mont',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () => _handleSignIn(context, 'Facebook'),
                icon: const Icon(
                  Icons.facebook,
                  color: Color(0xFF1877F2),
                  size: 24.0,
                ),
                label: const Text(
                  'Continue with Facebook',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Mont',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mont',
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                ],
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  SimpleEmailSignupModal.show(context);
                },
                icon: const Icon(Icons.email_outlined, color: Colors.white, size: 22),
                label: const Text(
                  'Sign Up with Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Mont',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontFamily: 'Mont',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}