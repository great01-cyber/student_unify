import 'package:flutter/material.dart';



class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  // Use 'true' for Login form initially
  bool _isLogin = true;

  // Global Key for form validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Animation controller for form transition
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

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
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Logic for Login/Signup goes here
      // For this example, we just navigate to the main screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Scaffold()),
      );
    }
  }

  void _toggleForm() {
    setState(() {
      _isLogin = !_isLogin;
    });
    // Rerun animation to make the new form fade in
    _animationController.forward(from: 0.0);
  }


  // --- Helper Widget for Input Fields ---
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
        style: const TextStyle(fontFamily: 'Quicksand'),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  // --- Login Form Widgets ---
  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildInputField(
          controller: _emailController,
          label: 'University Email',
          icon: Icons.email_outlined,
          validator: (value) {
            if (value == null || !value.contains('@')) {
              return 'Please enter a valid university email.';
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
            onPressed: () {
              // TODO: Implement Forgot Password Logic
            },
            child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF1E88E5))),
          ),
        ),
      ],
    );
  }

  // --- Sign Up Form Widgets ---
  Widget _buildSignupForm() {
    return Column(
      children: [
        _buildInputField(
          controller: _emailController,
          label: 'University Email',
          icon: Icons.school_outlined,
          validator: (value) {
            if (value == null || !value.contains('@')) {
              return 'A valid university email is required for verification.';
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
            if (value == null || value.length < 6) {
              return 'Password must be at least 6 characters.';
            }
            return null;
          },
        ),
        _buildInputField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          icon: Icons.lock_open_outlined,
          isPassword: true,
          validator: (value) {
            if (value != _passwordController.text) {
              return 'Passwords do not match.';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Use primary color variables for better consistency
    const Color primaryColor = Color(0xFF1E88E5);
    const Color lightGray = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          // Added vertical padding to give more breathing room at the top/bottom
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ----------------------------------------------------
              // 1. LOGO/TITLE SECTION (Corrected Syntax)
              // ----------------------------------------------------
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      "assets/images/logon.png", // Ensure this asset is available
                      height: 350,
                      width: 350,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if image asset is not found
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
              const SizedBox(height: 40), // Increased spacing after the logo

              // ----------------------------------------------------
              // 2. Login/Signup Toggle
              // ----------------------------------------------------
              Container(
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: BorderRadius.circular(30),
                  // Optional: Add a subtle border to the whole toggle container
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Row(
                  children: [
                    // _buildToggleItem should handle its own expanded layout
                    _buildToggleItem(label: 'Login', isSelected: _isLogin, onPressed: _toggleForm),
                    _buildToggleItem(label: 'Sign Up', isSelected: !_isLogin, onPressed: _toggleForm),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ----------------------------------------------------
              // 3. Form Section with Fade Animation
              // ----------------------------------------------------
              Form(
                key: _formKey,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Column(
                    children: [
                      // Form content changes based on the toggle state
                      _isLogin ? _buildLoginForm() : _buildSignupForm(),

                      const SizedBox(height: 24), // Increased spacing before button

                      // Main Action Button
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          // Added slight elevation for a raised look
                          elevation: 5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
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

  // --- Helper Widget for the Toggle Switch ---
  Widget _buildToggleItem({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: isSelected ? null : onPressed, // Only toggle if not already selected
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: isSelected ? Border.all(color: const Color(0xFF1E88E5), width: 1.5) : null,
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFF757575),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'Quicksand',
              ),
            ),
          ),
        ),
      ),
    );
  }
}