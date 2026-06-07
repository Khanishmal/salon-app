import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecommendedServices extends StatelessWidget {
  const RecommendedServices({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recommended Services",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _getRecommendedServices().length,
              itemBuilder: (context, index) {
                final service = _getRecommendedServices()[index];
                return _ServiceCard(service: service);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getRecommendedServices() {
    return [
      {'name': 'Bridal Makeup', 'price': 'Rs. 15,000', 'duration': '3-4 hrs', 'icon': Icons.face_retouching_natural},
      {'name': 'Facial Spa', 'price': 'Rs. 3,500', 'duration': '1 hr', 'icon': Icons.spa},
      {'name': 'Hair Styling', 'price': 'Rs. 2,500', 'duration': '1.5 hrs', 'icon': Icons.content_cut},
      {'name': 'Nail Art', 'price': 'Rs. 1,500', 'duration': '45 min', 'icon': Icons.brush},
      {'name': 'Henna Design', 'price': 'Rs. 2,000', 'duration': '1 hr', 'icon': Icons.auto_awesome},
      {'name': 'Waxing', 'price': 'Rs. 800', 'duration': '30 min', 'icon': Icons.cleaning_services},
    ];
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2845C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(service['icon'], color: const Color(0xFFF2845C), size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            service['name'],
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            service['price'],
            style: GoogleFonts.poppins(
              color: const Color(0xFFF2845C),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          Text(
            service['duration'],
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}