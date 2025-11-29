import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:student_unify_app/services/AppUser.dart'; // Keep if AppUser is used elsewhere
import 'package:string_similarity/string_similarity.dart'; // Not needed for Login
import 'package:firebase_messaging/firebase_messaging.dart';

import '../Home/Homepage.dart';


class Studentloginpage extends StatefulWidget {
  const Studentloginpage({super.key});

  @override
  State<Studentloginpage> createState() => _AuthPageState();
}

class _AuthPageState extends State<Studentloginpage> with SingleTickerProviderStateMixin {
  // SET TO TRUE PERMANENTLY - REMOVE TOGGLE FUNCTIONALITY
  bool _isLogin = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers (Removed all sign-up specific ones)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Animation controllers can be simplified or removed since no toggle is needed
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Keep animation for initial load fade-in
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    // Only dispose controllers that are used
    super.dispose();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  // --- REVISED LOGIN LOGIC ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    try {
      // Direct LOGIN FLOW (The 'if (_isLogin)' is now implied)
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCred.user;

      // Handle unverified email logic (Important security step)
      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        _showSnackbar(
            "Email not verified. Please check your inbox or spam folder.");
        return;
      }

      // Update FCM token on successful login
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (user != null && fcmToken != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': fcmToken,
        });
      }

      _showSnackbar('Login successful!');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Homepage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = 'Authentication Error: ${e.message}';
      }
      _showSnackbar(errorMessage);
    } catch (e) {
      _showSnackbar('An unexpected error occurred. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Removed _toggleForm() as it is no longer needed

  // Input field builder (Reused from your code)
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    const Color primaryColor = Color(0xFF1E88E5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(fontFamily: 'Quicksand'),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  // Login Form (Simplified to only the two required fields)
  Widget _buildLoginForm() {
    // Only two bottom fields: Email and Password
    return Column(
      children: [
        _buildInputField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          validator: (value) {
            if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
              return 'Please enter a valid email.';
            }
            return null;
          },
        ),
        _buildInputField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline,
          isPassword: true,
          validator: (value) {
            if (value == null || value.length < 6) {
              return 'Password must be at least 6 characters.';
            }
            return null;
          },
        ),
        // Keep Forgot Password option if needed
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _showSnackbar("Forgot Password functionality coming soon!"),
            child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF1E88E5))),
          ),
        ),
      ],
    );
  }

  // Removed _buildSignupForm() and _buildToggleItem()

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E88E5);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Header Logo/Text
              Center(
                child: Column(
                  children: [
                    // Ensure you have this asset or replace with a generic icon
                    Image.asset(
                      "assets/images/logon.png",
                      height: 150,
                      width: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.school, size: 80, color: primaryColor);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Welcome Back', // Simplified header text
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Removed the Auth Toggle Container

              Form(
                key: _formKey,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Column(
                    children: [
                      // Only display the Login form
                      _buildLoginForm(),
                      const SizedBox(height: 24),
                      // Login Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : const Text(
                          'LOG IN', // Hardcoded to 'LOG IN'
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Quicksand',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}