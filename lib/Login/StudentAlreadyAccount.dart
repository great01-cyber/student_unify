import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Home/Homepage.dart';
import 'forgot_password.dart';

class StudentAlreadyAccount extends StatefulWidget {
  const StudentAlreadyAccount({super.key});

  @override
  State<StudentAlreadyAccount> createState() => _StudentloginpageState();
}

class _StudentloginpageState extends State<StudentAlreadyAccount>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  String? _loginErrorMessage;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    _loadSavedLoginDetails(); // <-- Load saved email/password

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  // --- Load Saved Email & Password ---
  Future<void> _loadSavedLoginDetails() async {
    final prefs = await SharedPreferences.getInstance();
    _emailController.text = prefs.getString("saved_email") ?? "";
    _passwordController.text = prefs.getString("saved_password") ?? "";
  }

  // --- Save Email & Password ---
  Future<void> _saveLoginDetails(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("saved_email", email);
    await prefs.setString("saved_password", password);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIN FUNCTION ---
  Future<void> _submitForm() async {
    setState(() {
      _loginErrorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      UserCredential userCred =
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      User? user = userCred.user;

      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        setState(() {
          _loginErrorMessage =
          "Email not verified. Check your inbox or spam folder.";
          _isLoading = false;
        });
        return;
      }

      // --- Save login details to SharedPreferences ---
      await _saveLoginDetails(email, password);

      // Update FCM Token
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (user != null && fcmToken != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': fcmToken,
          });
        }
      } catch (e) {
        debugPrint("FCM Token error: $e");
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Homepage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case "user-not-found":
          message = "Email not found.";
          break;
        case "wrong-password":
          message = "Incorrect password.";
          break;
        case "invalid-email":
          message = "Invalid email format.";
          break;
        case "invalid-credential":
          message = "Invalid email or password.";
          break;
        case "user-disabled":
          message = "This account has been disabled.";
          break;
        case "too-many-requests":
          message = "Too many attempts. Try again later.";
          break;
        default:
          message = "An unknown error occurred.";
      }

      if (mounted) {
        setState(() {
          _loginErrorMessage = message;
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _loginErrorMessage = "An unexpected error occurred.";
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && _loginErrorMessage != null) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildInput({
    required String label,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    bool isPassword = false,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: color),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Colors.pinkAccent;

    return SafeArea(
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 28, color: primaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/images/logon.png",
                        height: 140,
                        width: 140,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.school, size: 80, color: primaryColor),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                          fontFamily: 'Mont',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildInput(
                        label: "Email",
                        icon: Icons.email_outlined,
                        color: primaryColor,
                        controller: _emailController,
                        validator: (value) {
                          if (value == null ||
                              !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                            return 'Enter a valid email.';
                          }
                          return null;
                        },
                      ),
                      _buildInput(
                        label: "Password",
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        color: primaryColor,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Simply call the modal's show method
                            ForgotPasswordModal.show(context);
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(fontFamily: 'Mont'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_loginErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _loginErrorMessage!,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "LOG IN",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Mont'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
