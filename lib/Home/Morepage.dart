import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../listings/Donate.dart';
import '../listings/LendPage.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  static const String _fontFamily = 'Mont';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isStudent = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        setState(() {
          _isStudent = false;
          _isLoading = false;
        });
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      final role = doc.data()?['roleEffective'] ?? 'nonStudent';

      setState(() {
        _isStudent = role.toString().toLowerCase() == 'student';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isStudent = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Options', style: TextStyle(fontFamily: _fontFamily)),
        backgroundColor: Colors.blueGrey[50],
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ButtonGrid(
        fontFamily: _fontFamily,
        isStudent: _isStudent,
      ),
    );
  }
}

// -----------------------------------------------------------------
// Button Grid
// -----------------------------------------------------------------
class ButtonGrid extends StatelessWidget {
  final String fontFamily;
  final bool isStudent;

  const ButtonGrid({
    super.key,
    required this.fontFamily,
    required this.isStudent,
  });

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Coming Soon", style: TextStyle(fontFamily: fontFamily)),
        content: Text(
          "This feature will be available soon.",
          style: TextStyle(fontFamily: fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(8),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        // ✅ Donate (everyone sees this)
        FancifulButton(
          label: 'Donate',
          subtitle: 'Donate an Item',
          icon: Icons.favorite,
          color: const Color(0xFF6366F1),
          fontFamily: fontFamily,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Donate(title: 'Donate')),
            );
          },
        ),

        // ✅ Student-only buttons (hidden for non-students)
        if (isStudent)
          FancifulButton(
            label: 'Request',
            subtitle: 'Request an Item',
            icon: Icons.outbox,
            color: Colors.green,
            fontFamily: fontFamily,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LendPage(title: 'Lend')),
              );
            },
          ),

        if (isStudent)
          FancifulButton(
            label: 'Borrow',
            subtitle: 'Borrow an Item',
            icon: Icons.move_to_inbox,
            color: Colors.blue,
            fontFamily: fontFamily,
            onPressed: () => _showComingSoon(context),
          ),

        if (isStudent)
          FancifulButton(
            label: 'Exchange',
            subtitle: 'Exchange an Item',
            icon: Icons.swap_horiz,
            color: Colors.orange,
            fontFamily: fontFamily,
            onPressed: () => _showComingSoon(context),
          ),

        if (isStudent)
          FancifulButton(
            label: 'Sell',
            subtitle: 'Sell an Item',
            icon: Icons.sell,
            color: Colors.purple,
            fontFamily: fontFamily,
            onPressed: () => _showComingSoon(context),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------
// Button Widget
// -----------------------------------------------------------------
class FancifulButton extends StatelessWidget {
  const FancifulButton({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    required this.fontFamily,
    required this.color,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final String fontFamily;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.8), width: 2),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: fontFamily,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
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
