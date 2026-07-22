import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../signin_screen.dart';

// Import all vendor screens
import 'profile_screen.dart';
import 'products_screen.dart';
import 'orders_screen.dart';
import 'vendor_chat_list_screen.dart';
import 'announcements_screen.dart';
import 'vendor_statistics_screen.dart';
import 'working_hours_screen.dart';
import 'unavailable_dates_screen.dart';
import 'promotions_screen.dart';
import 'settings_screen.dart';
import 'add_product_screen.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _vendorName = 'Vendor';
  String _businessName = '';
  bool _isLoading = true;
  bool _isDarkMode = false;
  int _unreadChatCount = 0;
  int _unreadAnnouncements = 0;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
    _loadUnreadChatCount();
    _loadUnreadAnnouncements();
  }

  Future<void> _loadVendorData() async {
    if (user == null) return;
    
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _vendorName = data['name'] ?? 'Vendor';
          _businessName = data['businessName'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading vendor data: $e');
    }
  }

  Future<void> _loadUnreadChatCount() async {
    if (user == null) return;

    try {
      QuerySnapshot chatSnapshot = await _firestore
          .collection('chat_messages')
          .where('participants', arrayContains: user!.uid)
          .get();

      int unreadCount = 0;
      for (var doc in chatSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        bool isRead = data['read'] ?? true;
        bool isAdminMessage = data['isAdminMessage'] ?? false;
        
        if (!isRead && !isAdminMessage) {
          unreadCount++;
        }
      }

      setState(() {
        _unreadChatCount = unreadCount;
      });
    } catch (e) {
      setState(() {
        _unreadChatCount = 0;
      });
    }
  }

  Future<void> _loadUnreadAnnouncements() async {
    if (user == null) return;

    try {
      QuerySnapshot announcementSnapshot = await _firestore
          .collection('announcements')
          .where('readBy', arrayContains: user!.uid)
          .get();

      // Count unread announcements
      int unreadCount = 0;
      for (var doc in announcementSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        List readBy = data['readBy'] ?? [];
        if (!readBy.contains(user!.uid)) {
          unreadCount++;
        }
      }

      setState(() {
        _unreadAnnouncements = unreadCount;
      });
    } catch (e) {
      setState(() {
        _unreadAnnouncements = 0;
      });
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error logging out: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Log Out',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            _businessName.isNotEmpty ? _businessName : "Vendor Dashboard",
            style: TextStyle(
              color: _isDarkMode ? Colors.white : const Color(0xFF2D3A4B),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: const SizedBox(),
          actions: [
            // Theme Toggle
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: Icon(
                  _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: const Color(0xFFF2845C),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isDarkMode = !_isDarkMode;
                  });
                },
              ),
            ),
           
            // Announcements Button with Badge
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Color(0xFFF2845C), size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VendorAnnouncementsScreen(),
                        ),
                      ).then((_) {
                        _loadUnreadAnnouncements();
                      });
                    },
                  ),
                  if (_unreadAnnouncements > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Center(
                          child: Text(
                            _unreadAnnouncements > 9 ? '9+' : _unreadAnnouncements.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Chats Button with Unread Badge
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat, color: Color(0xFFF2845C), size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VendorChatListScreen(),
                        ),
                      ).then((_) {
                        _loadUnreadChatCount();
                      });
                    },
                  ),
                  if (_unreadChatCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Center(
                          child: Text(
                            _unreadChatCount > 9 ? '9+' : _unreadChatCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Profile Button
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.person_outline, color: Color(0xFFF2845C), size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorProfileScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFFF2845C),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await _loadUnreadChatCount();
                  await _loadUnreadAnnouncements();
                  setState(() {});
                },
                color: const Color(0xFFF2845C),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 20),
                      _buildStatsGrid(),
                      const SizedBox(height: 20),
                      _buildQuickActionsGrid(),
                      const SizedBox(height: 20),
                      _buildRecentOrders(),
                      const SizedBox(height: 20),
                      _buildLowStockAlert(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF2845C), Color(0xFFFFB6A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2845C).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Text(
                  _vendorName.isNotEmpty ? _vendorName[0].toUpperCase() : 'V',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, $_vendorName! 👋",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_businessName.isNotEmpty)
                      Text(
                        _businessName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                const Text(
                  "Premium Vendor",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('products')
          .where('vendorId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, productSnapshot) {
        int productCount = productSnapshot.hasData ? productSnapshot.data!.docs.length : 0;
        
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('orders')
              .where('vendorId', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, orderSnapshot) {
            int totalOrders = orderSnapshot.hasData ? orderSnapshot.data!.docs.length : 0;
            double totalRevenue = 0;
            int pendingOrders = 0;
            
            if (orderSnapshot.hasData) {
              for (var doc in orderSnapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                totalRevenue += (data['amount'] ?? 0).toDouble();
                if (data['status'] == 'pending' || data['status'] == 'placed') {
                  pendingOrders++;
                }
              }
            }

            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  'Total Products',
                  productCount.toString(),
                  Icons.inventory_2_outlined,
                  Colors.blue,
                  _isDarkMode,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VendorProductsScreen(),
                      ),
                    );
                  },
                ),
                _buildStatCard(
                  'Total Orders',
                  totalOrders.toString(),
                  Icons.shopping_cart_outlined,
                  Colors.green,
                  _isDarkMode,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VendorOrdersScreen(),
                      ),
                    );
                  },
                ),
                _buildStatCard(
                  'Revenue',
                  'Rs.${_formatNumber(totalRevenue)}',
                  Icons.trending_up,
                  const Color(0xFFF2845C),
                  _isDarkMode,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VendorStatisticsScreen(),
                      ),
                    );
                  },
                ),
                _buildStatCard(
                  'Pending Orders',
                  pendingOrders.toString(),
                  Icons.pending_actions,
                  Colors.orange,
                  _isDarkMode,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VendorOrdersScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(isDark ? 0.2 : 0.06),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
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
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2D3A4B),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return NumberFormat('#,###').format(number);
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {'icon': Icons.add_shopping_cart, 'label': 'Add Product', 'color': const Color(0xFFF2845C)},
      {'icon': Icons.shopping_bag, 'label': 'Products', 'color': Colors.blue},
      {'icon': Icons.bar_chart, 'label': 'Analytics', 'color': Colors.purple},
      {'icon': Icons.local_offer, 'label': 'Promotions', 'color': Colors.green},
      {'icon': Icons.access_time, 'label': 'Working Hours', 'color': Colors.orange},
      {'icon': Icons.event_busy, 'label': 'Unavailable', 'color': Colors.red},
      {'icon': Icons.settings, 'label': 'Settings', 'color': Colors.grey},
      {'icon': Icons.chat, 'label': 'Chats', 'color': Colors.teal},
      {'icon': Icons.notifications, 'label': 'Announcements', 'color': Colors.pink},
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickAction(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          color: action['color'] as Color,
          isDark: _isDarkMode,
          onTap: () {
            switch (action['label']) {
              case 'Add Product':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductScreen(vendorId: user?.uid ?? ''),
                  ),
                );
                break;
              case 'Products':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendorProductsScreen(),
                  ),
                );
                break;
              case 'Analytics':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendorStatisticsScreen(),
                  ),
                );
                break;
              case 'Promotions':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendorPromotionsScreen(),
                  ),
                );
                break;
              case 'Working Hours':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkingHoursScreen(vendorId: user?.uid ?? ''),
                  ),
                );
                break;
              case 'Unavailable':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UnavailableDatesScreen(vendorId: user?.uid ?? ''),
                  ),
                );
                break;
              case 'Settings':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendorSettingsScreen(),
                  ),
                );
                break;
              case 'Chats':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendorChatListScreen(),
                  ),
                ).then((_) {
                  _loadUnreadChatCount();
                });
                break;
              case 'Announcements':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendorAnnouncementsScreen(),
                  ),
                ).then((_) {
                  _loadUnreadAnnouncements();
                });
                break;
            }
          },
        );
      },
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Replace the _buildOrderItem method with this:

