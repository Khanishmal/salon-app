// lib/screens/main_dashboard.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

import 'signin_screen.dart';
import 'signup_screen.dart';
import 'help_screen.dart';
import 'customer/customer_dashboard.dart';
import 'vendor/vendor_screen.dart';

class GlowSalonDashboard extends StatefulWidget {
  const GlowSalonDashboard({super.key});

  @override
  State<GlowSalonDashboard> createState() => _GlowSalonDashboardState();
}

class _GlowSalonDashboardState extends State<GlowSalonDashboard> {
  // ===========================================================================
  // SLIDESHOW STATE
  // ===========================================================================
  
  late PageController _pageController;
  int _currentSlide = 0;
  Timer? _slideTimer;
  
  final List<String> _slideImages = [
    'assets/assets/hero-salon.jpg',
    'assets/assets/service-bridal.jpg',
    'assets/assets/hero-banner.jpg',
    'assets/assets/service-manipedi.jpg',
    'assets/assets/promo-bridal.jpg',
    'assets/assets/products-hero.jpg',
    'assets/assets/promo-summer.jpg',
  ];
  
  final List<String> _slideTitles = [
    'Luxury Beauty Services',
    'AI-Powered Makeup Try-On',
    'Premium Salon Experience',
    'Expert Services',
    'Bridal Makeup Studio',
    'Advanced Skincare',
    'Complete Beauty Solutions',
  ];
  
  final List<String> _slideSubtitles = [
    'Experience world-class beauty treatments',
    'Try virtual makeup in real-time',
    'Where elegance meets excellence',
    'Professional services & booking made easy',
    'Your dream wedding look starts here',
    'Science-backed skincare solutions',
    'Everything you need to glow',
  ];

  // ===========================================================================
  // SERVICES DATA
  // ===========================================================================
  
  final List<Map<String, dynamic>> _services = [
    {'icon': Icons.content_cut, 'title': 'Hair Styling', 'color': Color(0xFFE8D5B7)},
    {'icon': Icons.face_retouching_natural, 'title': 'Makeup', 'color': Color(0xFFF5D6D6)},
    {'icon': Icons.spa, 'title': 'Spa', 'color': Color(0xFFD4E9D6)},
    {'icon': Icons.bolt, 'title': 'Nails', 'color': Color(0xFFE8D5F5)},
    {'icon': Icons.auto_fix_high, 'title': 'Facials', 'color': Color(0xFFD6E8F5)},
  ];

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startSlideshow();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startSlideshow() {
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentSlide + 1) % _slideImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  void _navigateToSignIn(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  void _navigateToSignUp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  void _navigateToHelp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpScreen()),
    );
  }

  void _navigateToDashboard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CustomerDashboard()),
      );
    } else {
      _navigateToSignIn(context);
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // =========================================================================
            // GLASS NAVIGATION BAR
            // =========================================================================
            _buildGlassNavBar(),
            
            // =========================================================================
            // HERO SLIDESHOW SECTION
            // =========================================================================
            _buildHeroSlideshow(),
            
            // =========================================================================
            // SERVICES SECTION
            // =========================================================================
            _buildServicesSection(),
            
            // =========================================================================
            // FEATURES SECTION
            // =========================================================================
            _buildFeaturesSection(),
            
            // =========================================================================
            // CTA SECTION
            // =========================================================================
            _buildCTASection(),
            
            // =========================================================================
            // FOOTER
            // =========================================================================
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // GLASS NAV BAR
  // ===========================================================================

  Widget _buildGlassNavBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.06),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF2845C), Color(0xFFFFB88C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'GlowSalon',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              
              // Actions
              Row(
                children: [
                  // Help Button
                  IconButton(
                    onPressed: () => _navigateToHelp(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Sign In Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF2845C), Color(0xFFFFB88C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _navigateToSignIn(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HERO SLIDESHOW
  // ===========================================================================

  Widget _buildHeroSlideshow() {
    return Container(
      height: 560,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2845C).withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          // PageView for slideshow
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentSlide = index);
              },
              itemCount: _slideImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    Image.asset(
                      _slideImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: const Color(0xFF1A1A1A),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 80,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                    ),
                    
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    
                    // Content
                    Positioned(
                      bottom: 40,
                      left: 30,
                      right: 30,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInUp(
                            delay: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2845C).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFF2845C).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '✨ Featured',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFF2845C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeInUp(
                            delay: const Duration(milliseconds: 400),
                            child: Text(
                              _slideTitles[index],
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeInUp(
                            delay: const Duration(milliseconds: 600),
                            child: Text(
                              _slideSubtitles[index],
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeInUp(
                            delay: const Duration(milliseconds: 800),
                            child: Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _navigateToDashboard(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF2845C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Explore Now',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: () => _navigateToSignUp(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign Up',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Slide Indicators
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slideImages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentSlide == index ? 30 : 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentSlide == index
                        ? const Color(0xFFF2845C)
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          
          // Navigation Arrows
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  final prev = (_currentSlide - 1) % _slideImages.length;
                  _pageController.animateToPage(
                    prev < 0 ? _slideImages.length - 1 : prev,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  final next = (_currentSlide + 1) % _slideImages.length;
                  _pageController.animateToPage(
                    next,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SERVICES SECTION
  // ===========================================================================

  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Column(
        children: [
          FadeInUp(
            child: Column(
              children: [
                Text(
                  'Premium Services',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 50,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF2845C), Color(0xFFFFB88C)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Luxury beauty experiences crafted for you',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: _services.map((service) {
              return FadeInUp(
                delay: Duration(milliseconds: 100 * _services.indexOf(service)),
                child: _buildServiceCard(
                  service['icon'] as IconData,
                  service['title'] as String,
                  service['color'] as Color,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(IconData icon, String title, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FEATURES SECTION
  // ===========================================================================

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.auto_awesome,
        'title': 'AI-Powered',
        'desc': 'Smart recommendations for your beauty needs',
        'color': Color(0xFFF2845C),
      },
      {
        'icon': Icons.face_retouching_natural,
        'title': 'Virtual Try-On',
        'desc': 'Preview looks before you book',
        'color': Color(0xFF4CA6FF),
      },
      {
        'icon': Icons.calendar_today,
        'title': 'Easy Booking',
        'desc': 'Schedule appointments in seconds',
        'color': Color(0xFF4CAF50),
      },
      {
        'icon': Icons.verified,
        'title': 'Trusted Experts',
        'desc': 'Certified beauty professionals',
        'color': Color(0xFFFFB74D),
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.02),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          FadeInUp(
            child: Text(
              'Why Choose GlowSalon',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.1,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return FadeInUp(
                delay: Duration(milliseconds: 150 * index),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (feature['color'] as Color).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          feature['icon'] as IconData,
                          color: feature['color'] as Color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        feature['title'] as String,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['desc'] as String,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CTA SECTION
  // ===========================================================================

  Widget _buildCTASection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF2845C),
            const Color(0xFFFFB88C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2845C).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          FadeInUp(
            child: Text(
              'Ready to Transform?',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Join GlowSalon today and experience the future of beauty',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _navigateToSignUp(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFF2845C),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _navigateToSignIn(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FOOTER
  // ===========================================================================

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF2845C), Color(0xFFFFB88C)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'GlowSalon',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '© 2026 GlowSalon. All rights reserved.',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.3),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFooterLink('About'),
              _buildFooterDivider(),
              _buildFooterLink('Contact'),
              _buildFooterDivider(),
              _buildFooterLink('Privacy'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.4),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFooterDivider() {
    return Container(
      width: 1,
      height: 12,
      color: Colors.white.withOpacity(0.1),
    );
  }
}