import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MehndiTryOn extends StatelessWidget {
  const MehndiTryOn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bridal Mehndi Try-On', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF4A2C00),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Augmented Reality Forehead Mehndi Patterns',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E3A07)),
              // FIXED: Changed parameter key name from 'onTap' to 'onPressed' to comply with widget definition constraints
              onPressed: () {
                // Initialize custom local rendering stack configurations
              },
              child: Text('Activate Cam Stream', style: GoogleFonts.poppins(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}