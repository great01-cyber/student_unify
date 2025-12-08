import 'package:flutter/material.dart';

class Exchangepage extends StatefulWidget {
  const Exchangepage({super.key});

  @override
  State<Exchangepage> createState() => _ExchangepageState();
}

class _ExchangepageState extends State<Exchangepage> {
  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Coming Soon!",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "This feature is under development and will be available soon.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // just closes the dialog
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exchange Page"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _showComingSoonDialog,
          child: const Text("Use Exchange Feature"),
        ),
      ),
    );
  }
}
