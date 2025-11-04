import 'package:flutter/material.dart';

import '../listings/BorrowPage.dart';
import '../listings/Donate.dart';
import '../listings/Exchange.dart';
import '../listings/LendPage.dart';
import '../listings/Sell.dart';

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
      backgroundColor: Colors.grey[100],
      body: const ButtonGrid(),
    );
  }
}

// -----------------------------------------------------------------
// The Grid Widget
// -----------------------------------------------------------------
class ButtonGrid extends StatelessWidget {
  const ButtonGrid({super.key});

  void _onButtonTap(BuildContext context, String buttonName, String pageTitle) {
    Widget pageToNavigateTo;

    switch (buttonName) {
    // --- MODIFICATION 2: Pass 'pageTitle' to the page constructor ---
      case 'Borrow':
        pageToNavigateTo = Borrowpage();
        break;
      case 'Lend':
        pageToNavigateTo = LendPage();
        break;
      case 'Donate':
        pageToNavigateTo = DonatePage();
        break;
      case 'Exchange':
        pageToNavigateTo = ExchangePage();
        break;
      case 'Sell':
        pageToNavigateTo = SellPage();
        break;
      default:
        print('$buttonName button tapped!');
        return;
    }

    // This navigation code now sends the page with the title
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pageToNavigateTo),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- MODIFICATION 1: Define the subtitles ---
    // This makes the code cleaner.
    const String borrowSubtitle = "Borrow an Item";
    const String lendSubtitle = "Lend an Item";
    const String donateSubtitle = "Donate an Item";
    const String exchangeSubtitle = "Exchange an Item";
    const String sellSubtitle = "Sell an Item";

    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(8.0),
      crossAxisSpacing: 8.0,
      mainAxisSpacing: 8.0,
      children: [
        // --- MODIFICATION 2: Pass the subtitle to the button ---
        FancifulButton(
          label: 'Borrow',
          subtitle: borrowSubtitle, // Pass subtitle
          icon: Icons.move_to_inbox,
          color: Colors.blue,
          onPressed: () => _onButtonTap(context, 'Borrow', borrowSubtitle),
        ),
        FancifulButton(
          label: 'Lend',
          subtitle: lendSubtitle, // Pass subtitle
          icon: Icons.outbox,
          color: Colors.green,
          onPressed: () => _onButtonTap(context, 'Lend', lendSubtitle),
        ),
        FancifulButton(
          label: 'Donate',
          subtitle: donateSubtitle, // Pass subtitle
          icon: Icons.favorite,
          color: Colors.red,
          onPressed: () => _onButtonTap(context, 'Donate', donateSubtitle),
        ),
        FancifulButton(
          label: 'Exchange',
          subtitle: exchangeSubtitle, // Pass subtitle
          icon: Icons.swap_horiz,
          color: Colors.orange,
          onPressed: () => _onButtonTap(context, 'Exchange', exchangeSubtitle),
        ),
        FancifulButton(
          label: 'Sell',
          subtitle: sellSubtitle, // Pass subtitle
          icon: Icons.sell,
          color: Colors.purple,
          onPressed: () => _onButtonTap(context, 'Sell', sellSubtitle),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------
// The Custom Button Widget
// -----------------------------------------------------------------
class FancifulButton extends StatelessWidget {
  // --- MODIFICATION 3: Add 'subtitle' to constructor ---
  const FancifulButton({
    super.key,
    required this.label,
    required this.subtitle, // Added this
    required this.icon,
    required this.onPressed,
    this.color = Colors.grey,
  });

  final String label;
  final String subtitle; // Added this
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

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
                style: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              // --- MODIFICATION 4: Add the Subtitle Text Widget ---
              const SizedBox(height: 4), // Add a little space
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.0, // Make it small
                  color: Colors.grey[600], // Make it light grey
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