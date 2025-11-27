import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// You might need to adjust the path to your DonateModel if you use it here,
// but for the calculations below, we just need to access the Firestore data directly.

class SustainabilityPage extends StatelessWidget {
  const SustainabilityPage({super.key});

  // Color scheme matching the Donate page
  static final Color _primaryColor = Colors.teal.shade700;
  static final Color _headerColor = Colors.teal.shade800;
  static final Color _accentColor = Colors.amber.shade700;
  static final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'en_GB', symbol: '£');

  // --- Core function to fetch and calculate data ---
  Future<Map<String, dynamic>> _fetchSustainabilityData(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('donations')
        .where('donorId', isEqualTo: userId)
        .get();

    int totalItemsShared = 0;
    double totalEstimatedValue = 0.0;
    double totalWasteDivertedKg = 0.0;

    for (var doc in querySnapshot.docs) {
      final data = doc.data();

      // 1. Total Items Shared (simply the count of documents)
      totalItemsShared++;

      // 2. Total Estimated Value (sum of 'price' field)
      final price = data['price'];
      if (price is num) {
        totalEstimatedValue += price.toDouble();
      }

      // 3. Total Waste Diverted (sum of 'kg' field)
      final kg = data['kg'];
      if (kg is num) {
        totalWasteDivertedKg += kg.toDouble();
      }
    }

    return {
      'totalItems': totalItemsShared,
      'totalValue': totalEstimatedValue,
      'totalKg': totalWasteDivertedKg,
    };
  }

  // --- Widget for displaying a single metric card ---
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                //color: color.shade800,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Sustainability Impact"),
          backgroundColor: _headerColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text("Please log in to see your impact."),
        ),
      );
    }

    final userId = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sustainability Impact"),
        backgroundColor: _headerColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchSustainabilityData(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          }

          final data = snapshot.data ?? {};
          final totalItems = data['totalItems'] as int? ?? 0;
          final totalValue = data['totalValue'] as double? ?? 0.0;
          final totalKg = data['totalKg'] as double? ?? 0.0;

          if (totalItems == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco_outlined, size: 60, color: _primaryColor),
                    const SizedBox(height: 16),
                    const Text(
                      "Start making an impact!",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Quicksand'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "You haven't shared any items yet. Every donation helps reduce waste and support your community.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Quicksand', color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Your Positive Impact",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Thank you for being a part of the sharing economy!",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 40, thickness: 2),

                // --- Grid of Metric Cards ---
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // 1. Total Items Shared
                    _buildMetricCard(
                      title: "Total Items Shared",
                      value: totalItems.toString(),
                      icon: Icons.redeem,
                      color: _primaryColor,
                    ),

                    // 2. Estimated Value Given
                    _buildMetricCard(
                      title: "Value Given to Community",
                      value: _currencyFormatter.format(totalValue),
                      icon: Icons.savings,
                      color: _accentColor,
                    ),

                    // 3. Waste Diverted
                    _buildMetricCard(
                      title: "Waste Diverted from Landfill",
                      value: "${totalKg.toStringAsFixed(1)} kg",
                      icon: Icons.recycling,
                      color: Colors.green.shade600,
                    ),

                    // Placeholder/Motivational Card
                    _buildMetricCard(
                      title: "Total CO₂ Saved",
                      value: "${(totalKg * 1.5).toStringAsFixed(1)} kg*", // Estimate based on average waste impact
                      icon: Icons.air,
                      color: Colors.blue.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // --- Notes Section ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metrics Explained:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '**Value Given:** Calculated from the estimated price you listed for each item. This represents the total savings for the recipient community.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '**Waste Diverted:** Calculated from the Estimated Kg value you provided. This is the amount of potential waste kept out of landfills.',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '*The CO₂ Saved metric is an **estimation** based on industry averages for waste reduction.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}