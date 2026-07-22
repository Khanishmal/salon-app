import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';

// Core Navigation Screen Modules
import 'nearby_salons.dart';
import 'booking_calendar.dart';
import 'real_time_chat.dart';
import 'ar_module/ar_makeup_screen.dart.md';
import 'ar_module/ar_ai_analysis_screen.dart';
import 'product_shop.dart';
import 'loyalty_screen.dart';
import '../signin_screen.dart';
import 'inbox_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'services_menu_screen.dart';
import 'ar_module/virtual_makeup_screen.dart';
import 'ar_module/ar_try_on_suite.dart';
import 'ar_module/photo_makeup_tryon_screen.dart';

// Theme Provider for dark mode toggle
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

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
    _navigationPages = const [
      DashboardHomeView(),
      ServicesMenuScreen(),
      ProductShopScreen(),
      InboxScreen(),
      CustomerProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5FA);
    final navBarColor = isDarkMode ? const Color(0xFF12121A) : Colors.white;

    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final currentIsDark = themeProvider.isDarkMode;
          
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (_currentTabIndex != 0) {
                setState(() => _currentTabIndex = 0);
              } else {
                _showLogoutConfirmation(context);
              }
            },
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: currentIsDark ? ThemeData.dark() : ThemeData.light(),
              home: Scaffold(
                backgroundColor: currentIsDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5FA),
                body: IndexedStack(
                  index: _currentTabIndex,
                  children: _navigationPages,
                ),
                bottomNavigationBar: Container(
                  decoration: BoxDecoration(
                    color: currentIsDark ? const Color(0xFF12121A) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(currentIsDark ? 0.4 : 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      )
                    ],
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _currentTabIndex,
                    onTap: (index) {
                      if (index < _navigationPages.length) {
                        setState(() => _currentTabIndex = index);
                      }
                    },
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: Colors.transparent,
                    selectedItemColor: const Color(0xFFE28766),
                    unselectedItemColor: currentIsDark ? Colors.grey[600] : Colors.grey[400],
                    selectedLabelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w400),
                    elevation: 0,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined, size: 24),
                        activeIcon: Icon(Icons.home, size: 24),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.spa_outlined, size: 24),
                        activeIcon: Icon(Icons.spa, size: 24),
                        label: 'Services',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.shopping_bag_outlined, size: 24),
                        activeIcon: Icon(Icons.shopping_bag, size: 24),
                        label: 'Shop',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.forum_outlined, size: 24),
                        activeIcon: Icon(Icons.forum, size: 24),
                        label: 'Inbox',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline, size: 24),
                        activeIcon: Icon(Icons.person, size: 24),
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Logout", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text("Are you sure you want to logout?", style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SignInScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE28766),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text("Logout", style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// --- DASHBOARD HOME VIEW ---
class DashboardHomeView extends StatelessWidget {
  const DashboardHomeView({super.key});

