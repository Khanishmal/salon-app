// lib/screens/customer/customer_dashboard.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// Core Navigation Screen Modules
import 'nearby_salons.dart';
import 'booking_calendar.dart';
import 'real_time_chat.dart';
// AR Feature Hub Modules 
import 'ar_try_on_suite.dart';
import 'ar_makeup_screen.dart';
import 'ai_advisor_screen.dart';
import 'product_shop.dart';
import 'loyalty_screen.dart';
import '../signin_screen.dart';
import 'inbox_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentTabIndex = 0;
  late final List<Widget> _navigationPages;

  @override
  void initState() {
    super.initState();
    _navigationPages = [
      const DashboardHomeView(),
      const NearbySalonsScreen(),
      const BookingCalendarScreen(),
      const InboxScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF9F9FB);
    final navBarColor = isDarkMode ? const Color(0xFF1E1E24) : Colors.white;
    final unselectedIconColor = isDarkMode ? const Color(0xFF7E7E8E) : const Color(0xFF9E9EAF);

    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentTabIndex != 0) {
          setState(() => _currentTabIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: IndexedStack(
          index: _currentTabIndex,
          children: _navigationPages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentTabIndex,
            onTap: (index) => setState(() => _currentTabIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: navBarColor,
            selectedItemColor: const Color(0xFFF2845C),
            unselectedItemColor: unselectedIconColor,
            selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400),
            items: const [
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.dashboard_customize_outlined, size: 22)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.dashboard_customize, size: 22)),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.map_outlined, size: 22)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.map, size: 22)),
                label: 'Nearby',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.calendar_month_outlined, size: 22)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.calendar_month, size: 22)),
                label: 'Bookings',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.forum_outlined, size: 22)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.forum, size: 22)),
                label: 'Inbox',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardHomeView extends StatelessWidget {
  const DashboardHomeView({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Confirm Logout", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to terminate your secure session?", style: GoogleFonts.poppins(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2845C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Logout", style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final cardBackgroundColor = isDarkMode ? const Color(0xFF1E1E24) : Colors.white;
    final textHeadingColor = isDarkMode ? Colors.white : const Color(0xFF1A1A24);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String clientName = "Ishmal"; 
        String memberStatus = "Gold";
        int loyaltyPoints = 1250;
        int activeBookings = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          clientName = userData['name'] ?? clientName;
          memberStatus = userData['memberStatus'] ?? memberStatus;
          loyaltyPoints = userData['loyaltyPoints'] ?? loyaltyPoints;
          activeBookings = userData['activeBookings'] ?? activeBookings;
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: false,
              pinned: true,
              backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF9F9FB),
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(10.0),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFF2845C).withOpacity(0.15),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFFF2845C), size: 16),
                ),
              ),
              title: Text(
                "GlowSalon",
                style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: textHeadingColor),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.notifications_none_rounded, color: textHeadingColor),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InboxScreen(),
                      ),
                    );
                  },
                ),
                Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  child: InkWell(
                    onTap: () => _handleSignOut(context),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFF2845C),
                      child: Text(
                        clientName.isNotEmpty ? clientName[0].toUpperCase() : "U",
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Hello, $clientName",
                                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text("👋", style: TextStyle(fontSize: 24)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Ready to glow today?",
                                  style: GoogleFonts.poppins(color: const Color(0xFF9E9EAF), fontSize: 14),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2845C).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.auto_awesome, color: Color(0xFFF2845C), size: 24),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.6,
                          children: [
                            _buildInnerHeroTile(
                              label: "Book Now",
                              icon: Icons.calendar_today_rounded,
                              color: const Color(0xFF3A2A25),
                              iconColor: const Color(0xFFF2845C),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingCalendarScreen())),
                            ),
                            _buildInnerHeroTile(
                              label: "AR Makeup",
                              icon: Icons.face_retouching_natural_rounded,
                              color: const Color(0xFF1A2A3A),
                              iconColor: const Color(0xFF4CA6FF),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArTryOnSuiteScreen())),
                            ),
                            _buildInnerHeroTile(
                              label: "Live AR",
                              icon: Icons.videocam_rounded,
                              color: const Color(0xFF351A2A),
                              iconColor: const Color(0xFFFF4C93),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArMakeupScreen())),
                            ),
                            _buildInnerHeroTile(
                              label: "Explore",
                              icon: Icons.explore_rounded,
                              color: const Color(0xFF251A35),
                              iconColor: const Color(0xFF9B4CFF),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NearbySalonsScreen())),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusMetricCard(
                          title: "Active Bookings",
                          value: "$activeBookings",
                          icon: Icons.bookmark_outline_rounded,
                          accentColor: Colors.orange,
                          cardColor: cardBackgroundColor,
                          isDark: isDarkMode,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusMetricCard(
                          title: "Loyalty Points",
                          value: loyaltyPoints.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                          icon: Icons.stars_rounded,
                          accentColor: const Color(0xFFF2845C),
                          cardColor: cardBackgroundColor,
                          isDark: isDarkMode,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoyaltyScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusMetricCard(
                          title: "Membership",
                          value: memberStatus,
                          icon: Icons.verified_user_rounded,
                          accentColor: Colors.teal,
                          cardColor: cardBackgroundColor,
                          isDark: isDarkMode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Text(
                    "Intelligent Simulation Suite",
                    style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: textHeadingColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Deploy precision mapping pipelines across modular variations",
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF7E7E8E)),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildPipelineHorizontalCard(
                          phase: "PHASE 1",
                          title: "Face & Chromatic Makeup Matrix",
                          subtitle: "Lipstick, Eye Shadow & Foundation parameters",
                          icon: Icons.face,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArMakeupScreen())),
                          isDark: isDarkMode,
                        ),
                        _buildPipelineHorizontalCard(
                          phase: "PHASE 2",
                          title: "Premium Bridal Look Architect",
                          subtitle: "Complete virtual styling customization engine",
                          icon: Icons.auto_awesome_motion,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArTryOnSuiteScreen())),
                          isDark: isDarkMode,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  Text(
                    "Exclusive AR Makeover Hub & Ecosystem Quick Actions",
                    style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: textHeadingColor),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [
                      _buildQuickActionCircle(
                        label: "Nearby",
                        icon: Icons.location_on_outlined,
                        color: const Color(0xFFFF8A65),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NearbySalonsScreen())),
                        isDark: isDarkMode,
                      ),
                      _buildQuickActionCircle(
                        label: "Book",
                        icon: Icons.edit_calendar_outlined,
                        color: const Color(0xFF5C6BC0),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingCalendarScreen())),
                        isDark: isDarkMode,
                      ),
                      _buildQuickActionCircle(
                        label: "Services",
                        icon: Icons.spa_outlined,
                        color: const Color(0xFF26A69A),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ServicesMenuScreen())),
                        isDark: isDarkMode,
                      ),
                      _buildQuickActionCircle(
                        label: "Shop",
                        icon: Icons.shopping_bag_outlined,
                        color: const Color(0xFFFFB74D),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductShopScreen())),
                        isDark: isDarkMode,
                      ),
                      _buildQuickActionCircle(
                        label: "AR Studio",
                        icon: Icons.camera_front_rounded,
                        color: const Color(0xFF29B6F6),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArTryOnSuiteScreen())),
                        isDark: isDarkMode,
                      ),
                      _buildQuickActionCircle(
                        label: "Orders",
                        icon: Icons.receipt_long,
                        color: const Color(0xFF4CAF50),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerOrdersScreen())),
                        isDark: isDarkMode,
                      ),
                      _buildQuickActionCircle(
                        label: "Loyalty",
                        icon: Icons.card_giftcard_rounded,
                        color: const Color(0xFFEC407A),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoyaltyScreen())),
                        isDark: isDarkMode,
                      ),
                      _buildQuickActionCircle(
                        label: "Profile",
                        icon: Icons.person_outline,
                        color: const Color(0xFF9C27B0),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerProfileScreen())),
                        isDark: isDarkMode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Upcoming Appointments",
                        style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: textHeadingColor),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingCalendarScreen())),
                        child: Text("View All", style: GoogleFonts.spaceGrotesk(color: const Color(0xFFF2845C), fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  _buildEmptyStateAppointmentBlock(cardBackgroundColor, context),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInnerHeroTile({
    required String label,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color cardColor,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: accentColor.withOpacity(0.12),
              child: Icon(icon, color: accentColor, size: 16),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A24)),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF7E7E8E), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineHorizontalCard({
    required String phase,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 14, bottom: 4, top: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.04), blurRadius: 8, offset: const Offset(0, 3))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF2845C).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFFF2845C), size: 22),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(phase, style: GoogleFonts.spaceGrotesk(fontSize: 9, color: const Color(0xFFF2845C), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A24))),
            ],
          ),
          subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF7E7E8E))),
        ),
      ),
    );
  }

  Widget _buildQuickActionCircle({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF333345)),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyStateAppointmentBlock(Color cardColor, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined, size: 40, color: const Color(0xFF7E7E8E).withOpacity(0.5)),
          const SizedBox(height: 16),
          Text("No upcoming appointments", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF7E7E8E))),
          const SizedBox(height: 4),
          Text("Book your first appointment today!", style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9E9EAF))),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingCalendarScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2845C),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text("Book Now", style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// FALLBACK CLASSES - Replace with actual implementations
// =========================================================================
class ServicesMenuScreen extends StatelessWidget {
  const ServicesMenuScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Services Menu Screen")));
}