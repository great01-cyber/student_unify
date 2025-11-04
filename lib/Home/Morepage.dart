import 'package:flutter/material.dart';

class Morepage extends StatefulWidget {
  const Morepage({super.key});

  @override
  State<Morepage> createState() => _MorepageState();
}

class _MorepageState extends State<Morepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More Options'),
        backgroundColor: Colors.blueGrey,
      ),
      // Set a light background color
      backgroundColor: Colors.grey[100],
      // The ButtonGrid is the main content of the page
      body: const ButtonGrid(),
    );
  }
}

// -----------------------------------------------------------------
// The Grid Widget
// -----------------------------------------------------------------
class ButtonGrid extends StatelessWidget {
  const ButtonGrid({super.key});

  // A simple handler for all button taps
  void _onButtonTap(String buttonName) {
    print('$buttonName button tapped!');
    // You would add your navigation or logic here
    // e.g., Navigator.push(context, MaterialPageRoute(builder: ...));
  }

  @override
  Widget build(BuildContext context) {
    // GridView.count creates a grid with a fixed number of columns
    return GridView.count(
      // 2 columns
      crossAxisCount: 3,
      // Reduced padding around the entire grid
      padding: const EdgeInsets.all(8.0),
      // Reduced spacing between items horizontally
      crossAxisSpacing: 8.0,
      // Reduced spacing between items vertically
      mainAxisSpacing: 8.0,
      // Define the 5 buttons
      children: [
        FancifulButton(
          label: 'Borrow',
          icon: Icons.move_to_inbox, // 📥
          color: Colors.blue,
          onPressed: () => _onButtonTap('Borrow'),
        ),
        FancifulButton(
          label: 'Lend',
          icon: Icons.outbox, // 📤
          color: Colors.green,
          onPressed: () => _onButtonTap('Lend'),
        ),
        FancifulButton(
          label: 'Donate',
          icon: Icons.favorite, // 💖
          color: Colors.red,
          onPressed: () => _onButtonTap('Donate'),
        ),
        FancifulButton(
          label: 'Exchange',
          icon: Icons.swap_horiz, // 🔄
          color: Colors.orange,
          onPressed: () => _onButtonTap('Exchange'),
        ),
        FancifulButton(
          label: 'Sell',
          icon: Icons.sell, // 🏷️
          color: Colors.purple,
          onPressed: () => _onButtonTap('Sell'),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------
// The Custom Button Widget (Smaller + Colored Outline)
// -----------------------------------------------------------------
class FancifulButton extends StatelessWidget {
  const FancifulButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = Colors.grey,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      // Lighter shadow
      elevation: 1.0,
      // Rounded corners AND colored outline
      shape: RoundedRectangleBorder(
        // --- THIS IS THE NEW OUTLINE ---
        side: BorderSide(
          color: color.withOpacity(0.8), // Use the button's color
          width: 2.0,
        ),
        // ---
        borderRadius: BorderRadius.circular(8.0), // Slightly smaller radius
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // The tap handler
        onTap: onPressed,
        // The content of the button
        child: Padding(
          // Reduced padding to make button smaller
          padding: const EdgeInsets.all(8.0),
          child: Column(
            // Center the content
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                // Reduced icon size
                size: 32.0,
                color: color,
              ),
              // This is the colored underline (now smaller)
              Padding(
                // Reduced vertical padding
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Container(
                  // Reduced height and width
                  height: 2.0,
                  width: 30.0,
                  color: color.withOpacity(0.7), // Use the button's color
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  // Reduced font size
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}