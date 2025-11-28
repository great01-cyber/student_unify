import 'package:flutter/material.dart';
import 'package:student_unify_app/Login/NonStudentLogin.dart';
import 'package:student_unify_app/Login/StudentPage.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              padding: const EdgeInsets.only(top: 80, left: 30, right: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Role Selection Buttons ---
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => StudentLogin()),  // ← replace with your screen
                          );
                        },
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
                        ),

                      ),
                      const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NonStudentLogin()),  // ← replace with your screen
                );
              },
              child: Container(
                height: 30,
                width: 90,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Non-Student",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
                    ],
                  ),

                  // 🎯 PUSH DOWN: Increased this spacer significantly
                  const SizedBox(height: 300),
                  const SizedBox(height: 10),

                  /// Subtitle
                  const Text(
                    "Find What You Need.\n"
                        "Share What You Have.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontFamily: "Mont",
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}