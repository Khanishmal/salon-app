import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AIBeautyFAB extends StatelessWidget {
  const AIBeautyFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, '/ai-chat'),
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      icon: const Icon(Icons.auto_awesome, color: Color(0xFFF2845C)),
      label: Text(
        "AI Beauty Assistant",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}