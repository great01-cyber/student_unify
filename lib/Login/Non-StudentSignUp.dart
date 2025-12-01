import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

// Home Page to trigger the Modal
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showSignUpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const StunifySignUpModalContent();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showSignUpModal(context),
          child: const Text('Show Stunify Sign Up Modal'),
        ),
      ),
    );
  }
}


// The Content for the Modal Sheet (Refined)
class StunifySignUpModalContent extends StatelessWidget {
  const StunifySignUpModalContent({super.key});

  void _handleSignIn(BuildContext context, String method) {
    debugPrint('Continuing with $method');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 10.0, // Reduced top padding to make space for the close button
        left: 32.0,
        right: 32.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // --- 1. Close Button (X) ---
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black54),
              onPressed: () => Navigator.pop(context), // Dismisses the modal
            ),
          ),

          const SizedBox(height: 10), // Spacing after the X

          // --- 2. Header Text and Subtitle ---
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Text(
                'Sign up for Stunify',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mont',
                ),
              ),
              SizedBox(height: 8),
              Text(
                "It's quickest to sign in with Apple ID",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Mont',
                ),
              ),
            ],
          ),

          const SizedBox(height: 50),

          // --- 3. Apple ID Button (Black Filled) ---
          ElevatedButton.icon(
            onPressed: () => _handleSignIn(context, 'Apple'),
            icon: const Icon(Icons.apple, color: Colors.white),
            label: const Text(
              'Continue with Apple',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- 4. Faint Underline (Divider) ---
          const Divider(
            color: Colors.grey,
            thickness: 0.5,
          ),

          const SizedBox(height: 20),

          // --- 5. Google Button (REVERTED to Transparent Outline) ---
          OutlinedButton.icon(
            onPressed: () => _handleSignIn(context, 'Google'),
            icon: Image.asset(
              'assets/images/google.png', // Placeholder
              height: 24.0,
            ),
            label: const Text(
              'Continue with Google',
              style: TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Mont'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
              // REVERTED: Transparent border (no compression/outline)
              side: const BorderSide(color: Colors.black),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // --- 6. Facebook Button (REVERTED to Transparent Outline) ---
          OutlinedButton.icon(
            onPressed: () => _handleSignIn(context, 'Facebook'),
            icon: const Icon(
              Icons.facebook,
              color: Colors.blue,
              size: 24.0,
            ),
            label: const Text(
              'Continue with Facebook',
              style: TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Mont'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
              // REVERTED: Transparent border (no compression/outline)
              side: const BorderSide(color: Colors.black),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}