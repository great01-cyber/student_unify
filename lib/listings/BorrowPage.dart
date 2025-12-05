import 'package:flutter/material.dart';

class BorrowPage extends StatefulWidget {
  const BorrowPage({super.key});

  @override
  State<BorrowPage> createState() => _BorrowPageState();
}

class _BorrowPageState extends State<BorrowPage> {
  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Coming Soon",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "This feature will be available soon. Please check back later.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
    // We use a GestureDetector to make the entire screen/widget area clickable.
    return GestureDetector(
      // The moment the user taps anywhere on this widget, the dialog will show.
      onTap: _showComingSoonDialog,

      // Since you don't want an AppBar or Scaffold, we return a simple Container.
      // I've added some centered placeholder text so the user knows they are on the page.
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_clock,
              size: 50,
              color: Colors.grey,
            ),
            SizedBox(height: 10),
            Text(
              "Tap anywhere to view feature status",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}