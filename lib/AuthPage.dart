import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:student_unify_app/services/AppUser.dart';
import 'package:string_similarity/string_similarity.dart';



import 'Home/Homepage.dart';
import 'Home/widgets/ukUniversities.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _universityName = TextEditingController();
  final TextEditingController _cityName = TextEditingController();

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
    _confirmPasswordController.dispose();
    _universityName.dispose();
    _cityName.dispose();
    super.dispose();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final university = _universityName.text.trim();
    final city = _cityName.text.trim();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // LOGIN FLOW
        UserCredential userCred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        User? user = userCred.user;

        if (user != null && !user.emailVerified) {
          await _auth.signOut();
          _showSnackbar(
              "Email not verified. Please check your inbox or spam folder to verify your account."
          );
          return;
        }

        _showSnackbar('Login successful!');

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => Homepage()),
          );
        }
      } else {
        // --- SIGN-UP FLOW ---
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final firebaseUser = userCredential.user!;
        await firebaseUser.sendEmailVerification();

        final newUser = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          emailVerified: false,
          createdAt: DateTime.now(),
          university: university,
          city: city,
          fcmToken: '',
        );

        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toMap());

        // Sign out to prevent automatic navigation
        await _auth.signOut();

        _showSnackbar('Account created! Please check your email to verify and log in.');
        _toggleForm();
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
        case 'email-already-in-use':
          errorMessage = 'An account already exists for that email.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak.';
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

  void _toggleForm() {
    if (_isLoading) return; // Prevent toggle during loading

    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _universityName.clear();
    _cityName.clear();
    _formKey.currentState?.reset();

    setState(() => _isLogin = !_isLogin);
    _animationController.forward(from: 0.0);
  }

  // Helper Input Field Widget
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

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildInputField(
          controller: _emailController,
          label: 'University Email',
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

  Widget _buildSignupForm() {
    return Column(
      children: [
        _buildInputField(
          controller: _emailController,
          label: 'University Email',
          icon: Icons.school_outlined,
          validator: (value) {
            if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
              return 'A valid university email is required.';
            }
            return null;
          },
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }

              // Fuzzy matching using string_similarity
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
              _universityName.text = selection; // Save selected value
            },
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              controller.text = _universityName.text;
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'University Name',
                  prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF1E88E5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'University name is required.';
                  return null;
                },
              );
            },
          ),
        ),

        _buildInputField(
          controller: _cityName,
          label: 'City',
          icon: Icons.location_city_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'City name is required.';
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
            if (value == null || value.isEmpty) return 'Please create a password.';
            if (value.length < 8) return 'Password must be at least 8 characters.';
            if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) return 'Password needs an uppercase letter.';
            if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) return 'Password needs at least one number.';
            return null;
          },
        ),
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
      ],
    );
  }

  Widget _buildToggleItem({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    const Color primaryColor = Color(0xFF1E88E5);
    const Color lightGray = Color(0xFFF5F5F5);

    return Expanded(
      child: GestureDetector(
        onTap: isSelected ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: isSelected ? Border.all(color: primaryColor, width: 1.5) : null,
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : const Color(0xFF757575),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'Quicksand',
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E88E5);
    const Color lightGray = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // LOGO
              Center(
                child: Column(
                  children: [
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
                      'Student Sharing App',
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

              // Toggle
              Container(
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Row(
                  children: [
                    _buildToggleItem(label: 'Login', isSelected: _isLogin, onPressed: _toggleForm),
                    _buildToggleItem(label: 'Sign Up', isSelected: !_isLogin, onPressed: _toggleForm),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Form
              Form(
                key: _formKey,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Column(
                    children: [
                      _isLogin ? _buildLoginForm() : _buildSignupForm(),
                      const SizedBox(height: 24),
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
                            : Text(
                          _isLogin ? 'LOG IN' : 'SIGN UP',
                          style: const TextStyle(
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
