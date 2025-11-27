import 'dart:async';
import 'package:flutter/material.dart';
// NOTE: Assuming you have this file for navigation
import 'onboardingScreen.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // 1. State variable for the animation (opacity starts at 0, fully transparent)
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // 2. Start the animation immediately after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0; // Fade in the text
      });
    });

    // 3. 🎯 Add the Timer logic for automatic navigation (e.g., after 3 seconds)
    Timer(const Duration(seconds: 8), () {
      if (mounted) {
        // Navigate to the next screen after the delay
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. 🎯 STUNIFY TEXT: Now wrapped in AnimatedOpacity
          Center(
            child: AnimatedOpacity(
              opacity: _opacity, // Controlled by the state variable
              duration: const Duration(milliseconds: 800), // How long the fade takes
              curve: Curves.easeIn, // Smooth acceleration
              child: const Text(
                "stunify",
                style: TextStyle(
                  color: Color(0xFFeb5777),
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Quicksand',
                ),
              ),
            ),
          ),

          // 2. 🎯 IMAGE: Positioned at the bottom edge, filling the width (Unchanged)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image(
              image: const AssetImage("assets/images/Frame.png"),
              width: screenWidth,
              height: 370,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}