import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:student_unify_app/Login/signup.dart';

import 'TermPage.dart';

class StudentLogin extends StatelessWidget {
  const StudentLogin({super.key});

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
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
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
                      GestureDetector(
                          child: Container(
                            height: 30,
                            width: 90,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pinkAccent.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Text(
                              "Student",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.pinkAccent,
                              ),
                            ),
                          )
                      ),
                    ],
                  ),

                  // 🎯 PUSH DOWN: Increased this spacer significantly
                  const SizedBox(height: 150),

                  const SizedBox(height: 10),

                  /// Subtitle
                  const Text(
                    "Find What You Need.\n"
                        "Share What You Have.",
                    style: TextStyle(
                      color: Colors.white ,
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
                  // --- "signup" Button ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true, // makes it full height if needed
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: SignupForm(), // Your signup form widget
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
                  RichText(
                    textAlign: TextAlign.left, // whole widget aligns to the left
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
                            color: Colors.blueAccent,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (context) => TermsBottomSheet(),
                              );
                            },
                        ),
                        const TextSpan(
                          text: "\n",
                        ),
                        WidgetSpan(
                          child: Align(
                            alignment: Alignment.center, // only the second line centered
                            child: Text(
                              "and other privacy policy details",
                              style: const TextStyle(
                                fontFamily: 'Mont',
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}