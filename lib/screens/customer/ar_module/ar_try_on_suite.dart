// lib/customer/ar_try_on_suite.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

import 'ar_makeup_screen.dart';
import 'ar_jewelry_screen.dart';
import 'ar_mehndi_screen.dart';
import 'ar_ai_analysis_screen.dart';
import 'photo_upload_screen.dart';

class ArTryOnSuiteScreen extends StatelessWidget {
  const ArTryOnSuiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0A14),
      appBar: AppBar(
        title: const Text('Virtual Try-On Suite'),
        backgroundColor: const Color(0xFF2D1B4E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Skin Analysis & AI Advisor Card
            FadeInDown(
              child: _buildFeatureCard(
                context,
                title: 'AI Skin Analysis',
                subtitle: 'Get personalized makeup recommendations',
                icon: Icons.analytics_outlined,
                color: const Color(0xFF6C2B7A),
                screen: const ArAiAnalysisScreen(),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildFeatureCard(
                    context,
                    title: 'Bridal Makeup',
                    icon: Icons.face_retouching_natural,
                    color: const Color(0xFF8B1A4A),
                    screen: const ArMakeupScreen(),
                  ),
                  _buildFeatureCard(
                    context,
                    title: 'Jewelry Try-On',
                    icon: Icons.diamond,
                    color: const Color(0xFF7A5A00),
                    screen: const ArJewelryScreen(),
                  ),
                  _buildFeatureCard(
                    context,
                    title: 'Mehndi Try-On',
                    icon: Icons.brush,
                    color: const Color(0xFF1A4A2A),
                    screen: const ArMehndiScreen(),
                  ),
                  _buildFeatureCard(
                    context,
                    title: 'Photo Upload',
                    icon: Icons.photo_camera,
                    color: const Color(0xFF2A4A6A),
                    screen: const PhotoUploadMakeupScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget screen,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Try Now →',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}