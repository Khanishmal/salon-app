//main_dashboard.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'signin_screen.dart'; 
import 'vendor/vendor_screen.dart'; 

class GlowSalonDashboard extends StatelessWidget {
  const GlowSalonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: _buildGlassAppBar(context),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),      
            _buildServicesSection(),         
            _buildPromoBanner(context),
            _buildFooterSection(context),
          ],
        ),
      ),
      // AI Advisor FAB matching the design in image_32e7fe.png
      floatingActionButton: _buildChatButton(context),
    );
  }

  // --- 1. GLASSMORPHIC APP BAR ---
// Update the _buildGlassAppBar method
Widget _buildGlassAppBar(BuildContext context) {
  return ClipRRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        title: const Text("GlowSalon", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          TextButton(onPressed: () {}, child: const Text("Services", style: TextStyle(color: Colors.black))),
          TextButton(onPressed: () {}, child: const Text("Shop", style: TextStyle(color: Colors.black))),
          
        
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const SignInScreen())
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2845C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Sign In", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    ),
  );
}

  // --- 2. HERO SECTION ---
  Widget _buildHeroSection(BuildContext context) {
    return Container(
      height: 600,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/hero-salon.jpg'), 
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.25), 
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Discover Your Perfect Glow",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
            const SizedBox(height: 20),
            const Text("Experience luxury beauty services with AI-powered recommendations.",
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2845C),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  ),
                  child: const Text("Book Appointment", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 15),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20)
                  ),
                  child: const Text("Explore Services", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. SERVICES GRID ---
  Widget _buildServicesSection() {
    final services = [
      {'icon': Icons.content_cut, 'title': 'Hair Styling'},
      {'icon': Icons.favorite_border, 'title': 'Makeup'},
      {'icon': Icons.bolt, 'title': 'Spa'},
      {'icon': Icons.auto_fix_high, 'title': 'Nails'},
      {'icon': Icons.face, 'title': 'Facials'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
      child: Column(
        children: [
          const Text("Our Services", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: services.map((s) => _buildServiceCard(s['icon'] as IconData, s['title'] as String)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(IconData icon, String title) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFDEEE9),
            child: Icon(icon, color: const Color(0xFFF2845C)),
          ),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  // --- 4. PROMO BANNER ---
  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(60),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFBC280), Color(0xFFF2845C)]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Text("Ready to Glow?", style: TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, 
              foregroundColor: const Color(0xFFF2845C),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text("Book Now", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- 5. FOOTER ---
  Widget _buildFooterSection(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("GlowSalon", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    Text("Your luxury destination for beauty.", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              _footerColumn(context, "Quick Links", ["About Us", "Contact", "Become a Vendor"]),
            ],
          ),
          const Divider(color: Colors.white10, height: 60),
          const Text("© 2026 GlowSalon. All rights reserved.", style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _footerColumn(BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        ...items.map((item) => GestureDetector(
          onTap: () {
            if (item == "Become a Vendor") {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const VendorScreen()));
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(item, style: const TextStyle(color: Colors.grey)),
          ),
        )),
      ],
    );
  }

  Widget _buildChatButton(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFF2845C),
      onPressed: () {
        // Here you would show the Beauty Advisor overlay from image_32e7fe.png
      }, 
      child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
    );
  }
}