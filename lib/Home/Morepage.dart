import 'package:flutter/material.dart';

// Assuming these pages exist in your project structure
import '../listings/BorrowPage.dart';
import '../listings/Donate.dart';
import '../listings/Exchange.dart';
import '../listings/LendPage.dart';
import '../listings/Sell.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  // Define the font family constant for easy use
  static const String _fontFamily = 'Mont';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Options',
          style: TextStyle(fontFamily: _fontFamily), // Use 'Mont' here
        ),
        backgroundColor: Colors.blueGrey[50],
      ),
      backgroundColor: Colors.grey[100],
      // Pass the font family down to the grid
      body: const ButtonGrid(fontFamily: _fontFamily),
    );
  }
}

// -----------------------------------------------------------------
// The Grid Widget - Now correctly accepts and uses the font
// -----------------------------------------------------------------
class ButtonGrid extends StatelessWidget {
  final String fontFamily;

  const ButtonGrid({super.key, required this.fontFamily});

  // Method to show the alert box with the specified font
  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Coming Soon",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: fontFamily, // Use 'Mont' here
            ),
          ),
          content: Text(
            "This feature will be available soon. Please check back later.",
            style: TextStyle(
              fontFamily: fontFamily, // Use 'Mont' here
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "OK",
                style: TextStyle(
                  color: Colors.blue,
                  fontFamily: fontFamily, // Use 'Mont' here
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onButtonTap(BuildContext context, String buttonName, String pageTitle) {
    // 1. CHECK FOR "COMING SOON" FEATURES (Borrow, Exchange, Sell)
    if (buttonName == 'Borrow' || buttonName == 'Exchange' || buttonName == 'Sell') {
      _showComingSoonDialog(context);
      return; // Stop navigation
    }

    // 2. FOR ALL OTHER BUTTONS ('Donate', 'Lend'), PROCEED WITH NAVIGATION
    Widget pageToNavigateTo;

    switch (buttonName) {
      case 'Lend':
        pageToNavigateTo = LendPage(title: 'Lend',);
        break;
      case 'Donate':
        pageToNavigateTo = Donate(title: 'Donate',);
        break;
      default:
        return;
    }

    // Navigation code for features that are ready
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pageToNavigateTo),
    );
  }

  @override
  Widget build(BuildContext context) {
    const String donateSubtitle = "Donate an Item";
    const String borrowSubtitle = "Lend an Item";
    const String lendSubtitle = "Request an Item";
    const String exchangeSubtitle = "Exchange an Item";
    const String sellSubtitle = "Sell an Item";

    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(8.0),
      crossAxisSpacing: 8.0,
      mainAxisSpacing: 8.0,
      children: [
        // Donate Button (Navigates)
        FancifulButton(
          label: 'Donate',
          subtitle: donateSubtitle,
          icon: Icons.favorite,
          color: Color(0xFF6366F1),
          onPressed: () => _onButtonTap(context, 'Donate', donateSubtitle),
          fontFamily: fontFamily,
        ),

        // Request/Lend Button (Navigates)
        FancifulButton(
          label: 'Request',
          subtitle: lendSubtitle,
          icon: Icons.outbox,
          color: Colors.green,
          onPressed: () => _onButtonTap(context, 'Lend', lendSubtitle),
          fontFamily: fontFamily,
        ),

        // Borrow Button (Alert Box)
        FancifulButton(
          label: 'Borrow',
          subtitle: borrowSubtitle,
          icon: Icons.move_to_inbox,
          color: Colors.blue,
          onPressed: () => _onButtonTap(context, 'Borrow', borrowSubtitle),
          fontFamily: fontFamily,
        ),

        // Exchange Button (Alert Box)
        FancifulButton(
          label: 'Exchange',
          subtitle: exchangeSubtitle,
          icon: Icons.swap_horiz,
          color: Colors.orange,
          onPressed: () => _onButtonTap(context, 'Exchange', exchangeSubtitle),
          fontFamily: fontFamily,
        ),

        // Sell Button (Alert Box)
        FancifulButton(
          label: 'Sell',
          subtitle: sellSubtitle,
          icon: Icons.sell,
          color: Colors.purple,
          onPressed: () => _onButtonTap(context, 'Sell', sellSubtitle),
          fontFamily: fontFamily,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------
// The Custom Button Widget - Corrected to use 'fontFamily' argument
// -----------------------------------------------------------------
class FancifulButton extends StatelessWidget {
  const FancifulButton({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    required this.fontFamily, // Correct property name
    this.color = Colors.grey,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: color.withOpacity(0.8),
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32.0,
                color: color,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Container(
                  height: 2.0,
                  width: 30.0,
                  color: color.withOpacity(0.7),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: fontFamily,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.0,
                  color: Colors.grey[600],
                  fontFamily: fontFamily,
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