import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('customerId', isEqualTo: user?.uid)
          .where('status', whereIn: ['Confirmed', 'Pending'])
          .snapshots(),
      builder: (context, snapshot) {
        int activeBookings = snapshot.hasData ? snapshot.data!.docs.length : 0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _StatCard(
                value: activeBookings.toString(),
                label: "Active Bookings",
                icon: Icons.calendar_month,
                color: const Color(0xFFF2845C),
              ),
              const SizedBox(width: 12),
              _StatCard(
                value: "1,250",
                label: "Loyalty Points",
                icon: Icons.stars_rounded,
                color: const Color(0xFF6C5CE7),
              ),
              const SizedBox(width: 12),
              _StatCard(
                value: "Gold",
                label: "Membership",
                icon: Icons.workspace_premium,
                color: const Color(0xFF00B894),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}