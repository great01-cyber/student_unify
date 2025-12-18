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
      backgroundColor: Colors.transparent,
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
  int _currentStep = 0;

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _universityEmailController = TextEditingController();
  final TextEditingController _personalEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _universityNameController = TextEditingController();
  final TextEditingController _graduationYearController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Color primaryColor = Color(0xFFFF6786);
  static const Color secondaryColor = Color(0xFFFFF0F3);
  static const Color textColor = Color(0xFF2D3142);

  @override
  void dispose() {
    _displayNameController.dispose();
    _universityEmailController.dispose();
    _personalEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _universityNameController.dispose();
    _graduationYearController.dispose();
    super.dispose();
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final displayName = _displayNameController.text.trim();
    final universityEmail = _universityEmailController.text.trim();
    final personalEmail = _personalEmailController.text.trim();
    final password = _passwordController.text.trim();
    final university = _universityNameController.text.trim();
    final graduationYear = _graduationYearController.text.trim();

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: universityEmail,
        password: password,
      );

      final firebaseUser = userCredential.user!;
      await firebaseUser.sendEmailVerification();

      if (displayName.isNotEmpty) {
        await firebaseUser.updateDisplayName(displayName);
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();

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

      final newUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        personalEmail: personalEmail.isNotEmpty ? personalEmail : null,
        displayName: displayName,
        emailVerified: false,
        createdAt: DateTime.now(),
        university: university,
        graduationYear: int.tryParse(graduationYear),
        fcmTokens: fcmToken != null ? [fcmToken] : [],
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
      await _auth.signOut();

      _showMessage('Account created! Please check your email to verify.', isError: false);

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'An account already exists for that email.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Must be 8+ chars, contain an uppercase letter, and a number.';
          break;
        case 'invalid-email':
          errorMessage = 'The provided email is invalid.';
          break;
        default:
          errorMessage = 'Authentication Error: ${e.message}';
      }
      _showMessage(errorMessage);
    } catch (e) {
      _showMessage('An unexpected error occurred. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_displayNameController.text.trim().isEmpty) {
        _showMessage('Please enter your full name.');
        return;
      }
      if (_universityEmailController.text.trim().isEmpty ||
          !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(_universityEmailController.text.trim())) {
        _showMessage('Please enter a valid university email.');
        return;
      }
      if (_universityNameController.text.trim().isEmpty) {
        _showMessage('Please select your university.');
        return;
      }
      if (_graduationYearController.text.trim().isEmpty) {
        _showMessage('Please enter your graduation year.');
        return;
      }
      setState(() => _currentStep = 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? helpText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: const TextStyle(fontFamily: 'Mont', fontSize: 15),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey.shade600),
            prefixIcon: Icon(icon, color: primaryColor, size: 22),
            filled: true,
            fillColor: secondaryColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            errorMaxLines: 2,
          ),
          validator: validator,
        ),
        if (helpText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    helpText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: 'Mont',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0),
        Container(
          width: 40,
          height: 2,
          color: _currentStep > 0 ? primaryColor : Colors.grey.shade300,
          margin: const EdgeInsets.symmetric(horizontal: 8),
        ),
        _buildStepDot(1),
      ],
    );
  }

  Widget _buildStepDot(int step) {
    bool isActive = step == _currentStep;
    bool isCompleted = step < _currentStep;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive || isCompleted ? primaryColor : Colors.grey.shade300,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
          '${step + 1}',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontFamily: 'Mont',
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
            fontFamily: 'Mont',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let\'s get to know you better',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontFamily: 'Mont',
          ),
        ),
        const SizedBox(height: 28),
        _buildInputField(
          controller: _displayNameController,
          label: 'Full Name',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Full name is required';
            return null;
          },
        ),
        _buildInputField(
          controller: _universityEmailController,
          label: 'University Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          helpText: 'Use your official student email (e.g., student@university.ac.uk)',
          validator: (value) {
            if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
              return 'A valid university email is required';
            }
            return null;
          },
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
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
                style: const TextStyle(fontFamily: 'Mont', fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'University Name',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: const Icon(Icons.school_outlined, color: primaryColor, size: 22),
                  filled: true,
                  fillColor: secondaryColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  errorMaxLines: 2,
                ),
                onChanged: (value) {
                  _universityNameController.text = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'University name is required';
                  return null;
                },
              );
            },
          ),
        ),
        _buildInputField(
          controller: _graduationYearController,
          label: 'Expected Graduation Year',
          icon: Icons.calendar_today_outlined,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Graduation year is required';
            final year = int.tryParse(value);
            if (year == null || year < DateTime.now().year || year > DateTime.now().year + 10) {
              return 'Please enter a valid year';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Security',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
            fontFamily: 'Mont',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create a secure password and add recovery options',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontFamily: 'Mont',
          ),
        ),
        const SizedBox(height: 28),
        _buildInputField(
          controller: _personalEmailController,
          label: 'Personal Email (Optional but Recommended)',
          icon: Icons.alternate_email,
          keyboardType: TextInputType.emailAddress,
          helpText: 'For account recovery and alumni updates after graduation',
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
            }
            return null;
          },
        ),
        _buildInputField(
          controller: _passwordController,
          label: 'Create Password',
          icon: Icons.lock_outline,
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please create a password';
            if (value.length < 8) return 'Password must be at least 8 characters';
            if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) return 'Needs an uppercase letter';
            if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) return 'Needs at least one number';
            return null;
          },
        ),
        _buildInputField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          icon: Icons.lock_open_outlined,
          isPassword: true,
          validator: (value) {
            if (value != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Join Stunify',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'Mont',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connect with students nationwide',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontFamily: 'Mont',
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildStepIndicator(),
                      const SizedBox(height: 32),
                      _currentStep == 0 ? _buildStep1() : _buildStep2(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          if (_currentStep > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _previousStep,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: primaryColor, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'BACK',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                    fontFamily: 'Mont',
                                  ),
                                ),
                              ),
                            ),
                          if (_currentStep > 0) const SizedBox(width: 12),
                          Expanded(
                            flex: _currentStep == 0 ? 1 : 2,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : (_currentStep == 0 ? _nextStep : _submitForm),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                                  : Text(
                                _currentStep == 0 ? 'CONTINUE' : 'CREATE ACCOUNT',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Mont',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_currentStep == 0) ...[
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}