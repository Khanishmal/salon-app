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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedUserType = 'All';
  
  // For messaging
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          _buildAdminSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _buildTabContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SIDEBAR WITH ALL ADMIN OPTIONS ---
  Widget _buildAdminSidebar() {
    return Container(
      width: 280,
      color: const Color(0xFF121212),
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Text(
            "GLOW ADMIN",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _adminNavItem(0, Icons.dashboard_rounded, "Dashboard Overview"),
                  _adminNavItem(1, Icons.people_rounded, "User Management"),
                  _adminNavItem(2, Icons.store_rounded, "Vendors"),
                  _adminNavItem(3, Icons.person_rounded, "Customers"),
                  _adminNavItem(4, Icons.pending_actions_rounded, "Pending Approvals"),
                  _adminNavItem(5, Icons.message_rounded, "Messages"),
                  _adminNavItem(6, Icons.campaign_rounded, "Announcements"),
                  _adminNavItem(7, Icons.analytics_rounded, "Analytics"),
                  _adminNavItem(8, Icons.settings_rounded, "Settings"),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white24, width: 1),
              ),
            ),
            child: _adminNavItem(9, Icons.logout, "Exit Admin", isLogout: true),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _adminNavItem(int index, IconData icon, String label, {bool isLogout = false}) {
    bool selected = _activeTab == index;
    return Container(
      color: selected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
      child: ListTile(
        onTap: isLogout ? _signOut : () => setState(() => _activeTab = index),
        leading: Icon(
          icon,
          color: selected ? const Color(0xFFF2845C) : Colors.grey[600],
          size: 24,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[600],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- TOP BAR WITH SEARCH AND NOTIFICATIONS ---
  Widget _buildTopBar() {
    return Container(
      height: 90,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search users, vendors, or customers...",
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFF2845C)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 25),
          
          // Pending Approvals Badge
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pending_approvals')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              int count = 0;
              if (snapshot.hasData && snapshot.data != null) {
                // Filter to only show vendor applications (not customers)
                var docs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return data['type'] == 'vendor' || data['role'] == 'Vendor';
                }).toList();
                count = docs.length;
              }
              
              return GestureDetector(
                onTap: () => setState(() => _activeTab = 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: count > 0 ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending_actions,
                        color: count > 0 ? Colors.orange : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$count Pending",
                        style: TextStyle(
                          color: count > 0 ? Colors.orange : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 15),
          
          // Unread Messages Badge
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('admin_messages')
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unread = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.message_outlined, size: 28),
                    onPressed: () => setState(() => _activeTab = 5),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 20),
          
          // Admin Profile
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              String email = snapshot.data?.email ?? 'Admin';
              String initial = email.isNotEmpty ? email[0].toUpperCase() : 'A';
              return CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF2845C),
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- TAB CONTENT BASED ON SELECTION ---
  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return _buildUserManagement('All');
      case 2:
        return _buildUserManagement('Vendor');
      case 3:
        return _buildUserManagement('Customer');
      case 4:
        return _buildPendingApprovals();
      case 5:
        return _buildMessagingCenter();
      case 6:
        return _buildAnnouncements();
      case 7:
        return _buildAnalytics();
      case 8:
        return _buildSettings();
      default:
        return _buildDashboardOverview();
    }
  }

  // --- 1. DASHBOARD OVERVIEW WITH FIXED STATS (EXCLUDING SALON OWNER) ---
  Widget _buildDashboardOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dashboard Overview",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          
          // Stats Cards with Proper Filtering
          Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', whereIn: ['Customer', 'Vendor'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _statCard(
                      "Total Users",
                      total.toString(),
                      Icons.people,
                      Colors.blue,
                      () => setState(() => _activeTab = 1),
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'Vendor')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _statCard(
                      "Vendors",
                      total.toString(),
                      Icons.store,
                      Colors.green,
                      () => setState(() => _activeTab = 2),
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'Customer')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _statCard(
                      "Customers",
                      total.toString(),
                      Icons.person,
                      Colors.purple,
                      () => setState(() => _activeTab = 3),
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('pending_approvals')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int pending = 0;
                    if (snapshot.hasData && snapshot.data != null) {
                      // Only count vendor applications
                      pending = snapshot.data!.docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return data['type'] == 'vendor' || data['role'] == 'Vendor';
                      }).length;
                    }
                    return _statCard(
                      "Pending",
                      pending.toString(),
                      Icons.pending_actions,
                      Colors.orange,
                      () => setState(() => _activeTab = 4),
                    );
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Searchable Recent Activity
          const Text(
            "Recent Activity",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildSearchableRecentActivity(),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --- 2. USER MANAGEMENT (EXCLUDING SALON OWNER) ---
  Widget _buildUserManagement(String roleFilter) {
    Query userQuery = FirebaseFirestore.instance
        .collection('users')
        .where('role', whereIn: roleFilter == 'All' 
            ? ['Customer', 'Vendor'] 
            : [roleFilter])
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: userQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var users = snapshot.data!.docs;
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          users = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final phone = (data['phone'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || 
                   email.contains(_searchQuery) || 
                   phone.contains(_searchQuery);
          }).toList();
        }

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(32),
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index];
            var data = user.data() as Map<String, dynamic>;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFFF2845C),
                  child: Text(
                    (data['name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                title: Text(
                  data['name'] ?? 'No Name',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['email'] ?? 'No Email'),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildUserBadge(data['role'] ?? 'Unknown'),
                        if (data['approved'] == false)
                          _buildStatusBadge('Pending', Colors.orange),
                        if (data['isActive'] == false)
                          _buildStatusBadge('Inactive', Colors.red),
                        if (data['isActive'] == true && data['approved'] == true)
                          _buildStatusBadge('Active', Colors.green),
                      ],
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.message,
                          label: 'Message',
                          color: Colors.blue,
                          onTap: () => _openMessageDialog(user.id, data['name']),
                        ),
                        _buildActionButton(
                          icon: data['isActive'] == false ? Icons.play_arrow : Icons.pause,
                          label: data['isActive'] == false ? 'Activate' : 'Suspend',
                          color: data['isActive'] == false ? Colors.green : Colors.orange,
                          onTap: () => _toggleUserStatus(user.id, data),
                        ),
                        _buildActionButton(
                          icon: Icons.edit,
                          label: 'Edit',
                          color: Colors.purple,
                          onTap: () => _editUserDialog(user.id, data),
                        ),
                        _buildActionButton(
                          icon: Icons.delete,
                          label: 'Delete',
                          color: Colors.red,
                          onTap: () => _deleteUserDialog(user.id),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserBadge(String role) {
    Color color;
    switch (role) {
      case 'Vendor':
        color = Colors.green;
        break;
      case 'Customer':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. PENDING APPROVALS (VENDORS ONLY) ---
  Widget _buildPendingApprovals() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pending_approvals')
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          if (snapshot.error.toString().contains('Missing or insufficient permissions')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 80, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Permission Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check Firestore security rules',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter to only show vendor applications
        var allDocs = snapshot.data!.docs;
        var pendingDocs = allDocs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['type'] == 'vendor' || data['role'] == 'Vendor';
        }).toList();

        if (pendingDocs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
                SizedBox(height: 20),
                Text(
                  "No Pending Approvals",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text("All vendor applications have been processed"),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(32),
          itemCount: pendingDocs.length,
          itemBuilder: (context, index) {
            var doc = pendingDocs[index];
            var data = doc.data() as Map<String, dynamic>;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFFF2845C),
                          child: Text(
                            (data['name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? 'No Name',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.email, data['email'] ?? 'N/A'),
                              _buildInfoRow(Icons.business, data['businessName'] ?? 'N/A'),
                              _buildInfoRow(Icons.phone, data['phone'] ?? 'N/A'),
                              _buildInfoRow(
                                Icons.calendar_today,
                                'Applied: ${_formatDate(data['submittedAt'])}',
                              ),
                              if (data['address'] != null)
                                _buildInfoRow(Icons.location_on, data['address']),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 40),
                    
                    // Approval Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showRejectionDialog(doc.id),
                          icon: const Icon(Icons.close),
                          label: const Text("Reject"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _approveVendor(doc.id, data['uid']),
                          icon: const Icon(Icons.check),
                          label: const Text("Approve Vendor"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
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
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. MESSAGING CENTER (FIXED PERMISSIONS) ---
  Widget _buildMessagingCenter() {
    return Row(
      children: [
        // Users List (Left Panel)
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Select User to Message",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedUserType,
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Users')),
                          DropdownMenuItem(value: 'Vendor', child: Text('Vendors Only')),
                          DropdownMenuItem(value: 'Customer', child: Text('Customers Only')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedUserType = value!;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildUserListForMessaging(),
                ),
              ],
            ),
          ),
        ),
        
        // Message Area (Right Panel)
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.grey[50],
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('admin_messages')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                var messages = snapshot.data!.docs;
                
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No messages yet",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msg = messages[index];
                    var data = msg.data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: data['direction'] == 'from_admin' 
                              ? const Color(0xFFF2845C) 
                              : Colors.blue,
                          child: Icon(
                            data['direction'] == 'from_admin' 
                                ? Icons.admin_panel_settings 
                                : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(data['userName'] ?? 'User'),
                        subtitle: Text(data['message'] ?? ''),
                        trailing: Text(
                          _formatTimeAgo(data['timestamp']),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserListForMessaging() {
    Query userQuery = FirebaseFirestore.instance
        .collection('users')
        .where('role', whereIn: _selectedUserType == 'All' 
            ? ['Customer', 'Vendor'] 
            : [_selectedUserType])
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: userQuery.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var users = snapshot.data!.docs;
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          users = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || email.contains(_searchQuery);
          }).toList();
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index];
            var data = user.data() as Map<String, dynamic>;
            
            return ListTile(
              onTap: () => _openMessageDialog(user.id, data['name']),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFF2845C),
                child: Text(
                  (data['name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(data['name'] ?? 'No Name'),
              subtitle: Text(data['email'] ?? ''),
              trailing: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('admin_messages')
                    .where('userId', isEqualTo: user.id)
                    .where('read', isEqualTo: false)
                    .snapshots(),
                builder: (context, msgSnapshot) {
                  int unread = msgSnapshot.hasData ? msgSnapshot.data!.docs.length : 0;
                  if (unread > 0) {
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unread.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  }
                  return const Icon(Icons.message_outlined, color: Colors.grey);
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openMessageDialog(String userId, String? userName) {
    _messageController.clear();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Send Message to ${userName ?? 'User'}"),
        content: Container(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _messageController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Type your message here...",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_messageController.text.isNotEmpty) {
                await _sendMessage(userId, userName ?? 'User', _messageController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2845C),
            ),
            child: const Text("Send Message"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String userId, String userName, String message) async {
    try {
      await FirebaseFirestore.instance.collection('admin_messages').add({
        'userId': userId,
        'userName': userName,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'direction': 'from_admin',
        'adminId': FirebaseAuth.instance.currentUser!.uid,
      });

      // Also create a notification for the user
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'New Message from Admin',
        'body': message.length > 50 ? '${message.substring(0, 50)}...' : message,
        'type': 'message',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSuccessMessage("Message sent to $userName");
    } catch (e) {
      print('Error sending message: $e');
      _showErrorMessage("Error sending message. Check permissions.");
    }
  }

  // --- 5. ANNOUNCEMENTS (FIXED PERMISSIONS) ---
  Widget _buildAnnouncements() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Announcement Panel
          Expanded(
            flex: 1,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Create Announcement",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    DropdownButtonFormField<String>(
                      value: 'All',
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Users')),
                        DropdownMenuItem(value: 'Vendor', child: Text('Vendors Only')),
                        DropdownMenuItem(value: 'Customer', child: Text('Customers Only')),
                      ],
                      onChanged: (value) {},
                      decoration: const InputDecoration(
                        labelText: "Send To",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: _announcementController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: "Announcement Message",
                        hintText: "Type your announcement here...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _sendAnnouncement,
                            icon: const Icon(Icons.campaign),
                            label: const Text("Send Announcement"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF2845C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 32),
          
          // Announcement History
          Expanded(
            flex: 1,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Announcement History",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('announcements')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            print('Error: ${snapshot.error}');
                            return Center(child: Text('Error loading announcements'));
                          }
                          
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          var announcements = snapshot.data!.docs;
                          
                          if (announcements.isEmpty) {
                            return const Center(
                              child: Text("No announcements yet"),
                            );
                          }
                          
                          return ListView.builder(
                            itemCount: announcements.length,
                            itemBuilder: (context, index) {
                              var ann = announcements[index];
                              var data = ann.data() as Map<String, dynamic>;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFF2845C),
                                    child: const Icon(Icons.campaign, color: Colors.white),
                                  ),
                                  title: Text(
                                    data['message'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'Sent to: ${data['targetAudience'] ?? 'All'} • ${_formatDateTime(data['timestamp'])}',
                                  ),
                                  isThreeLine: true,
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
          ),
        ],
      ),
    );
  }

  Future<void> _sendAnnouncement() async {
    if (_announcementController.text.isEmpty) {
      _showErrorMessage("Please enter an announcement message");
      return;
    }

    try {
      // Save announcement
      await FirebaseFirestore.instance.collection('announcements').add({
        'message': _announcementController.text,
        'targetAudience': 'All',
        'timestamp': FieldValue.serverTimestamp(),
        'sentBy': FirebaseAuth.instance.currentUser!.uid,
      });

      // Get all users (excluding admin)
      var users = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['Customer', 'Vendor'])
          .get();
      
      // Create notifications for all users
      for (var user in users.docs) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': user.id,
          'title': 'New Announcement',
          'body': _announcementController.text.length > 100 
              ? '${_announcementController.text.substring(0, 100)}...'
              : _announcementController.text,
          'type': 'announcement',
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      _announcementController.clear();
      _showSuccessMessage("Announcement sent to all users!");
    } catch (e) {
      print('Error sending announcement: $e');
      _showErrorMessage("Error sending announcement. Check permissions.");
    }
  }

  // --- 6. ANALYTICS (FIXED STATS) ---
  Widget _buildAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Platform Analytics",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          
          // User Statistics (excluding Salon Owner)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', whereIn: ['Customer', 'Vendor'])
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              
              var users = snapshot.data!.docs;
              int total = users.length;
              int vendors = users.where((doc) => 
                (doc.data() as Map)['role'] == 'Vendor').length;
              int customers = users.where((doc) => 
                (doc.data() as Map)['role'] == 'Customer').length;
              
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "User Statistics",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _analyticsItem("Total", total.toString(), Colors.blue),
                          _analyticsItem("Vendors", vendors.toString(), Colors.green),
                          _analyticsItem("Customers", customers.toString(), Colors.purple),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Pending Approvals Stats
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pending_approvals')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              int pending = 0;
              if (snapshot.hasData && snapshot.data != null) {
                pending = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return data['type'] == 'vendor' || data['role'] == 'Vendor';
                }).length;
              }
              
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Pending Approvals",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _analyticsItem("Pending", pending.toString(), Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Searchable Recent Activity
          const Text(
            "Recent Activity",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildSearchableRecentActivity(),
        ],
      ),
    );
  }

  Widget _analyticsItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- 7. SETTINGS ---
  Widget _buildSettings() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Admin Settings",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              
              _buildSettingTile(
                Icons.security,
                "Security Settings",
                "Configure password policies, 2FA, etc.",
                () {},
              ),
              
              _buildSettingTile(
                Icons.notifications,
                "Notification Settings",
                "Configure email and push notification preferences",
                () {},
              ),
              
              _buildSettingTile(
                Icons.brush,
                "Appearance",
                "Customize admin dashboard theme",
                () {},
              ),
              
              _buildSettingTile(
                Icons.backup,
                "Backup & Restore",
                "Manage database backups",
                () {},
              ),
              
              _buildSettingTile(
                Icons.api,
                "API Configuration",
                "Configure payment gateways and external APIs",
                () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2845C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFF2845C)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }

  // --- SEARCHABLE RECENT ACTIVITY ---
  Widget _buildSearchableRecentActivity() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['Customer', 'Vendor'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var users = snapshot.data!.docs;
        
        // Apply search filter if any
        if (_searchQuery.isNotEmpty) {
          users = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || email.contains(_searchQuery);
          }).toList();
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length > 10 ? 10 : users.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              var user = users[index];
              var data = user.data() as Map<String, dynamic>;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFF2845C),
                  child: Text(
                    (data['name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(data['name'] ?? 'Unknown'),
                subtitle: Text(
                  "${data['role'] ?? 'User'} joined ${_formatDate(data['createdAt'])}",
                ),
                trailing: Text(
                  _formatTimeAgo(data['createdAt']),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- HELPER FUNCTIONS (unchanged) ---
  Future<void> _approveVendor(String docId, String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('pending_approvals')
          .doc(docId)
          .update({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': FirebaseAuth.instance.currentUser!.uid,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'approved': true,
        'role': 'Vendor',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': uid,
        'title': 'Vendor Application Approved',
        'body': 'Congratulations! Your vendor application has been approved.',
        'type': 'approval',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSuccessMessage("Vendor approved successfully!");
    } catch (e) {
      print('Error approving vendor: $e');
      _showErrorMessage("Error approving vendor. Check permissions.");
    }
  }

  Future<void> _showRejectionDialog(String docId) {
    TextEditingController reasonController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Vendor Application"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please provide a reason for rejection:"),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Reason...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _rejectVendor(docId, reasonController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectVendor(String docId, String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('pending_approvals')
          .doc(docId)
          .update({
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessMessage("Vendor application rejected.");
    } catch (e) {
      print('Error rejecting vendor: $e');
      _showErrorMessage("Error rejecting vendor. Check permissions.");
    }
  }

  Future<void> _toggleUserStatus(String uid, Map<String, dynamic> data) async {
    try {
      bool newStatus = data['isActive'] == false;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _showSuccessMessage(newStatus ? "User activated" : "User suspended");
    } catch (e) {
      print('Error updating status: $e');
      _showErrorMessage("Error updating user status");
    }
  }

  Future<void> _editUserDialog(String uid, Map<String, dynamic> data) {
    TextEditingController nameController = TextEditingController(text: data['name']);
    TextEditingController emailController = TextEditingController(text: data['email']);
    TextEditingController phoneController = TextEditingController(text: data['phone'] ?? '');
    String selectedRole = data['role'] ?? 'Customer';
    bool isActive = data['isActive'] ?? true;
    bool approved = data['approved'] ?? true;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit User"),
        content: Container(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'Customer', child: Text('Customer')),
                    DropdownMenuItem(value: 'Vendor', child: Text('Vendor')),
                  ],
                  onChanged: (value) {
                    selectedRole = value!;
                  },
                  decoration: const InputDecoration(labelText: "Role"),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text("Active"),
                        value: isActive,
                        onChanged: (value) {
                          isActive = value!;
                        },
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text("Approved"),
                        value: approved,
                        onChanged: (value) {
                          approved = value!;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({
                  'name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'role': selectedRole,
                  'isActive': isActive,
                  'approved': approved,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                _showSuccessMessage("User updated successfully!");
              } catch (e) {
                print('Error updating user: $e');
                _showErrorMessage("Error updating user");
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUserDialog(String uid) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User"),
        content: const Text(
          "Are you sure you want to delete this user? "
          "This action cannot be undone and all user data will be permanently removed."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .delete();
                    
                Navigator.pop(context);
                _showSuccessMessage("User deleted successfully!");
              } catch (e) {
                print('Error deleting user: $e');
                _showErrorMessage("Error deleting user");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Unknown';
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'Unknown';
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      Duration diff = DateTime.now().difference(date);
      
      if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    }
    return 'Unknown';
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    }
  }
}