Widget _buildOrderItem({
  required String id,
  required String customer,
  required double amount,  // Changed to double
  required String status,
  Timestamp? date,
}) {
  Color statusColor;
  String statusLabel;
  
  switch (status) {
    case 'delivered':
      statusColor = Colors.green;
      statusLabel = 'Delivered';
      break;
    case 'shipped':
      statusColor = Colors.blue;
      statusLabel = 'Shipped';
      break;
    case 'processing':
      statusColor = Colors.orange;
      statusLabel = 'Processing';
      break;
    case 'cancelled':
      statusColor = Colors.red;
      statusLabel = 'Cancelled';
      break;
    default:
      statusColor = Colors.grey;
      statusLabel = 'Pending';
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            status == 'delivered' ? Icons.check_circle : Icons.pending,
            color: statusColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.white : const Color(0xFF2D3A4B),
                  fontSize: 13,
                ),
              ),
              Text(
                'Order #${id.substring(0, 8)}',
                style: TextStyle(
                  fontSize: 11,
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Rs.${NumberFormat('#,###').format(amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFF2845C),
                fontSize: 14,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 9,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// And update the _buildRecentOrders method where amount is passed:

Widget _buildRecentOrders() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(_isDarkMode ? 0.2 : 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : const Color(0xFF2D3A4B),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendorOrdersScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF2845C),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: const Text('View All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('orders')
              .where('vendorId', isEqualTo: user?.uid)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: const Center(
                  child: Text('Error loading orders'),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'No customer orders yet',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                // FIXED: Ensure amount is converted to double
                double amount = 0.0;
                if (data['total'] != null) {
                  amount = (data['total'] as num).toDouble();
                } else if (data['amount'] != null) {
                  amount = (data['amount'] as num).toDouble();
                }
                
                return _buildOrderItem(
                  id: doc.id,
                  customer: data['customerName'] ?? 'Customer',
                  amount: amount,
                  status: data['orderStatus'] ?? data['status'] ?? 'pending',
                  date: data['createdAt'] as Timestamp?,
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  );
}

  Widget _buildLowStockAlert() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('products')
          .where('vendorId', isEqualTo: user?.uid)
          .where('stock', isLessThan: 10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ Low Stock Alert',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${snapshot.data!.docs.length} products are running low on stock',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorProductsScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF2845C),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: const Text('View Products', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }
}