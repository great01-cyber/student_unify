import 'package:flutter/material.dart';

// A simple, beautiful 2x2 grid of buttons: Donate, Lend, Borrow, Sell, Exchange, Info.
// Each button navigates to a new page.

class MarketplaceButtons extends StatelessWidget {
  const MarketplaceButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _GridButtonData('Donate', Icons.volunteer_activism, '/donate'),
      _GridButtonData('Lend', Icons.handshake, '/lend'),
      _GridButtonData('Borrow', Icons.download_rounded, '/borrow'),
      _GridButtonData('Sell', Icons.attach_money, '/sell'),
      _GridButtonData('Exchange', Icons.swap_horiz, '/exchange'),
      _GridButtonData('Info', Icons.info_outline, '/info'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: buttons.map((btn) => _buildButton(context, btn)).toList(),
    );
  }

  Widget _buildButton(BuildContext context, _GridButtonData btn) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 6,
        shadowColor: Colors.indigo.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(20),
      ),
      onPressed: () => Navigator.pushNamed(context, btn.route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(btn.icon, size: 40, color: Colors.indigo),
          const SizedBox(height: 12),
          Text(btn.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _GridButtonData {
  final String label;
  final IconData icon;
  final String route;

  const _GridButtonData(this.label, this.icon, this.route);
}
