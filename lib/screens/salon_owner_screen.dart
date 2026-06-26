// lib/screens/salon_owner_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signin_screen.dart';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: _accentColor, size: 22),
              const SizedBox(width: 10),
              const Text(
                "GLOW MANAGEMENT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _adminNavItem(0, Icons.dashboard_customize_rounded, "Dashboard Overview", isMobile),
                _adminNavItem(1, Icons.people_alt_rounded, "User Management", isMobile),
                _adminNavItem(2, Icons.storefront_rounded, "Active Salons", isMobile),
                _adminNavItem(3, Icons.face_retouching_natural_rounded, "Client Directory", isMobile),
                _adminNavItem(4, Icons.verified_user_rounded, "Pending Requests", isMobile),
                _adminNavItem(5, Icons.chat_bubble_outline_rounded, "Live Messages", isMobile),
                _adminNavItem(6, Icons.campaign_rounded, "Global Broadcasts", isMobile),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF262626))),
            ),
            child: _adminNavItem(9, Icons.logout_rounded, "Secure Log Out", isMobile, isLogout: true),
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
  Widget _buildTopBar({required bool showMenuButton}) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
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
          Expanded(
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF222222) : const Color(0xFFF0EFFB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 13, color: _primaryTextColor),
                decoration: InputDecoration(
                  hintText: "Search dynamically across records...",
                  hintStyle: TextStyle(color: _secondaryTextColor, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: _accentColor, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
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
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: _accentColor,
                    child: Text(
                      count.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
      case 1: return _buildUserManagement('All', isMobile: isMobile);
      case 2: return _buildUserManagement('Vendor', isMobile: isMobile);
      case 3: return _buildUserManagement('Customer', isMobile: isMobile);
      case 4: return _buildPendingApprovals(isMobile: isMobile);
      case 5: return _buildLiveMessagingCenter(isMobile: isMobile);
      case 6: return _buildAnnouncementsHub(isMobile: isMobile);
      default: return _buildDashboardOverview(isMobile: isMobile);
    }
  }

  // --- 1. PREMIUM DASHBOARD OVERVIEW SCREEN ---
  Widget _buildDashboardOverview({required bool isMobile}) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      color: _accentColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Control Dashboard", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _primaryTextColor)),
            Text("Real-time telemetry and ecosystem management metrics.", style: TextStyle(color: _secondaryTextColor, fontSize: 13)),
            const SizedBox(height: 24),

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
                  builder: (context, snap) => _analyticsCard(
                    "Total Users",
                    snap.hasData ? snap.data!.docs.length.toString() : "0",
                    Icons.people,
                    Colors.blue,
                    () => setState(() => _activeTab = 1),
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Vendor').snapshots(),
                  builder: (context, snap) => _analyticsCard("Salons Active", snap.hasData ? snap.data!.docs.length.toString() : "0", Icons.storefront_rounded, Colors.green, () => setState(() => _activeTab = 2)),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Customer').snapshots(),
                  builder: (context, snap) => _analyticsCard("Clients", snap.hasData ? snap.data!.docs.length.toString() : "0", Icons.face_retouching_natural_rounded, Colors.purple, () => setState(() => _activeTab = 3)),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('pending_approvals').where('status', isEqualTo: 'pending').snapshots(),
                  builder: (context, snap) => _analyticsCard("Pending Approvals", snap.hasData ? snap.data!.docs.length.toString() : "0", Icons.verified_user_rounded, _accentColor, () => setState(() => _activeTab = 4)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text("Recent Profile Signups", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryTextColor)),
            const SizedBox(height: 12),
            _buildRealtimeRecentActivityList(),
          ],
        ),
      ),
    );
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
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 10),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _primaryTextColor)),
                Text(title, style: TextStyle(fontSize: 11, color: _secondaryTextColor, fontWeight: FontWeight.w500)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- 2. COMPLETE USER PROFILE DIRECTORY MANAGEMENT ---
  Widget _buildUserManagement(String filter, {required bool isMobile}) {
    final String? adminId = FirebaseAuth.instance.currentUser?.uid;
    
    Query query = FirebaseFirestore.instance.collection('users');
    
    if (filter == 'All') {
      query = query.where('role', whereIn: ['Customer', 'Vendor']);
    } else if (filter == 'Vendor') {
      query = query.where('role', isEqualTo: 'Vendor');
    } else if (filter == 'Customer') {
      query = query.where('role', isEqualTo: 'Customer');
    }

    return StreamBuilder<QuerySnapshot>(
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

        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            var data = d.data() as Map<String, dynamic>;
            return (data['name'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
                   (data['email'] ?? '').toString().toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;
            bool isActive = data['isActive'] ?? true;
            String role = data['role'] ?? 'User';

            return Card(
              color: _cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _borderColor),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _accentColor.withOpacity(0.15),
                  child: Text(
                    (data['name'] ?? 'U').isNotEmpty ? (data['name'] ?? 'U')[0].toUpperCase() : 'U',
                    style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  data['name'] ?? 'No Registered Name',
                  style: TextStyle(color: _primaryTextColor, fontWeight: FontWeight.bold),
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
                    const SizedBox(width: 6),
                    Text(
                      data['email'] ?? '',
                      style: TextStyle(color: _secondaryTextColor, fontSize: 12),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        color: isActive ? Colors.red : Colors.green,
                        size: 20,
                      ),
                      onPressed: () => FirebaseFirestore.instance
                          .collection('users')
                          .doc(doc.id)
                          .update({'isActive': !isActive}),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                      onPressed: () => _confirmDeleteUser(doc.id),
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

  // --- 3. INTAKE PROCESSING & APPROVAL MANAGEMENT PANEL ---
  Widget _buildPendingApprovals({required bool isMobile}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pending_approvals').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.done_all_rounded, size: 40, color: _secondaryTextColor),
                const SizedBox(height: 8),
                Text("Verification queue completely clear!", style: TextStyle(color: _primaryTextColor)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;

            return Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: _borderColor)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['businessName'] ?? 'Salon Registration Request', style: TextStyle(color: _primaryTextColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text("Owner: ${data['name'] ?? ''} • ${data['email'] ?? ''}", style: TextStyle(color: _secondaryTextColor, fontSize: 12)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => FirebaseFirestore.instance.collection('pending_approvals').doc(doc.id).update({'status': 'rejected'}),
                        child: const Text("Reject", style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('pending_approvals').doc(doc.id).update({'status': 'approved'});
                          if (data['uid'] != null) {
                            await FirebaseFirestore.instance.collection('users').doc(data['uid']).update({'role': 'Vendor'});
                          }
                        },
                        child: const Text("Approve", style: TextStyle(color: Colors.white)),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- 4. IMPROVED LIVE MESSAGING CENTER ---
  Widget _buildLiveMessagingCenter({required bool isMobile}) {
    final String? adminId = FirebaseAuth.instance.currentUser?.uid;

    return isMobile ? _buildMobileChatView(adminId) : _buildDesktopChatView(adminId);
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
          // Mobile Chat Header
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
        // Chat Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: _borderColor)), 
            color: _cardColor
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
              "You can chat with both customers and vendors",
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

  // --- BUILD MESSAGE BUBBLE (IMPROVED) ---
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
          // User avatar (only for received messages)
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
          
          // Message content
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
                            timestamp != null ? _formatTimestamp(timestamp!) : '',
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
                          // Delete button
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
          
          // Admin avatar (only for sent messages)
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

  // --- BUILD MESSAGE INPUT (IMPROVED) ---
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

  // --- 5. ANNOUNCEMENTS HUB ---
  Widget _buildAnnouncementsHub({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Compose System Announcement", style: TextStyle(color: _primaryTextColor, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          
          TextField(
            controller: _announcementTitleController,
            style: TextStyle(color: _primaryTextColor),
            decoration: InputDecoration(
              hintText: "Enter announcement title...",
              hintStyle: TextStyle(color: _secondaryTextColor, fontSize: 13),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderColor)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _accentColor)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Text("Target Demographics: ", style: TextStyle(color: _secondaryTextColor, fontSize: 13)),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _broadcastTarget,
                dropdownColor: _cardColor,
                style: TextStyle(color: _primaryTextColor),
                items: <String>['All', 'Vendor', 'Customer'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _broadcastTarget = newValue!);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _announcementController,
            maxLines: 3,
            style: TextStyle(color: _primaryTextColor),
            decoration: InputDecoration(
              hintText: "Write announcement message...",
              hintStyle: TextStyle(color: _secondaryTextColor, fontSize: 13),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderColor)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _accentColor)),
            ),
          ),
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor, 
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _postAnnouncement,
              child: Text(
                "Broadcast Announcement",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Text("Announcement History", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryTextColor)),
          const SizedBox(height: 12),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('announcements').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined, size: 40, color: _secondaryTextColor),
                        const SizedBox(height: 8),
                        Text("No announcements yet.", style: TextStyle(color: _secondaryTextColor)),
                      ],
                    ),
                  );
                }

                var list = snapshot.data!.docs;

                return ListView.builder(
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

                    return Card(
                      color: _cardColor,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: _borderColor), 
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          title,
                          style: TextStyle(color: _primaryTextColor, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message, style: TextStyle(color: _secondaryTextColor)),
                            const SizedBox(height: 4),
                            Text(
                              "Audience: $audience • ${timestamp != null ? _formatTimestamp(timestamp!) : 'No date'}",
                              style: TextStyle(color: _accentColor, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                          onPressed: () => _confirmDeleteAnnouncement(list[i].id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
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
            child: Text(
              "No new user registrations tracked.",
              style: TextStyle(color: _secondaryTextColor),
            ),
          );
        }

        var docs = snapshot.data!.docs.where((doc) => doc.id != adminId).toList();

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Text(
              "No new user registrations tracked.",
              style: TextStyle(color: _secondaryTextColor),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
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
                leading: const Icon(Icons.account_circle, color: Colors.grey),
                title: Text(
                  data['name'] ?? 'New Account',
                  style: TextStyle(color: _primaryTextColor, fontWeight: FontWeight.w600),
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
        content: Text("Do you really want to close the administrator console engine session?", style: TextStyle(color: _secondaryTextColor, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(onPressed: () => _signOut(), child: const Text("Yes, Log Out")),
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