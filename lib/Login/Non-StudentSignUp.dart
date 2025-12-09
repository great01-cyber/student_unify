import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// ⭐️ NEW IMPORT ADDED ⭐️
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// NOTE: The 'package:firebase_core/firebase_core.dart' import
// and `await Firebase.initializeApp()` in main() are REQUIRED for this code to run.
// They are assumed to be outside of this snippet or in your actual main.dart file.

// import '../Home/Homepage.dart'; // Assuming Homepage is defined locally

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: handleAuthState(),
    );
  }
}

// Determine if the user is authenticated
Widget handleAuthState() {
  return StreamBuilder(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (BuildContext context, snapshot) {
      if (snapshot.hasData) {
        return const HomePage(); // Ensure HomePage is const if possible
      } else {
        return const LoginPage();
      }
    },
  );
}

// Login Page (placeholder)
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (BuildContext context) {
                return const StunifySignUpModalContent();
              },
            );
          },
          child: const Text('Sign In'),
        ),
      ),
    );
  }
}

// Home Page after successful login
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showSignUpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const StunifySignUpModalContent();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome! You are logged in.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showSignUpModal(context),
              child: const Text('Show Sign Up Modal'),
            ),
          ],
        ),
      ),
    );
  }
}

// The Content for the Modal Sheet with working Google Sign-In and new Apple Sign-In
class StunifySignUpModalContent extends StatefulWidget {
  const StunifySignUpModalContent({super.key});

  @override
  State<StunifySignUpModalContent> createState() =>
      _StunifySignUpModalContentState();
}

class _StunifySignUpModalContentState
    extends State<StunifySignUpModalContent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // Handle sign-in for different providers
  Future<void> _handleSignIn(BuildContext context, String method) async {
    if (method == 'Google') {
      await _signInWithGoogle(context);
    } else if (method == 'Apple') {
      // ⭐️ CALL THE NEW METHOD ⭐️
      await _signInWithApple(context);
    } else if (method == 'Facebook') {
      debugPrint('Facebook sign-in not implemented yet');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Facebook sign-in coming soon!')),
        );
      }
    }
  }

  // ⭐️ APPLE SIGN-IN IMPLEMENTATION ⭐️
  Future<void> _signInWithApple(BuildContext context) async {
    try {
      if (!mounted) return;
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 1. Get the Apple ID Credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // 2. Create the Firebase Auth Credential
      final credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // 3. Sign in to Firebase with the Apple credential
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Apple');
      }

      // --- Firestore/FCM Finalization Logic ---

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (!userDoc.exists) {
        // New user - create Firestore document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          'uid': firebaseUser.uid,
          // Use Apple's provided email/name for initial population if available
          'email': firebaseUser.email ?? appleCredential.email ?? '',
          'displayName': firebaseUser.displayName ?? appleCredential.givenName ?? '',
          'photoUrl': firebaseUser.photoURL ?? '',
          'emailVerified': firebaseUser.emailVerified,
          'createdAt': FieldValue.serverTimestamp(),
          'university': '',
          'city': '',
          'fcmToken': fcmToken ?? '',
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } else {
        // Existing user - update FCM token and online status
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .update({
          'fcmToken': fcmToken ?? '',
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      // --- Navigation and Cleanup ---
      if (mounted) Navigator.pop(context); // Close loading dialog
      if (mounted) Navigator.pop(context); // Close modal

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);

      String errorMessage = 'Apple Authentication failed: ${e.message}';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      debugPrint('Apple Sign-In Error: $e');

      if (mounted && e.toString().contains('canceled')) {
        return; // User canceled
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    }
  }


  // Google Sign-In implementation (Original, slightly cleaned up)
  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      if (!mounted) return;
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancels the sign-in
      if (googleUser == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Create a new credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Check if user exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      // Get FCM token for push notifications
      final fcmToken = await FirebaseMessaging.instance.getToken();

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
          'city': '',
          'fcmToken': fcmToken ?? '',
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } else {
        // Existing user - update FCM token and online status
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .update({
          'fcmToken': fcmToken ?? '',
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Close modal
      if (mounted) Navigator.pop(context);

      // Navigate to home and remove all previous routes
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
        );
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);

      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
          'An account already exists with this email using a different sign-in method.';
          break;
        case 'invalid-credential':
          errorMessage = 'The credential is invalid. Please try again.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google sign-in is not enabled for this app.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this credential.';
          break;
        default:
          errorMessage = 'Authentication failed: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      debugPrint('Google Sign-In Error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 10.0,
        left: 32.0,
        right: 32.0,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // --- 1. Close Button (X) ---
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black54),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          const SizedBox(height: 10),

          // --- 2. Header Text and Subtitle ---
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Sign up for Stunify',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mont',
                ),
              ),
              SizedBox(height: 8),
              Text(
                "It's quickest to sign in with Apple ID",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Mont',
                ),
              ),
            ],
          ),

          const SizedBox(height: 50),

          // --- 3. Apple ID Button (Black Filled) ---
          ElevatedButton.icon(
            onPressed: () => _handleSignIn(context, 'Apple'),
            icon: const Icon(Icons.apple, color: Colors.white),
            label: const Text(
              'Continue with Apple',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Mont',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- 4. Faint Underline (Divider) ---
          const Divider(
            color: Colors.grey,
            thickness: 0.5,
          ),

          const SizedBox(height: 20),

          // --- 5. Google Button ---
          OutlinedButton.icon(
            onPressed: () => _handleSignIn(context, 'Google'),
            icon: Image.asset(
              'assets/images/google.png',
              height: 24.0,
            ),
            label: const Text(
              'Continue with Google',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Mont',
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: Colors.black),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // --- 6. Facebook Button ---
          OutlinedButton.icon(
            onPressed: () => _handleSignIn(context, 'Facebook'),
            icon: const Icon(
              Icons.facebook,
              color: Colors.blue,
              size: 24.0,
            ),
            label: const Text(
              'Continue with Facebook',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Mont',
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: Colors.black),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}