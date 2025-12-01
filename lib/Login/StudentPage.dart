import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../Home/Homepage.dart';

class Studentloginpage extends StatefulWidget {
  const Studentloginpage({super.key});

  @override
  State<Studentloginpage> createState() => _StudentloginpageState();
}

class _StudentloginpageState extends State<Studentloginpage> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

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
    super.dispose();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitForm() async {
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
        _showSnackbar("Email not verified. Check your inbox or spam folder.");
        return;
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (user != null && fcmToken != null) {
        await _firestore.collection('users').doc(user.uid).update({'fcmToken': fcmToken});
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Homepage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackbar(e.message ?? "Login failed.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildInput({
    required String label,
    required IconData icon,
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
          prefixIcon: Icon(icon, color: Colors.blue),
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
    const Color primaryColor = Color(0xFF1E88E5);

    return SafeArea(
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Close Button
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Logo
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
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildInput(
                        label: "Email",
                        icon: Icons.email_outlined,
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
                          onPressed: () {},
                          child: const Text("Forgot Password?"),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Login button
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
                        color: Colors.white),
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
