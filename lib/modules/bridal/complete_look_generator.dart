import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CompleteLookGenerator extends StatelessWidget {
  const CompleteLookGenerator({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F3460),
      appBar: AppBar(
        title: Text('Complete Look Generator', style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: const Color(0xFF16213E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'AI Consultation Matcher',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE94560),
                      ),
                      // FIXED: Replaced invalid parameter 'onTap' with required parameter 'onPressed'
                      onPressed: () {
                        // Generation initialization pipeline execution routine
                      },
                      child: const Text('Analyze Complex Profiles', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Output Parameters Matrix Layer',
              // FIXED: Replaced 'Colors.white90' with standard supported material opacity colors modifier
              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.90), fontSize: 14),
            )
          ],
        ),
      ),
    );
  }
}