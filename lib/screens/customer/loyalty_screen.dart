// lib/screens/customer_modules/loyalty_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Glow Rewards",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          int points = data['loyaltyPoints'] ?? 0;
          String status = data['memberStatus'] ?? 'Bronze';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildPointsCard(points, status),
                const SizedBox(height: 25),
                _buildBenefitsList(status),
                const SizedBox(height: 25),
                _buildRewardsGrid(),
                const SizedBox(height: 25),
                _buildPointsHistory(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPointsCard(int points, String status) {
    Color statusColor;
    switch (status) {
      case 'Gold':
        statusColor = const Color(0xFFFFD700);
        break;
      case 'Silver':
        statusColor = const Color(0xFFC0C0C0);
        break;
      default:
        statusColor = const Color(0xFFCD7F32); // Bronze
    }

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.stars_rounded, size: 60, color: Color(0xFFF2845C)),
          const SizedBox(height: 15),
          Text(
            points.toString(),
            style: GoogleFonts.poppins(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            "Loyalty Points",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              "$status Member",
              style: GoogleFonts.poppins(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList(String status) {
    List<Map<String, dynamic>> benefits = [
      {'icon': Icons.local_offer, 'text': '10% off on all services', 'available': true},
      {'icon': Icons.fastfood, 'text': 'Free welcome drink', 'available': true},
      {'icon': Icons.card_giftcard, 'text': 'Birthday special discount', 'available': true},
      {'icon': Icons.calendar_month, 'text': 'Priority booking', 'available': status != 'Bronze'},
      {'icon': Icons.star, 'text': 'Exclusive events access', 'available': status == 'Gold'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Benefits",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          ...benefits.map((benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  benefit['icon'],
                  color: benefit['available'] 
                      ? const Color(0xFFF2845C) 
                      : Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    benefit['text'],
                    style: GoogleFonts.poppins(
                      color: benefit['available'] 
                          ? Colors.black87 
                          : Colors.grey[400],
                    ),
                  ),
                ),
                if (!benefit['available'])
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Upgrade",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRewardsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Redeem Points",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.2,
          children: [
            _buildRewardCard("Free Facial", "500 pts"),
            _buildRewardCard("20% Off", "300 pts"),
            _buildRewardCard("Hair Treatment", "800 pts"),
            _buildRewardCard("Makeup Session", "1000 pts"),
          ],
        ),
      ],
    );
  }

  Widget _buildRewardCard(String title, String points) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            points,
            style: GoogleFonts.poppins(
              color: const Color(0xFFF2845C),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2845C),
              minimumSize: const Size(double.infinity, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text("Redeem", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Activity",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.green),
            ),
            title: const Text("Booking completed"),
            subtitle: Text("Hair styling • +50 pts", style: GoogleFonts.poppins(fontSize: 12)),
            trailing: Text("+50", style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove, color: Colors.red),
            ),
            title: const Text("Redeemed reward"),
            subtitle: Text("Free facial • -500 pts", style: GoogleFonts.poppins(fontSize: 12)),
            trailing: Text("-500", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}