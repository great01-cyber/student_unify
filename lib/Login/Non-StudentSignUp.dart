import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:geolocator/geolocator.dart';

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

  // Check if Apple Sign-In should be shown (iOS or macOS only)
  bool get _shouldShowAppleSignIn {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  void _showMessage(String message, {bool isError = true}) {
    final overlay = Overlay.of(context);
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

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Apple');
      }

      await _finalizeUserInFirestore(firebaseUser);

      if (mounted) {
        Navigator.pop(context); // Close modal
        _showMessage('Welcome to Stunify!', isError: false);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Apple Authentication failed: ${e.message}';
      _showMessage(errorMessage);
    } catch (e) {
      debugPrint('Apple Sign-In Error: $e');
      if (!e.toString().contains('canceled')) {
        _showMessage('Sign-in failed. Please try again.');
      }
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      if (!mounted) return;

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Google');
      }

      await _finalizeUserInFirestore(firebaseUser);

      if (mounted) {
        Navigator.pop(context); // Close modal
        _showMessage('Welcome to Stunify!', isError: false);
      }
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

  Future<void> _finalizeUserInFirestore(User firebaseUser) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    final fcmToken = await FirebaseMessaging.instance.getToken();

    // Get location if available
    Position? position;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }

    if (!userDoc.exists) {
      // New user - create Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set({
        'uid': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'displayName': firebaseUser.displayName ?? '',
        'photoUrl': firebaseUser.photoURL ?? '',
        'emailVerified': firebaseUser.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'university': '',
        'graduationYear': null,
        'fcmTokens': fcmToken != null ? [fcmToken] : [],
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } else {
      // Existing user - update FCM token and online status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .update({
        'fcmTokens': FieldValue.arrayUnion([fcmToken ?? '']),
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
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
              // Close Button
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

              // Apple Sign-In Button (only on iOS/macOS)
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

              // Google Button
              OutlinedButton.icon(
                onPressed: () => _handleSignIn(context, 'Google'),
                icon: Image.asset(
                  'assets/images/google.png',
                  height: 24.0,
                ),
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

              // Facebook Button
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

              const SizedBox(height: 20),

              // Terms and Privacy
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