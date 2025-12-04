import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:student_unify_app/services/AppUser.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

import '../Home/widgets/ukUniversities.dart';

class SignupModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Use transparent for overlay effect
      builder: (_) => const SignupForm(),
    );
  }
}

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => SignupFormState();
}

class SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _universityNameController = TextEditingController();
  final TextEditingController _cityNameController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Color primaryColor = Color(0xFFFF6786); // Pink color

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _universityNameController.dispose();
    _cityNameController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade600,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final university = _universityNameController.text.trim();
    final city = _cityNameController.text.trim();

    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user!;
      await firebaseUser.sendEmailVerification();

      if (displayName.isNotEmpty) {
        await firebaseUser.updateDisplayName(displayName);
      }

      // 1️⃣ Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();

      // 2️⃣ Get device location
      Position? position;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _showSnackbar('Please enable location services.', isError: true);
        } else {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            _showSnackbar('Location permission denied.', isError: true);
          } else {
            position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high);
          }
        }
      } catch (e) {
        debugPrint('Error getting location: $e');
      }

      // 3️⃣ Save user data with latitude & longitude
      final newUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: displayName,
        emailVerified: false,
        createdAt: DateTime.now(),
        university: university,
        city: city,
        fcmToken: fcmToken ?? '',
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
      await _auth.signOut();

      _showSnackbar('Account created! Please check your email to verify.', isError: false);
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'An account already exists for that email.';
          break;
        case 'weak-password':
          errorMessage =
          'Password is too weak. Must be 8+ chars, contain an uppercase letter, and a number.';
          break;
        case 'invalid-email':
          errorMessage = 'The provided email is invalid.';
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


  // Input field builder
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(fontFamily: 'Mont'),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          errorMaxLines: 2,
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Title + Cancel Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SignUp with Stunify',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontFamily: 'Mont',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: primaryColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Full Name
                _buildInputField(
                  controller: _displayNameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Full name is required.';
                    return null;
                  },
                ),
                // Email
                _buildInputField(
                  controller: _emailController,
                  label: 'University Email',
                  icon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                      return 'A valid university email is required.';
                    }
                    return null;
                  },
                ),
                // University Autocomplete
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      final matches = ukUniversities.map((university) {
                        final similarity = StringSimilarity.compareTwoStrings(
                          textEditingValue.text.toLowerCase(),
                          university.toLowerCase(),
                        );
                        return {'university': university, 'score': similarity};
                      }).toList();
                      matches.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
                      return matches
                          .where((match) => match['score'] as double > 0.2)
                          .map((match) => match['university'] as String);
                    },
                    onSelected: (String selection) {
                      _universityNameController.text = selection;
                      FocusScope.of(context).unfocus();
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      controller.text = _universityNameController.text;
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        style: const TextStyle(fontFamily: 'Mont'),
                        decoration: InputDecoration(
                          labelText: 'University Name',
                          prefixIcon: const Icon(Icons.school_outlined, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryColor, width: 2),
                          ),
                          errorMaxLines: 2,
                        ),
                        onChanged: (value) {
                          _universityNameController.text = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'University name is required.';
                          return null;
                        },
                      );
                    },
                  ),
                ),
                // City
                _buildInputField(
                  controller: _cityNameController,
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'City name is required.';
                    return null;
                  },
                ),
                // Password
                _buildInputField(
                  controller: _passwordController,
                  label: 'Create Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please create a password.';
                    if (value.length < 8) return 'Password must be at least 8 characters.';
                    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) return 'Password needs an uppercase letter.';
                    if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) return 'Password needs at least one number.';
                    return null;
                  },
                ),
                // Confirm Password
                _buildInputField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_open_outlined,
                  isPassword: true,
                  validator: (value) {
                    if (value != _passwordController.text) return 'Passwords do not match.';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 80),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text(
                    'SIGN UP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
  }
}
