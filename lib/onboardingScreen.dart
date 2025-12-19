import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:student_unify_app/Login/signup.dart';
import 'package:student_unify_app/Login/StudentAlreadyAccount.dart';
import 'package:student_unify_app/Login/TermPage.dart';
import 'package:student_unify_app/Login/Non-StudentSignUp.dart';

import 'Login/NonStudentAlreadyAccount.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool isStudent = true; // true = Student, false = Non-Student

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.pinkAccent),
      ),
      body: Stack(
        children: [
          /// Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/images/image.png",
              fit: BoxFit.cover,
            ),
          ),

          /// Dark overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          /// CONTENT - Animated between student and non-student
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: isStudent
                  ? _buildStudentLoginContent()
                  : _buildNonStudentLoginContent(),
            ),
          ),
        ],
      ),
    );
  }

  // Student login content
  Widget _buildStudentLoginContent() {
    return Padding(
      key: const ValueKey('student'),
      padding: const EdgeInsets.only(top: 30, left: 30, right: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- Animated Toggle Button ---
          Row(
            children: [
              _buildAnimatedToggle(),
            ],
          ),

          const SizedBox(height: 150),

          /// Title: "Dear students"
          const Text(
            "Dear students,",
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
              fontFamily: 'Mont',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          /// Subtitle
          const Text(
            "Find what you need\n"
                "Share What You Have.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontFamily: "Mont",
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // --- "Sign Up" Button ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: SignupForm(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Sign Up",
                style: TextStyle(fontSize: 18, fontFamily: "Mont"),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- "I already have an account" Button ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  isDismissible: false,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: const StudentAlreadyAccount(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "I already have an account",
                style: TextStyle(
                    fontSize: 18, fontFamily: "Mont", color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Terms and privacy
          RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Mont',
                color: Colors.white,
                fontSize: 13,
              ),
              children: [
                const TextSpan(
                  text: "By signing up you agree to Stunify ",
                ),
                TextSpan(
                  text: "terms of service",
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.pinkAccent,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => TermsBottomSheet(),
                      );
                    },
                ),
                const TextSpan(
                  text: "\n",
                ),
                const WidgetSpan(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "and other privacy policy details",
                      style: TextStyle(
                        fontFamily: 'Mont',
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Non-Student login content
  Widget _buildNonStudentLoginContent() {
    return Padding(
      key: const ValueKey('non-student'),
      padding: const EdgeInsets.only(top: 30, left: 30, right: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- Animated Toggle Button ---
          Row(
            children: [
              _buildAnimatedToggle(),
            ],
          ),

          const SizedBox(height: 150),

          /// Title: "Dear non-students"
          const Text(
            "Dear non-students,",
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
              fontFamily: 'Mont',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          /// Subtitle
          const Text(
            "Share What You Have.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontFamily: "Mont",
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // --- "Sign Up" Button ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                SocialSignInModal.show(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Sign up",
                style: TextStyle(fontSize: 18, fontFamily: "Mont"),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- "I already have an account" Button ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                NonStudentSignUp.show(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "I already have an account",
                style: TextStyle(fontSize: 18, fontFamily: 'Mont'),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAnimatedToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isStudent = !isStudent;
        });
      },
      child: Container(
        height: 30,
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Animated sliding background
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment:
              isStudent ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                height: 30,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

            // Text labels
            Row(
              children: [
                // Student button
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isStudent
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                    ),
                    child: const Center(
                      child: Text("Student"),
                    ),
                  ),
                ),

                // Non-Student button
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: !isStudent
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                    ),
                    child: const Center(
                      child: Text("Non-Student"),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}