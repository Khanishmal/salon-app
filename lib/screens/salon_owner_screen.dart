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

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  // Define Theme Colors Dynamically
  Color get _bgColor => _isDarkMode ? const Color(0xFF0D0D0D) : const Color(0xFFFAF9F6);
  Color get _cardColor => _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _primaryTextColor => _isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
  Color get _secondaryTextColor => _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _borderColor => _isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFEAE6DF);
  Color get _accentColor => const Color(0xFFE28766); // Premium Rose/Copper Gold

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 800;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            // Instantly returns to Dashboard Overview if on any other sub-tab
            if (_activeTab != 0) {
              setState(() => _activeTab = 0);
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
                            duration: const Duration(milliseconds: 300),
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
            floatingActionButton: FloatingActionButton(
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
              backgroundColor: _accentColor,
              mini: true,
              child: Icon(
                _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- PREMIUM RESPONSIVE SIDEBAR ---
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
                setState(() => _activeTab = index);
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

  // --- MODERN DYNAMIC TOP BAR ---
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
                  hintText: "Search dynamically...",
                  hintStyle: TextStyle(color: _secondaryTextColor, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: _accentColor, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
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

  // --- CORE SYSTEM ROUTER ---
  Widget _buildTabContent({required bool isMobile}) {
    switch (_activeTab) {
      case 0: return _buildDashboardOverview(isMobile: isMobile);
      case 1: return _buildUserManagement('All', isMobile: isMobile);
      case 2: return _buildUserManagement('Vendor', isMobile: isMobile);
      case 3: return _buildUserManagement('Customer', isMobile: isMobile);
      case 4: return _buildPendingApprovals(isMobile: isMobile);
      case 5: return _buildMessagingCenter(isMobile: isMobile);
      case 6: return _buildAnnouncements(isMobile: isMobile);
      default: return _buildDashboardOverview(isMobile: isMobile);
    }
  }

  // --- 1. DASHBOARD OVERVIEW ---
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
            Text("Real-time telemetry and management metrics.", style: TextStyle(color: _secondaryTextColor, fontSize: 13)),
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
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snap) => _analyticsCard("Total Profiles", snap.hasData ? snap.data!.docs.length.toString() : "0", Icons.people, Colors.blue, () => setState(() => _activeTab = 1)),
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

  // --- 2. USER MANAGEMENT VIEWS ---
  Widget _buildUserManagement(String filter, {required bool isMobile}) {
    Query query = FirebaseFirestore.instance.collection('users');
    if (filter != 'All') {
      query = query.where('role', isEqualTo: filter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            var data = d.data() as Map<String, dynamic>;
            return (data['name'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
                   (data['email'] ?? '').toString().toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(child: Text("No user records found.", style: TextStyle(color: _secondaryTextColor)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;
            bool isActive = data['isActive'] ?? true;

            return Card(
              color: _cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _borderColor)),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _accentColor.withOpacity(0.15),
                  child: Text(
                    (data['name'] ?? 'U').isNotEmpty ? (data['name'] ?? 'U')[0].toUpperCase() : 'U',
                    style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(data['name'] ?? 'No Name', style: TextStyle(color: _primaryTextColor, fontWeight: FontWeight.bold)),
                subtitle: Text("${data['email'] ?? ''} • [${data['role'] ?? 'User'}]", style: TextStyle(color: _secondaryTextColor, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(isActive ? Icons.block : Icons.check_circle, color: isActive ? Colors.red : Colors.green, size: 20),
                      onPressed: () => FirebaseFirestore.instance.collection('users').doc(doc.id).update({'isActive': !isActive}),
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

  // --- 3. PENDING APPROVAL QUEUE ---
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
                Text("Verification queue clean!", style: TextStyle(color: _primaryTextColor)),
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

  // --- 4. REAL-TIME LIVE MESSAGING INTERFACE ---
  Widget _buildMessagingCenter({required bool isMobile}) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('admin_messages').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var messages = snapshot.data!.docs;

              if (messages.isEmpty) {
                return Center(child: Text("No live dynamic logs here.", style: TextStyle(color: _secondaryTextColor)));
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var data = messages[index].data() as Map<String, dynamic>;
                  bool isAdmin = data['direction'] == 'from_admin';

                  return Align(
                    alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isAdmin ? _accentColor : (_isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        data['message'] ?? '',
                        style: TextStyle(color: isAdmin ? Colors.white : _primaryTextColor),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: _cardColor,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: _primaryTextColor),
                  decoration: const InputDecoration(hintText: "Type live message...", border: InputBorder.none),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: _accentColor),
                onPressed: _sendMessage,
              )
            ],
          ),
        )
      ],
    );
  }

  // --- 5. GLOBAL BROADCAST SYSTEM ---
  Widget _buildAnnouncements({required bool isMobile}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _announcementController,
            style: TextStyle(color: _primaryTextColor),
            decoration: InputDecoration(
              hintText: "Post global dynamic announcement...",
              hintStyle: TextStyle(color: _secondaryTextColor),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderColor)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _accentColor)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
              onPressed: _postAnnouncement,
              child: const Text("Broadcast Live", style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('announcements').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                var list = snapshot.data!.docs;

                if (list.isEmpty) {
                  return Center(child: Text("No history of global alerts.", style: TextStyle(color: _secondaryTextColor)));
                }

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    var data = list[i].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['message'] ?? '', style: TextStyle(color: _primaryTextColor)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 16, color: Colors.grey),
                        onPressed: () => FirebaseFirestore.instance.collection('announcements').doc(list[i].id).delete(),
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

  // --- REALTIME SUB-LIST LISTENER ---
  Widget _buildRealtimeRecentActivityList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Text("No new signups recorded.", style: TextStyle(color: _secondaryTextColor)),
          );
        }

        return Container(
          decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: _borderColor)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (c, i) => Divider(height: 1, color: _borderColor),
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                dense: true,
                leading: const Icon(Icons.account_circle, color: Colors.grey),
                title: Text(data['name'] ?? 'New Account Node', style: TextStyle(color: _primaryTextColor, fontWeight: FontWeight.w600)),
                subtitle: Text(data['role'] ?? 'Customer', style: TextStyle(color: _secondaryTextColor)),
                trailing: const Icon(Icons.check_circle, color: Colors.green, size: 14),
              );
            },
          ),
        );
      },
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('admin_messages').add({
      'message': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'direction': 'from_admin',
    });
    _messageController.clear();
  }

  void _postAnnouncement() async {
    if (_announcementController.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('announcements').add({
      'message': _announcementController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
    _announcementController.clear();
  }

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

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text("Log Out?", style: TextStyle(color: _primaryTextColor, fontSize: 16)),
        content: Text("Do you really want to close the dashboard session?", style: TextStyle(color: _secondaryTextColor, fontSize: 13)),
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