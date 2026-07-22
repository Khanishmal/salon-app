// lib/screens/salon_owner_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'signin_screen.dart';
import 'salon_owner/salon_services_screen.dart';
import 'salon_owner/salon_bookings_screen.dart';

class SalonOwnerScreen extends StatefulWidget {
  const SalonOwnerScreen({super.key});

  @override
  State<SalonOwnerScreen> createState() => _SalonOwnerScreenState();
}

class _SalonOwnerScreenState extends State<SalonOwnerScreen> {
  int _activeTab = 0;
  bool _isDarkMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Controllers for messaging and announcements
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _announcementTitleController = TextEditingController();

  // Track selected active customer/user for 1-on-1 live chat support
  Map<String, dynamic>? _selectedChatUser;
  String _broadcastTarget = 'All';

  // Cache messages to prevent flickering
  List<QueryDocumentSnapshot> _cachedMessages = [];
  String? _currentAdminId;

  // Search for users in chat list
  String _userSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentAdminId = FirebaseAuth.instance.currentUser?.uid;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _announcementController.dispose();
    _announcementTitleController.dispose();
    super.dispose();
  }

  // Define Design Theme Colors Dynamically
  Color get _bgColor => _isDarkMode ? const Color(0xFF0D0D0D) : const Color(0xFFFAF9F6);
  Color get _cardColor => _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _primaryTextColor => _isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
  Color get _secondaryTextColor => _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _borderColor => _isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFEAE6DF);
  Color get _accentColor => const Color(0xFFE28766);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 800;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_activeTab != 0) {
              setState(() {
                _activeTab = 0;
                _selectedChatUser = null;
                _cachedMessages = [];
              });
            } else {
              _showLogoutConfirmation();
            }
          },
          child: Scaffold(
            backgroundColor: _bgColor,
            drawer: isMobile
                ? Drawer(
                    backgroundColor: const Color(0xFF141414),
                    child: _buildAdminSidebar(isMobile: true),
                  )
                : null,
            body: SafeArea(
              child: Row(
                children: [
                  if (!isMobile) _buildAdminSidebar(isMobile: false),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTopBar(showMenuButton: isMobile),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Container(
                              key: ValueKey<int>(_activeTab + (_isDarkMode ? 100 : 0)),
                              child: _buildTabContent(isMobile: isMobile),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- ADMIN PLATFORM NAVIGATION SIDEBAR ---
  Widget _buildAdminSidebar({required bool isMobile}) {
    return Container(
      width: 280,
      color: const Color(0xFF141414),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: AssetImage('assets/salon-1.jpg'),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: _accentColor.withOpacity(0.3)),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "GLOW",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "SALON",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _adminNavItem(0, Icons.dashboard_customize_rounded, "Dashboard", isMobile),
                _adminNavItem(1, Icons.people_alt_rounded, "User Management", isMobile),
                _adminNavItem(2, Icons.storefront_rounded, "Vendors", isMobile),
                _adminNavItem(3, Icons.face_retouching_natural_rounded, "Clients", isMobile),
                _adminNavItem(4, Icons.verified_user_rounded, "Pending Requests", isMobile),
                _adminNavItem(5, Icons.chat_bubble_outline_rounded, "Live Messages", isMobile),
                _adminNavItem(6, Icons.campaign_rounded, "Announcements", isMobile),
                _adminNavItem(7, Icons.spa, "Services", isMobile),
                _adminNavItem(10, Icons.calendar_today_rounded, "Bookings", isMobile),
                _adminNavItem(8, Icons.settings, "Settings", isMobile),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF262626))),
            ),
            child: _adminNavItem(9, Icons.logout_rounded, "Log Out", isMobile, isLogout: true),
          ),
        ],
      ),
    );
  }

  Widget _adminNavItem(int index, IconData icon, String label, bool isMobile, {bool isLogout = false}) {
    bool selected = _activeTab == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF262626) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: isLogout
            ? _showLogoutConfirmation
            : () {
                setState(() {
                  _activeTab = index;
                  if (index != 5) {
                    _selectedChatUser = null;
                    _cachedMessages = [];
                  }
                });
                if (isMobile) Navigator.pop(context);
              },
        dense: true,
        leading: Icon(icon, color: selected ? _accentColor : Colors.grey[500], size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[400],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // --- MODERN DYNAMIC HEADER TOP BAR ---
  // In salon_owner_screen.dart, replace the _buildTopBar method:

Widget _buildTopBar({required bool showMenuButton}) {
  return Container(
    height: 70,
    decoration: BoxDecoration(
      color: _cardColor,
      border: Border(bottom: BorderSide(color: _borderColor)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        if (showMenuButton) ...[
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu_rounded, color: _primaryTextColor),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: const DecorationImage(
              image: AssetImage('assets/salon-1.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          "GlowSalon",
          style: TextStyle(
            color: _primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        // REMOVED: The search bar
        IconButton(
          onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          icon: Icon(
            _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: _primaryTextColor,
            size: 22,
          ),
        ),
        _buildTopBarBadge(
          stream: FirebaseFirestore.instance.collection('pending_approvals').where('status', isEqualTo: 'pending').snapshots(),
          icon: Icons.notifications_none_rounded,
          tabIndex: 4,
        ),
      ],
    ),
  );
}

  Widget _buildTopBarBadge({required Stream<QuerySnapshot> stream, required IconData icon, required int tabIndex}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return GestureDetector(
          onTap: () => setState(() => _activeTab = tabIndex),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(icon, color: _primaryTextColor, size: 24),
              ),
              if (count > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withOpacity(0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  // --- CORE VIEW ROUTER ---
  Widget _buildTabContent({required bool isMobile}) {
    switch (_activeTab) {
      case 0: return _buildDashboardOverview(isMobile: isMobile);
      case 1: return _buildUserManagement('All', isMobile: isMobile, title: 'User Management');
      case 2: return _buildUserManagement('Vendor', isMobile: isMobile, title: 'Vendors');
      case 3: return _buildUserManagement('Customer', isMobile: isMobile, title: 'Clients');
      case 4: return _buildPendingApprovals(isMobile: isMobile);
      case 5: return _buildLiveMessagingCenter(isMobile: isMobile);
      case 6: return _buildAnnouncementsHub(isMobile: isMobile);
      case 7: return const SalonServicesScreen();
      case 8: return _buildSalonSettings(isMobile: isMobile);
      case 10: return const SalonBookingsScreen();
      default: return _buildDashboardOverview(isMobile: isMobile);
    }
  }

  // --- 1. PREMIUM DASHBOARD OVERVIEW SCREEN ---
  Widget _buildDashboardOverview({required bool isMobile}) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      color: _accentColor,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: _isDarkMode
                ? [
                    const Color(0xFF0D0D0D),
                    const Color(0xFF1A0A0A),
                  ]
                : [
                    const Color(0xFFFAF9F6),
                    const Color(0xFFFFF5F0),
                  ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: AssetImage('assets/salon-1.jpg'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        "GlowSalon",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Premium Beauty & Wellness",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            const Shadow(
                              blurRadius: 10,
                              color: Colors.black,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getTodayDate(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Dashboard Overview",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _primaryTextColor,
                ),
              ),
              Text(
                "Real-time business metrics and insights",
                style: TextStyle(color: _secondaryTextColor, fontSize: 13),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: isMobile ? 2 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isMobile ? 1.4 : 1.6,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', whereIn: ['Customer', 'Vendor'])
                        .snapshots(),
                    builder: (context, snap) {
                      int count = 0;
                      if (snap.hasData) {
                        final adminId = FirebaseAuth.instance.currentUser?.uid;
                        count = snap.data!.docs.where((doc) => doc.id != adminId).length;
                      }
                      return _analyticsCard(
                        "Total Users",
                        count.toString(),
                        Icons.people,
                        const Color(0xFF4A90D9),
                        () => setState(() => _activeTab = 1),
                      );
                    },
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Vendor').snapshots(),
                    builder: (context, snap) => _analyticsCard(
                      "Vendors",
                      snap.hasData ? snap.data!.docs.length.toString() : "0",
                      Icons.storefront_rounded,
                      const Color(0xFF34C759),
                      () => setState(() => _activeTab = 2),
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Customer').snapshots(),
                    builder: (context, snap) => _analyticsCard(
                      "Clients",
                      snap.hasData ? snap.data!.docs.length.toString() : "0",
                      Icons.face_retouching_natural_rounded,
                      const Color(0xFFAF52DE),
                      () => setState(() => _activeTab = 3),
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('service_bookings').snapshots(),
                    builder: (context, snap) => _analyticsCard(
                      "Total Bookings",
                      snap.hasData ? snap.data!.docs.length.toString() : "0",
                      Icons.calendar_today_rounded,
                      _accentColor,
                      () => setState(() => _activeTab = 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('service_bookings').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final bookings = snapshot.data!.docs;
                  final pending = bookings.where((b) => (b.data() as Map<String, dynamic>)['status'] == 'pending').length;
                  final confirmed = bookings.where((b) => (b.data() as Map<String, dynamic>)['status'] == 'confirmed').length;
                  final completed = bookings.where((b) => (b.data() as Map<String, dynamic>)['status'] == 'completed').length;

                  return Row(
                    children: [
                      Expanded(
                        child: _bookingStatCard(
                          "Pending",
                          pending.toString(),
                          Colors.orange,
                          Icons.pending_actions,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _bookingStatCard(
                          "Confirmed",
                          confirmed.toString(),
                          Colors.blue,
                          Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _bookingStatCard(
                          "Completed",
                          completed.toString(),
                          Colors.green,
                          Icons.done_all,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                "Recent Activity",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryTextColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildRealtimeRecentActivityList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookingStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryTextColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: _secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getTodayDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Widget _analyticsCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _primaryTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: _secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- 2. COMPLETE USER PROFILE DIRECTORY MANAGEMENT WITH TITLE ---
 Widget _buildUserManagement(String filter, {required bool isMobile, required String title}) {
  final String? adminId = FirebaseAuth.instance.currentUser?.uid;

  Query query = FirebaseFirestore.instance.collection('users');

  if (filter == 'All') {
    query = query.where('role', whereIn: ['Customer', 'Vendor']);
  } else if (filter == 'Vendor') {
    query = query.where('role', isEqualTo: 'Vendor');
  } else if (filter == 'Customer') {
    query = query.where('role', isEqualTo: 'Customer');
  }

  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: _isDarkMode
            ? [
                const Color(0xFF0D0D0D),
                const Color(0xFF1A0A0A),
              ]
            : [
                const Color(0xFFFAF9F6),
                const Color(0xFFFFF5F0),
              ],
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage all ${title.toLowerCase()} in your system',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          // Search Bar
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF222222) : const Color(0xFFF0EFFB),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                width: 0.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 14, color: _primaryTextColor),
              decoration: InputDecoration(
                hintText: "Search ${title.toLowerCase()}...",
                hintStyle: TextStyle(color: _secondaryTextColor, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: _accentColor, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: _secondaryTextColor, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
                        const SizedBox(height: 12),
                        Text(
                          "Error loading users",
                          style: TextStyle(color: _secondaryTextColor),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs.where((doc) => doc.id != adminId).toList();

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    var data = d.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final email = (data['email'] ?? '').toString().toLowerCase();
                    final businessName = (data['businessName'] ?? '').toString().toLowerCase();
                    final phone = (data['phone'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) ||
                        email.contains(_searchQuery) ||
                        businessName.contains(_searchQuery) ||
                        phone.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 50, color: _secondaryTextColor.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty ? "No users found matching your search" : "No users found",
                          style: TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search terms',
                            style: TextStyle(
                              color: _secondaryTextColor.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(4),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    bool isActive = data['isActive'] ?? true;
                    String role = data['role'] ?? 'User';
                    String name = data['name'] ?? 'No Registered Name';
                    String email = data['email'] ?? '';
                    String businessName = data['businessName'] ?? '';

                    return Card(
                      color: _cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: _borderColor.withOpacity(0.3)),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: _accentColor.withOpacity(0.15),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  color: _accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: _primaryTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (businessName.isNotEmpty) ...[
                                    Text(
                                      businessName,
                                      style: TextStyle(
                                        color: _secondaryTextColor,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: role == 'Vendor'
                                              ? Colors.green.withOpacity(0.15)
                                              : Colors.blue.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          role,
                                          style: TextStyle(
                                            color: role == 'Vendor' ? Colors.green[700] : Colors.blue[700],
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          email,
                                          style: TextStyle(
                                            color: _secondaryTextColor,
                                            fontSize: 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Actions
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Status Toggle
                                Container(
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      isActive ? Icons.visibility : Icons.visibility_off,
                                      color: isActive ? Colors.green : Colors.red,
                                      size: 18,
                                    ),
                                    onPressed: () => FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(doc.id)
                                        .update({'isActive': !isActive}),
                                    padding: const EdgeInsets.all(6),
                                    constraints: const BoxConstraints(),
                                    tooltip: isActive ? 'Deactivate User' : 'Activate User',
                                  ),
                                ),
                                // Delete Button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                    onPressed: () => _confirmDeleteUser(doc.id),
                                    padding: const EdgeInsets.all(6),
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Delete User',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  // --- 3. INTAKE PROCESSING & APPROVAL MANAGEMENT PANEL ---
  Widget _buildPendingApprovals({required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: _isDarkMode
              ? [
                  const Color(0xFF0D0D0D),
                  const Color(0xFF1A0A0A),
                ]
              : [
                  const Color(0xFFFAF9F6),
                  const Color(0xFFFFF5F0),
                ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Requests',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Review and approve vendor registration requests',
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('pending_approvals').where('status', isEqualTo: 'pending').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all_rounded, size: 60, color: Colors.green.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            "All Clear!",
                            style: TextStyle(
                              color: _primaryTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Verification queue is completely clear",
                            style: TextStyle(color: _secondaryTextColor, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var doc = docs[index];
                      var data = doc.data() as Map<String, dynamic>;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "PENDING",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTimestamp(data['timestamp'] as Timestamp? ?? Timestamp.now()),
                                  style: TextStyle(color: _secondaryTextColor, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['businessName'] ?? 'Salon Registration Request',
                              style: TextStyle(
                                color: _primaryTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Owner: ${data['name'] ?? ''} • ${data['email'] ?? ''}",
                              style: TextStyle(color: _secondaryTextColor, fontSize: 12),
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => FirebaseFirestore.instance
                                      .collection('pending_approvals')
                                      .doc(doc.id)
                                      .update({'status': 'rejected'}),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.red.withOpacity(0.5)),
                                  ),
                                  child: const Text("Reject", style: TextStyle(color: Colors.red)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accentColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('pending_approvals')
                                        .doc(doc.id)
                                        .update({'status': 'approved'});
                                    if (data['uid'] != null) {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(data['uid'])
                                          .update({'role': 'Vendor'});
                                    }
                                  },
                                  child: const Text("Approve"),
                                )
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. IMPROVED LIVE MESSAGING CENTER ---
  Widget _buildLiveMessagingCenter({required bool isMobile}) {
    final String? adminId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: _isDarkMode
              ? [
                  const Color(0xFF0D0D0D),
                  const Color(0xFF1A0A0A),
                ]
              : [
                  const Color(0xFFFAF9F6),
                  const Color(0xFFFFF5F0),
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Live Messages',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _primaryTextColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Real-time chat with customers and vendors',
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: isMobile ? _buildMobileChatView(adminId) : _buildDesktopChatView(adminId),
          ),
        ],
      ),
    );
  }

  // --- DESKTOP CHAT VIEW ---
  Widget _buildDesktopChatView(String? adminId) {
    return Row(
      children: [
        Container(
          width: 280,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: _borderColor)),
          ),
          child: _buildUserList(adminId, isMobile: false),
        ),
        Expanded(
          child: _selectedChatUser == null
              ? _buildNoChatSelected()
              : _buildChatArea(isMobile: false),
        ),
      ],
    );
  }

  // --- MOBILE CHAT VIEW ---
  Widget _buildMobileChatView(String? adminId) {
    if (_selectedChatUser != null) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _cardColor,
              border: Border(bottom: BorderSide(color: _borderColor)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: _primaryTextColor),
                  onPressed: () {
                    setState(() {
                      _selectedChatUser = null;
                      _cachedMessages = [];
                    });
                  },
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _accentColor.withOpacity(0.2),
                  child: Text(
                    (_selectedChatUser!['name'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(color: _accentColor, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedChatUser!['name'] ?? 'User',
                        style: TextStyle(
                          color: _primaryTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _selectedChatUser!['role'] ?? 'User',
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_sweep, color: Colors.red[400], size: 20),
                  onPressed: () => _confirmDeleteAllMessages(_selectedChatUser!['uid']),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildChatMessages(),
          ),
          _buildMessageInput(isMobile: true),
        ],
      );
    }

    return _buildUserList(adminId, isMobile: true);
  }

  // --- BUILD USER LIST ---
  Widget _buildUserList(String? adminId, {required bool isMobile}) {
    return Column(
      children: [
        if (isMobile) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF222222) : const Color(0xFFF0EFFB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                style: TextStyle(fontSize: 13, color: _primaryTextColor),
                decoration: InputDecoration(
                  hintText: "Search users...",
                  hintStyle: TextStyle(color: _secondaryTextColor, fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded, color: _accentColor, size: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                ),
                onChanged: (value) {
                  setState(() {
                    _userSearchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
        ],
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', whereIn: ['Customer', 'Vendor'])
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
                      const SizedBox(height: 8),
                      Text(
                        "Error loading users",
                        style: TextStyle(color: _secondaryTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 40, color: _secondaryTextColor),
                      const SizedBox(height: 8),
                      Text(
                        "No users found",
                        style: TextStyle(color: _secondaryTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              var users = snapshot.data!.docs.where((doc) => doc.id != adminId).toList();

              if (_userSearchQuery.isNotEmpty) {
                users = users.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_userSearchQuery);
                }).toList();
              }

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 40, color: _secondaryTextColor),
                      const SizedBox(height: 8),
                      Text(
                        "No users found",
                        style: TextStyle(color: _secondaryTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  var userDoc = users[index];
                  var userData = userDoc.data() as Map<String, dynamic>;
                  String uid = userDoc.id;
                  bool isSelected = _selectedChatUser != null && _selectedChatUser!['uid'] == uid;
                  String role = userData['role'] ?? 'User';

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chat_messages')
                        .where('participants', arrayContains: uid)
                        .where('read', isEqualTo: false)
                        .where('isAdminMessage', isEqualTo: false)
                        .snapshots(),
                    builder: (context, unreadSnapshot) {
                      int unreadCount = unreadSnapshot.hasData ? unreadSnapshot.data!.docs.length : 0;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? _accentColor.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 12,
                            vertical: 2,
                          ),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: isMobile ? 18 : 20,
                                backgroundColor: _accentColor.withOpacity(0.2),
                                child: Text(
                                  (userData['name'] ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: _accentColor,
                                    fontSize: isMobile ? 12 : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            userData['name'] ?? 'User',
                            style: TextStyle(
                              color: _primaryTextColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: isMobile ? 13 : 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          subtitle: isMobile ? null : Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: role == 'Vendor'
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    color: role == 'Vendor' ? Colors.green[700] : Colors.blue[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (unreadCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: isMobile && unreadCount > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedChatUser = userData;
                              _selectedChatUser!['uid'] = uid;
                              _cachedMessages = [];
                              _markMessagesAsRead(uid);
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        if (isMobile) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: _borderColor.withOpacity(0.3))),
            ),
            child: Text(
              "Select a user to chat",
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- BUILD CHAT AREA ---
  Widget _buildChatArea({required bool isMobile}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: _borderColor)),
            color: _cardColor,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _accentColor.withOpacity(0.2),
                child: Text(
                  (_selectedChatUser!['name'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(color: _accentColor, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedChatUser!['name'] ?? 'User',
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _selectedChatUser!['role'] ?? 'User',
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_sweep, color: Colors.red[400], size: 20),
                onPressed: () => _confirmDeleteAllMessages(_selectedChatUser!['uid']),
                tooltip: "Delete all messages",
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildChatMessages(),
        ),
        _buildMessageInput(isMobile: isMobile),
      ],
    );
  }

  // --- BUILD NO CHAT SELECTED ---
  Widget _buildNoChatSelected() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: _accentColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No Conversation Selected",
              style: TextStyle(
                color: _primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Select a user from the list to start chatting",
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Chat with customers and vendors",
              style: TextStyle(
                color: _secondaryTextColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BUILD CHAT MESSAGES ---
  Widget _buildChatMessages() {
    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('chat_${_selectedChatUser?['uid'] ?? 'none'}'),
      stream: FirebaseFirestore.instance
          .collection('chat_messages')
          .where('participants', arrayContains: _selectedChatUser!['uid'])
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE28766)),
                ),
                const SizedBox(height: 12),
                Text(
                  "Loading messages...",
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  "Error loading messages",
                  style: TextStyle(
                    color: _primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: _accentColor.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "No messages yet",
                  style: TextStyle(
                    color: _primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Send a message to start the conversation",
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "💬 Say hello!",
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        _cachedMessages = snapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: _cachedMessages.length,
          itemBuilder: (context, index) {
            var doc = _cachedMessages[index];
            var data = doc.data() as Map<String, dynamic>;
            String messageId = doc.id;
            bool isAdmin = data['senderId'] == _currentAdminId;

            return _buildMessageBubble(
              data: data,
              isAdmin: isAdmin,
              messageId: messageId,
            );
          },
        );
      },
    );
  }

  // --- BUILD MESSAGE BUBBLE ---
  Widget _buildMessageBubble({
    required Map<String, dynamic> data,
    required bool isAdmin,
    required String messageId,
  }) {
    final String message = data['message'] ?? '';
    final bool isAdminMessage = data['isAdminMessage'] ?? false;
    final bool isCustomerMessage = data['isCustomerMessage'] ?? false;
    Timestamp? timestamp;

    if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
      timestamp = data['timestamp'] as Timestamp;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isAdmin) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: _accentColor.withOpacity(0.12),
                child: Text(
                  (_selectedChatUser!['name'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: const BoxConstraints(maxWidth: 300),
                  decoration: BoxDecoration(
                    gradient: isAdmin
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _accentColor,
                              _accentColor.withOpacity(0.85),
                            ],
                          )
                        : null,
                    color: isAdmin ? null : (_isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF1F1F1)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isAdmin ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: isAdmin ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isAdmin ? 0.1 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          color: isAdmin ? Colors.white : _primaryTextColor,
                          fontSize: 14.5,
                          height: 1.5,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timestamp != null ? _formatTimestamp(timestamp) : '',
                            style: TextStyle(
                              color: isAdmin
                                  ? Colors.white.withOpacity(0.7)
                                  : _secondaryTextColor.withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all,
                              size: 14,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ],
                          if (isAdminMessage && !isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE28766).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Admin",
                                style: TextStyle(
                                  color: const Color(0xFFE28766),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (isCustomerMessage && isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "User",
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _confirmDeleteSingleMessage(messageId),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: isAdmin
                                    ? Colors.white.withOpacity(0.4)
                                    : Colors.grey.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isAdmin) ...[
            const SizedBox(width: 10),
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: _accentColor,
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- BUILD MESSAGE INPUT ---
  Widget _buildMessageInput({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(
          top: BorderSide(
            color: _borderColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF222222) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _borderColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  color: _primaryTextColor,
                  fontSize: isMobile ? 14 : 15,
                ),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(
                    color: _secondaryTextColor.withOpacity(0.6),
                    fontSize: isMobile ? 13 : 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isMobile ? 10 : 14,
                    horizontal: 4,
                  ),
                ),
                onSubmitted: (_) => _sendTargetedMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: _accentColor,
              shape: const CircleBorder(),
              elevation: 4,
              shadowColor: _accentColor.withOpacity(0.3),
              child: InkWell(
                onTap: _sendTargetedMessage,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 14),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: isMobile ? 20 : 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MARK MESSAGES AS READ ---
  void _markMessagesAsRead(String userId) async {
    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      if (adminId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('chat_messages')
          .where('participants', arrayContains: userId)
          .where('read', isEqualTo: false)
          .where('isAdminMessage', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'read': true});
      }
    } catch (e) {
      // Ignore errors
    }
  }

  // --- DELETE SINGLE MESSAGE ---
  void _confirmDeleteSingleMessage(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text("Delete Message?", style: TextStyle(color: _primaryTextColor)),
        content: Text("This action cannot be undone.", style: TextStyle(color: _secondaryTextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('chat_messages').doc(messageId).delete();
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message deleted'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- DELETE ALL MESSAGES ---
  void _confirmDeleteAllMessages(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text("Delete All Messages?", style: TextStyle(color: _primaryTextColor)),
        content: Text(
          "This will delete all messages with ${_selectedChatUser!['name'] ?? 'this user'}. This action cannot be undone.",
          style: TextStyle(color: _secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final snapshot = await FirebaseFirestore.instance
                  .collection('chat_messages')
                  .where('participants', arrayContains: userId)
                  .get();

              final batch = FirebaseFirestore.instance.batch();
              for (var doc in snapshot.docs) {
                batch.delete(doc.reference);
              }
              await batch.commit();

              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _cachedMessages = [];
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All messages deleted'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text("Delete All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- FORMAT TIMESTAMP ---
  String _formatTimestamp(Timestamp timestamp) {
    try {
      final DateTime dateTime = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        if (difference.inDays > 7) {
          return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
        }
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  // --- SEND MESSAGE ---
  void _sendTargetedMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _selectedChatUser == null) return;

    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in as admin to send messages')),
      );
      return;
    }

    final String userId = _selectedChatUser!['uid'];

    try {
      await FirebaseFirestore.instance.collection('chat_messages').add({
        'senderId': adminId,
        'receiverId': userId,
        'message': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'participants': [adminId, userId],
        'read': false,
        'isAdminMessage': true,
        'isCustomerMessage': false,
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'senderId': adminId,
        'type': 'message',
        'title': 'New Message from Admin',
        'body': 'You have received a new message from the salon admin.',
        'message': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'chatId': 'admin_chat_$userId',
      });

      _messageController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message sent to ${_selectedChatUser!['name'] ?? 'user'}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  // --- 5. IMPROVED ANNOUNCEMENTS HUB ---
  // In salon_owner_screen.dart, replace the _buildAnnouncementsHub method with this:

Widget _buildAnnouncementsHub({required bool isMobile}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: _isDarkMode
            ? [
                const Color(0xFF0D0D0D),
                const Color(0xFF1A0A0A),
              ]
            : [
                const Color(0xFFFAF9F6),
                const Color(0xFFFFF5F0),
              ],
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Announcements",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create and manage system-wide announcements',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Fixed: Use Flexible and SingleChildScrollView to prevent overflow
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Card(
                    color: _cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: _borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Compose New Announcement',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _announcementTitleController,
                            style: TextStyle(color: _primaryTextColor),
                            decoration: InputDecoration(
                              hintText: "Announcement title...",
                              hintStyle: TextStyle(color: _secondaryTextColor, fontSize: 13),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: _borderColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: _accentColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              prefixIcon: Icon(Icons.title, color: _accentColor, size: 20),
                              filled: true,
                              fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _announcementController,
                            maxLines: 2,
                            style: TextStyle(color: _primaryTextColor),
                            decoration: InputDecoration(
                              hintText: "Write announcement message...",
                              hintStyle: TextStyle(color: _secondaryTextColor, fontSize: 13),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: _borderColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: _accentColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              prefixIcon: Icon(Icons.message, color: _accentColor, size: 20),
                              filled: true,
                              fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                "Target Audience: ",
                                style: TextStyle(color: _secondaryTextColor, fontSize: 13),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: _borderColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: _broadcastTarget,
                                  dropdownColor: _cardColor,
                                  style: TextStyle(color: _primaryTextColor),
                                  underline: const SizedBox(),
                                  items: <String>['All', 'Vendor', 'Customer'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Row(
                                        children: [
                                          Icon(
                                            value == 'All' ? Icons.public :
                                                value == 'Vendor' ? Icons.storefront : Icons.face,
                                            size: 16,
                                            color: _accentColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(value),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() => _broadcastTarget = newValue!);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _postAnnouncement,
                              icon: const Icon(Icons.send, size: 20),
                              label: const Text(
                                'Broadcast Announcement',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "Announcement History",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fixed: Use ConstrainedBox for history list
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.35,
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('announcements')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.campaign_outlined, size: 60, color: _secondaryTextColor.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  "No announcements yet",
                                  style: TextStyle(
                                    color: _secondaryTextColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Create your first announcement above",
                                  style: TextStyle(
                                    color: _secondaryTextColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        var list = snapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            var data = list[i].data() as Map<String, dynamic>;
                            String audience = data['targetAudience'] ?? 'All';
                            String title = data['title'] ?? 'Announcement';
                            String message = data['message'] ?? '';
                            Timestamp? timestamp;

                            if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
                              timestamp = data['timestamp'] as Timestamp;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: _cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _borderColor.withOpacity(0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _accentColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.campaign,
                                            color: _accentColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              color: _primaryTextColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                          onPressed: () => _confirmDeleteAnnouncement(list[i].id),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      message,
                                      style: TextStyle(
                                        color: _secondaryTextColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _accentColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            audience,
                                            style: TextStyle(
                                              color: _accentColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color: _secondaryTextColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          timestamp != null ? _formatTimestamp(timestamp) : 'No date',
                                          style: TextStyle(
                                            color: _secondaryTextColor,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // --- CONFIRM DELETE ANNOUNCEMENT ---
  void _confirmDeleteAnnouncement(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text(
          "Delete Announcement?",
          style: TextStyle(color: _primaryTextColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "This action cannot be undone.",
          style: TextStyle(color: _secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: _secondaryTextColor)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('announcements').doc(docId).delete();
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Announcement deleted'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete: $e')),
                );
              }
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- POST ANNOUNCEMENT ---
  void _postAnnouncement() async {
    final title = _announcementTitleController.text.trim();
    final message = _announcementController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            title.isEmpty ? 'Please enter an announcement title' : 'Please enter an announcement message',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'message': message,
        'targetAudience': _broadcastTarget,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _announcementTitleController.clear();
      _announcementController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement broadcast successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post announcement: $e')),
      );
    }
  }

  // --- SALON SETTINGS ---
  Widget _buildSalonSettings({required bool isMobile}) {
    TimeOfDay? openTime;
    TimeOfDay? closeTime;
    bool isSaving = false;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('settings')
          .doc('salon_settings')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          if (data['openTime'] != null) {
            var parts = data['openTime'].split(':');
            openTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
          if (data['closeTime'] != null) {
            var parts = data['closeTime'].split(':');
            closeTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: _isDarkMode
                      ? [
                          const Color(0xFF0D0D0D),
                          const Color(0xFF1A0A0A),
                        ]
                      : [
                          const Color(0xFFFAF9F6),
                          const Color(0xFFFFF5F0),
                        ],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: const DecorationImage(
                          image: AssetImage('assets/salon-1.jpg'),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.black.withOpacity(0.1),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "GlowSalon",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: Colors.black,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Premium Beauty & Wellness",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: Colors.black,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Working Hours',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set your working hours. Customers can only book during these hours.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      color: _cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: _borderColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDEEE9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.access_time, color: Color(0xFFF2845C)),
                              ),
                              title: const Text(
                                'Opening Time',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                openTime != null
                                    ? openTime!.format(context)
                                    : 'Select opening time',
                                style: TextStyle(
                                  fontWeight: openTime != null ? FontWeight.bold : FontWeight.normal,
                                  color: openTime != null ? _primaryTextColor : _secondaryTextColor,
                                ),
                              ),
                              trailing: Icon(Icons.edit, color: _accentColor),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: openTime ?? const TimeOfDay(hour: 9, minute: 0),
                                );
                                if (time != null) {
                                  setState(() {
                                    openTime = time;
                                  });
                                }
                              },
                            ),
                            const Divider(),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDEEE9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.access_time, color: Color(0xFFF2845C)),
                              ),
                              title: const Text(
                                'Closing Time',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                closeTime != null
                                    ? closeTime!.format(context)
                                    : 'Select closing time',
                                style: TextStyle(
                                  fontWeight: closeTime != null ? FontWeight.bold : FontWeight.normal,
                                  color: closeTime != null ? _primaryTextColor : _secondaryTextColor,
                                ),
                              ),
                              trailing: Icon(Icons.edit, color: _accentColor),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: closeTime ?? const TimeOfDay(hour: 21, minute: 0),
                                );
                                if (time != null) {
                                  setState(() {
                                    closeTime = time;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text(
                                        'Opens',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        openTime != null
                                            ? openTime!.format(context)
                                            : 'Not set',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: openTime != null ? Colors.green : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: Colors.grey[300],
                                  ),
                                  Column(
                                    children: [
                                      const Text(
                                        'Closes',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        closeTime != null
                                            ? closeTime!.format(context)
                                            : 'Not set',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: closeTime != null ? Colors.red : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isSaving ? null : () async {
                                  if (openTime == null || closeTime == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please select both open and close time'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() => isSaving = true);

                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('settings')
                                        .doc('salon_settings')
                                        .set({
                                          'openTime': '${openTime!.hour}:${openTime!.minute}',
                                          'closeTime': '${closeTime!.hour}:${closeTime!.minute}',
                                          'updatedAt': FieldValue.serverTimestamp(),
                                          'updatedBy': FirebaseAuth.instance.currentUser?.uid,
                                        }, SetOptions(merge: true));

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Settings saved successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error saving: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    setState(() => isSaving = false);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accentColor,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Save Settings',
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 6. RECENT ACTIVITY ---
  Widget _buildRealtimeRecentActivityList() {
    final String? adminId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['Customer', 'Vendor'])
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: Text(
              "No recent activity.",
              style: TextStyle(color: _secondaryTextColor),
            ),
          );
        }

        var docs = snapshot.data!.docs.where((doc) => doc.id != adminId).toList();

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: Text(
              "No recent activity.",
              style: TextStyle(color: _secondaryTextColor),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (c, i) => Divider(height: 1, color: _borderColor),
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String role = data['role'] ?? 'User';

              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: _accentColor.withOpacity(0.1),
                  child: Text(
                    (data['name'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  data['name'] ?? 'New Account',
                  style: TextStyle(
                    color: _primaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: role == 'Vendor'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          color: role == 'Vendor' ? Colors.green[700] : Colors.blue[700],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.check_circle, color: Colors.green, size: 14),
              );
            },
          ),
        );
      },
    );
  }

  // --- DELETE USER ---
  void _confirmDeleteUser(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text("Delete account permanently?", style: TextStyle(color: _primaryTextColor, fontSize: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- LOGOUT ---
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text("Log Out?", style: TextStyle(color: _primaryTextColor, fontSize: 16)),
        content: Text("Are you sure you want to log out?", style: TextStyle(color: _secondaryTextColor, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () => _signOut(), child: const Text("Log Out")),
        ],
      ),
    );
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const SignInScreen()));
    }
  }
}