  void _showSideMenu(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF12121A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1A2E);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    title: "Dashboard",
                    onTap: () { Navigator.pop(context); },
                    isDark: isDarkMode,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.spa_rounded,
                    title: "Services",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ServicesMenuScreen()));
                    },
                    isDark: isDarkMode,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.shopping_bag_rounded,
                    title: "Shop",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductShopScreen()));
                    },
                    isDark: isDarkMode,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.calendar_today_rounded,
                    title: "Bookings",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingCalendarScreen()));
                    },
                    isDark: isDarkMode,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.face_retouching_natural_rounded,
                    title: "AR Studio",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ArTryOnSuiteScreen()));
                    },
                    isDark: isDarkMode,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.location_on_rounded,
                    title: "Nearby Salons",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NearbySalonsScreen()));
                    },
                    isDark: isDarkMode,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.card_giftcard_rounded,
                    title: "Loyalty",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoyaltyScreen()));
                    },
                    isDark: isDarkMode,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long_rounded,
                    title: "Orders",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerOrdersScreen()));
                    },
                    isDark: isDarkMode,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.forum_rounded,
                    title: "Inbox",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const InboxScreen()));
                    },
                    isDark: isDarkMode,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_rounded,
                    title: "Profile",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerProfileScreen()));
                    },
                    isDark: isDarkMode,
                  ),
                  const SizedBox(height: 20),
                  Divider(color: isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout_rounded,
                    title: "Logout",
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutConfirmation(context);
                    },
                    isDark: isDarkMode,
                    isLogout: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLogout ? Colors.red.withOpacity(0.1) : const Color(0xFFE28766).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isLogout ? Colors.red : const Color(0xFFE28766),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Logout", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text("Are you sure you want to logout?", style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SignInScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE28766),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text("Logout", style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDarkMode ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5FA);
    final cardColor = isDarkMode ? const Color(0xFF16161E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    // Bookings from service_bookings (appointments)
    final bookingsStream = FirebaseFirestore.instance
        .collection('service_bookings')
        .where('customerId', isEqualTo: user?.uid)
        .where('status', whereIn: ['pending', 'confirmed'])
        .snapshots();

    // Orders from orders collection (product purchases)
    final ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: user?.uid)
        .where('orderStatus', whereIn: ['placed', 'processing', 'shipped'])
        .snapshots();

    // Loyalty points stream
    final loyaltyStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .snapshots();

    // Notifications stream - FIXED: Removed to hide the dot
    // We'll use a static value instead

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String clientName = "Guest";
        String memberStatus = "Member";
        int loyaltyPoints = 0;
        int activeBookings = 0;
        String profileImage = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          clientName = userData['name'] ?? clientName;
          memberStatus = userData['memberStatus'] ?? memberStatus;
          loyaltyPoints = userData['loyaltyPoints'] ?? 0;
          activeBookings = userData['activeBookings'] ?? 0;
          profileImage = userData['profileImage'] ?? '';
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // --- Premium App Bar ---
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu_rounded, size: 22),
                  color: textColor,
                  onPressed: () => _showSideMenu(context),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: const DecorationImage(
                        image: AssetImage('assets/salon-1.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "GlowSalon",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                // Theme Toggle Button
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 22,
                    ),
                    color: textColor,
                    onPressed: () {
                      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                      themeProvider.toggleTheme();
                    },
                  ),
                ),
                // Notifications - REMOVED DOT
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 22),
                    color: textColor,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InboxScreen()),
                      );
                    },
                  ),
                ),
                // Profile Avatar
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CustomerProfileScreen()),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE28766), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFE28766).withOpacity(0.1),
                      child: profileImage.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                profileImage,
                                fit: BoxFit.cover,
                                width: 36,
                                height: 36,
                                errorBuilder: (context, error, stackTrace) => Text(
                                  clientName.isNotEmpty ? clientName[0].toUpperCase() : "G",
                                  style: GoogleFonts.spaceGrotesk(
                                    color: const Color(0xFFE28766),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              clientName.isNotEmpty ? clientName[0].toUpperCase() : "G",
                              style: GoogleFonts.spaceGrotesk(
                                color: const Color(0xFFE28766),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  // --- Welcome Section ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFE28766),
                          const Color(0xFFD4785A),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE28766).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Good ${_getTimeOfDay()}!",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    clientName,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star_rounded,
                                              color: Colors.amber[300],
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              memberStatus,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: StreamBuilder<DocumentSnapshot>(
                                          stream: loyaltyStream,
                                          builder: (context, snapshot) {
                                            int points = 0;
                                            if (snapshot.hasData && snapshot.data!.exists) {
                                              final data = snapshot.data!.data() as Map<String, dynamic>;
                                              points = data['loyaltyPoints'] ?? 0;
                                            }
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.card_giftcard_rounded,
                                                  color: Colors.white.withOpacity(0.8),
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "$points pts",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Quick Action Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                icon: Icons.calendar_today_rounded,
                                label: "Book Now",
                                color: Colors.white,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingCalendarScreen())),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                icon: Icons.face_retouching_natural_rounded,
                                label: "AR Try-On",
                                color: Colors.white,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArTryOnSuiteScreen())),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                icon: Icons.location_on_rounded,
                                label: "Nearby",
                                color: Colors.white,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NearbySalonsScreen())),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Stats Cards ---
                  StreamBuilder<QuerySnapshot>(
                    stream: bookingsStream,
                    builder: (context, bookingSnapshot) {
                      int bookingCount = 0;
                      if (bookingSnapshot.hasData) {
                        bookingCount = bookingSnapshot.data!.docs.length;
                      }

                      return StreamBuilder<QuerySnapshot>(
                        stream: ordersStream,
                        builder: (context, orderSnapshot) {
                          int orderCount = 0;
                          if (orderSnapshot.hasData) {
                            orderCount = orderSnapshot.data!.docs.length;
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: "Bookings",
                                  value: bookingCount.toString(),
                                  icon: Icons.bookmark_rounded,
                                  color: const Color(0xFF4A90D9),
                                  cardColor: cardColor,
                                  isDark: isDarkMode,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingCalendarScreen())),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  title: "Orders",
                                  value: orderCount.toString(),
                                  icon: Icons.shopping_bag_rounded,
                                  color: const Color(0xFFE28766),
                                  cardColor: cardColor,
                                  isDark: isDarkMode,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerOrdersScreen())),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StreamBuilder<DocumentSnapshot>(
                                  stream: loyaltyStream,
                                  builder: (context, loyaltySnapshot) {
                                    int points = 0;
                                    if (loyaltySnapshot.hasData && loyaltySnapshot.data!.exists) {
                                      final data = loyaltySnapshot.data!.data() as Map<String, dynamic>;
                                      points = data['loyaltyPoints'] ?? 0;
                                    }
                                    return _buildStatCard(
                                      title: "Points",
                                      value: points.toString(),
                                      icon: Icons.stars_rounded,
                                      color: const Color(0xFF34C759),
                                      cardColor: cardColor,
                                      isDark: isDarkMode,
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoyaltyScreen())),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // --- Services Section ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Popular Services",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ServicesMenuScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "See All",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFE28766),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Services Horizontal List
                  SizedBox(
                    height: 160,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('services')
                          .where('isActive', isEqualTo: true)
                          .limit(5)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildShimmerEffect();
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.spa_outlined,
                                    size: 40,
                                    color: subtitleColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "No services available",
                                    style: GoogleFonts.poppins(
                                      color: subtitleColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            var doc = snapshot.data!.docs[index];
                            var data = doc.data() as Map<String, dynamic>;
                            return _buildServiceCard(data, cardColor, isDarkMode, context);
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --- AR Studio Section ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "AR Studio",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ArTryOnSuiteScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Explore",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFE28766),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // FIXED: Virtual Makeup Card with Photo Upload and Selfie Mode
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Photo Upload Card
                        _buildARCard(
                          title: "Photo Upload",
                          subtitle: "Upload photo for makeup try-on",
                          icon: Icons.photo_library_rounded,
                          color: const Color(0xFFFF6B6B),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PhotoMakeupTryonScreen(),
                              ),
                            );
                          },
                          isDark: isDarkMode,
                        ),
                        // Selfie Mode Card
                        _buildARCard(
                          title: "Selfie Mode",
                          subtitle: "Real-time virtual makeup",
                          icon: Icons.camera_alt_rounded,
                          color: const Color(0xFF4ECDC4),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VirtualMakeupScreen(),
                              ),
                            );
                          },
                          isDark: isDarkMode,
                        ),
                        // AR Try-On Suite
                        _buildARCard(
                          title: "AR Try-On Suite",
                          subtitle: "Complete virtual styling",
                          icon: Icons.auto_awesome_motion_rounded,
                          color: const Color(0xFFA78BFA),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ArTryOnSuiteScreen(),
                              ),
                            );
                          },
                          isDark: isDarkMode,
                        ),
                        // AI Analysis
                        _buildARCard(
                          title: "AI Analysis",
                          subtitle: "Smart skin & face analysis",
                          icon: Icons.analytics_rounded,
                          color: const Color(0xFF4A90D9),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ArAiAnalysisScreen(),
                              ),
                            );
                          },
                          isDark: isDarkMode,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --- Quick Actions Grid ---
                  Text(
                    "Quick Actions",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: [
                      _buildQuickActionCircle(
                        label: "Book",
                        icon: Icons.edit_calendar_rounded,
                        color: const Color(0xFFE28766),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingCalendarScreen())),
                        isDark: isDarkMode,
                      ),
                      _buildQuickActionCircle(
                        label: "Services",
                        icon: Icons.spa_rounded,
                        color: const Color(0xFF4A90D9),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ServicesMenuScreen())),
                        isDark: isDarkMode,
                      ),
                      _buildQuickActionCircle(
                        label: "Shop",
                        icon: Icons.shopping_bag_rounded,
                        color: const Color(0xFF34C759),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductShopScreen())),
                        isDark: isDarkMode,
                      ),
                      _buildQuickActionCircle(
                        label: "Orders",
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFFFF9500),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerOrdersScreen())),
                        isDark: isDarkMode,
                      ),
                      _buildQuickActionCircle(
                        label: "Loyalty",
                        icon: Icons.card_giftcard_rounded,
                        color: const Color(0xFFAF52DE),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoyaltyScreen())),
                        isDark: isDarkMode,
                      ),
                      _buildQuickActionCircle(
                        label: "Inbox",
                        icon: Icons.forum_rounded,
                        color: const Color(0xFF5AC8FA),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InboxScreen())),
                        isDark: isDarkMode,
                      ),
                      _buildQuickActionCircle(
                        label: "Nearby",
                        icon: Icons.location_on_rounded,
                        color: const Color(0xFFFF6B6B),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NearbySalonsScreen())),
                        isDark: isDarkMode,
                      ),
                      _buildQuickActionCircle(
                        label: "Profile",
                        icon: Icons.person_rounded,
                        color: const Color(0xFFA78BFA),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerProfileScreen())),
                        isDark: isDarkMode,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // --- Upcoming Appointments ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Upcoming Appointments",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingCalendarScreen())),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "View All",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFE28766),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // FIXED: No orderBy to avoid index requirement
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('service_bookings')
                        .where('customerId', isEqualTo: user?.uid)
                        .where('status', whereIn: ['pending', 'confirmed'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildShimmerCard();
                      }

                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
                          ),
                          child: Center(
                            child: Text(
                              "Error loading bookings",
                              style: GoogleFonts.poppins(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyAppointmentCard(cardColor, context);
                      }

                      // Sort locally
                      var bookings = snapshot.data!.docs.toList();
                      bookings.sort((a, b) {
                        var dateA = (a.data() as Map<String, dynamic>)['bookingDate'] as Timestamp?;
                        var dateB = (b.data() as Map<String, dynamic>)['bookingDate'] as Timestamp?;
                        if (dateA == null && dateB == null) return 0;
                        if (dateA == null) return 1;
                        if (dateB == null) return -1;
                        return dateA.toDate().compareTo(dateB.toDate());
                      });
                      bookings = bookings.take(3).toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          var doc = bookings[index];
                          var data = doc.data() as Map<String, dynamic>;
                          return _buildAppointmentCard(data, cardColor, isDarkMode);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Helper Methods ---

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> data, Color cardColor, bool isDark, BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                  ? (data['imageUrl'].toString().startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: data['imageUrl'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, size: 30),
                          ),
                        )
                      : Image.asset(
                          data['imageUrl'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, size: 30),
                          ),
                        )
                    )
                  : Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: const Icon(Icons.spa, size: 30),
                    ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    data['name'] ?? 'Service',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs.${data['price'] ?? 0}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE28766),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE28766).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${data['duration'] ?? 0}m',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            color: const Color(0xFFE28766),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 150,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            Container(
              height: 20,
              width: double.infinity,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 100,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildARCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAppointmentCard(Color cardColor, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 36,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            "No upcoming appointments",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Book your first appointment today!",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingCalendarScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE28766),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              "Book Now",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> data, Color cardColor, bool isDark) {
    final status = data['status'] ?? 'pending';
    final statusColor = status == 'pending' ? Colors.orange : Colors.blue;
    final date = data['bookingDate'] as Timestamp?;
    final dateTime = date?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE28766).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.spa,
              color: Color(0xFFE28766),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['serviceName'] ?? 'Service',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateTime != null ? _formatDate(dateTime) : 'No date',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}