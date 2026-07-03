// lib/screens/main_dashboard.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin_screen.dart'; 
import 'vendor/vendor_screen.dart'; 
import 'customer/ar_makeup_screen.dart';
import 'customer/customer_dashboard.dart';
import 'customer/product_shop.dart';
import 'customer/booking_calendar.dart';
import 'signup_screen.dart';
import 'help_screen.dart';
import 'customer/services_menu_screen.dart';

class GlowSalonDashboard extends StatelessWidget {
  const GlowSalonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: _buildGlassAppBar(context),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeroSection(context),      
            _buildServicesSection(context),         
            _buildPromoBanner(context),
            _buildFooterSection(context),
          ],
        ),
      ),
      floatingActionButton: _buildHelpButton(context),
    );
  }

  Widget _buildGlassAppBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AppBar(
          backgroundColor: Colors.white.withOpacity(0.65),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          title: const Text(
            "GlowSalon", 
            style: TextStyle(
              color: Color(0xFF1D1D1F), 
              fontWeight: FontWeight.bold, 
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _navigateToServices(context), 
              child: const Text("Services", style: TextStyle(color: Color(0xFF424245), fontWeight: FontWeight.w500)),
            ),
            TextButton(
              onPressed: () => _navigateToShop(context), 
              child: const Text("Shop", style: TextStyle(color: Color(0xFF424245), fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const SignInScreen())
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2845C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Sign In", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToServices(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ServicesMenuScreen(),
        ),
      );
    } else {
      _showSignInPrompt(context, 'Please sign in to view services');
    }
  }

  void _navigateToShop(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProductShopScreen(),
        ),
      );
    } else {
      _showSignInPrompt(context, 'Please sign in to shop');
    }
  }

  void _showSignInPrompt(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignInScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2845C),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      height: 650,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/hero-salon.jpg'), 
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.45),
              Colors.black.withOpacity(0.2),
              Colors.black.withOpacity(0.6),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const Text(
              "Discover Your\nPerfect Glow",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 44, 
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                height: 1.2,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Experience luxury beauty services with AI-powered recommendations.",
              textAlign: TextAlign.center, 
              style: TextStyle(
                fontSize: 16, 
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 180),
                    margin: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: () => _handleBookNow(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2845C),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFFF2845C).withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Book Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 180),
                    margin: const EdgeInsets.only(left: 8),
                    child: OutlinedButton(
                      onPressed: () => _handleExplore(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Explore Studio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleBookNow(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BookingCalendarScreen(),
        ),
      );
    } else {
      _showSignInPrompt(context, 'Please sign in to book an appointment');
    }
  }

  void _handleExplore(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CustomerDashboard(),
        ),
      );
    } else {
      _showSignInPrompt(context, 'Please sign in to explore');
    }
  }

  Widget _buildServicesSection(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Our Luxury Services", 
            style: TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 50,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFF2845C),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: services.map((s) => _buildServiceCard(context, s['icon'] as IconData, s['title'] as String)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, IconData icon, String title) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      shadowColor: Colors.black.withOpacity(0.04),
      elevation: 10,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            if (title == 'Makeup') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ArMakeupScreen()),
              );
            } else if (title == 'Spa' || title == 'Facials') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServicesMenuScreen(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingCalendarScreen(),
                ),
              );
            }
          } else {
            _showSignInPrompt(context, 'Please sign in to book $title');
          }
        },
        child: Container(
          width: 155,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF2F2F7), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDF0EC),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFFF2845C), size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title, 
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600, 
                  fontSize: 15,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFCAE82), Color(0xFFF2845C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2845C).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Ready to Glow?", 
            style: TextStyle(
              fontSize: 32, 
              color: Colors.white, 
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Book an appointment online or consult with our real-time AI advisor instantly.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => _handleBookNow(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, 
              foregroundColor: const Color(0xFFF2845C),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("Book Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(BuildContext context) {
    return Container(
      color: const Color(0xFF121214), 
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "GlowSalon", 
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Your premium luxury destination for automated beauty operations and personalized cosmetics.", 
                      style: TextStyle(color: const Color(0xFF8E8E93), fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              _footerColumn(context, "Quick Links", ["About Us", "Contact", "Become a Vendor"]),
            ],
          ),
          const SizedBox(height: 48),
          Container(width: double.infinity, height: 1, color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 24),
          const Text(
            "© 2026 GlowSalon. All rights reserved.", 
            style: TextStyle(color: Color(0xFF48484A), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _footerColumn(BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 16),
        ...items.map((item) => GestureDetector(
          onTap: () {
            if (item == "Become a Vendor") {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const SignUpScreen(),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              item, 
              style: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildHelpButton(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFF2845C),
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HelpScreen(),
          ),
        );
      }, 
      child: const Icon(Icons.help_outline_rounded, size: 28),
    );
  }
}