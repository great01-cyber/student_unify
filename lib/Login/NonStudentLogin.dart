import 'package:flutter/material.dart';

import 'Non-StudentSignUp.dart';

class NonStudentLogin extends StatelessWidget {
  const NonStudentLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.pinkAccent),
      ),
      body: Stack(
        children: [
          /// Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/images/image.png", // change to your image path
              fit: BoxFit.cover,
            ),
          ),

          /// Dark overlay for readability (optional)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          /// CONTENT
          SafeArea(
            // Increased top padding slightly for overall breathing room
            child: Padding(
              padding: const EdgeInsets.only(top: 30, left: 30, right: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Role Selection Buttons ---
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      GestureDetector(
                        child: Container(
                          height: 30,
                          width: 90,
                          child: Center(
                            child: Text(
                              "Non-Student",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),

                        ),
                      ),
                    ],
                  ),

                  // 🎯 PUSH DOWN: Increased this spacer significantly
                  const SizedBox(height: 150),

                  /// Title: "Dear students"
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

                  // The remaining space here is flexible due to 'Expanded' below,
                  // but we ensure the content above is pushed down.

                  // Use a Spacer to push the remaining buttons to the very bottom
                  const Spacer(),

                  // --- "signup" Button ---
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
                      onPressed: () {},
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

                  // Add padding to ensure buttons clear the bottom edge of the screen
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
