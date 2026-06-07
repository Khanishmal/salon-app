import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiBridalRecommendations extends StatelessWidget {
  const AiBridalRecommendations({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(
          'AI Bridal Recommendations',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalized AI Looks',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              // AI Card containing the button triggers
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Discover the perfect color combinations tailored for your facial structure and tone.',
                      style: GoogleFonts.poppins(color: const Color(0xFFEEEEEE), fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE94560),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome, color: Colors.white),
                      label: Text(
                        'Generate Look',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      // FIXED: Changed from onTap to onPressed as required by the compiler diagnostic
                      onPressed: () {
                        // Action handling logic goes here
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // FIXED: Changed 'Colors.whiteefe' to a valid hex custom color definition
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Premium Recommendations updated dynamically via real-time image computer vision model metrics.',
                  style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}