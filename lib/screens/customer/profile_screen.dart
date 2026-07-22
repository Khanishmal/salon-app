// lib/screens/customer/customer_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'orders_screen.dart';
import '../signin_screen.dart';
import 'services_menu_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploadingImage = false;
  Map<String, dynamic> _userData = {};
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data() as Map<String, dynamic>;
          _nameController.text = _userData['name'] ?? '';
          _phoneController.text = _userData['phone'] ?? '';
          _addressController.text = _userData['address'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfileImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF1E1E24) 
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Image Source',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  context,
                  Icons.photo_library,
                  'Gallery',
                  ImageSource.gallery,
                ),
                _buildImageSourceOption(
                  context,
                  Icons.camera_alt,
                  'Camera',
                  ImageSource.camera,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    
    if (source != null && user != null) {
      try {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: source,
          maxWidth: 500,
          maxHeight: 500,
          imageQuality: 70,
        );
        
        if (pickedFile != null) {
          setState(() => _isUploadingImage = true);
          
          // Create a reference with a unique name
          final String fileName = 'profile_${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images/$fileName');
          
          final UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));
          final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
          final String imageUrl = await snapshot.ref.getDownloadURL();
          
          // Update Firestore
          await _firestore.collection('users').doc(user!.uid).update({
            'profileImage': imageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          await _loadUserData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: ${e.toString()}')),
        );
      } finally {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Widget _buildImageSourceOption(
    BuildContext context,
    IconData icon,
    String label,
    ImageSource source,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, source),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF2A2A30) 
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFFE28766)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (user == null) return;
    
    try {
      await _firestore.collection('users').doc(user!.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _isEditing = false;
        _userData['name'] = _nameController.text.trim();
        _userData['phone'] = _phoneController.text.trim();
        _userData['address'] = _addressController.text.trim();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FA);
    final cardColor = isDarkMode ? const Color(0xFF1E1E24) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2D3A4B);
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFE28766),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              if (_isEditing) {
                setState(() {
                  _isEditing = false;
                  _nameController.text = _userData['name'] ?? '';
                  _phoneController.text = _userData['phone'] ?? '';
                  _addressController.text = _userData['address'] ?? '';
                });
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE28766), Color(0xFFFFB6A0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: _isUploadingImage
                                  ? const SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFE28766),
                                      ),
                                    )
                                  : _userData['profileImage'] != null && _userData['profileImage'].toString().isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            _userData['profileImage'],
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                            errorBuilder: (context, error, stackTrace) => Text(
                                              (_userData['name'] ?? 'U')[0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFE28766),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          (_userData['name'] ?? 'U')[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFE28766),
                                          ),
                                        ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _updateProfileImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Color(0xFFE28766),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _userData['name'] ?? 'User',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _userData['email'] ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _userData['role'] ?? 'Customer',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats
                  Row(
                    children: [
                      _buildStatCard('Orders', _userData['totalOrders'] ?? 0, Icons.shopping_bag_rounded, cardColor, isDarkMode),
                      const SizedBox(width: 12),
                      _buildStatCard('Points', _userData['loyaltyPoints'] ?? 0, Icons.stars_rounded, cardColor, isDarkMode),
                      const SizedBox(width: 12),
                      _buildStatCard('Status', _userData['memberStatus'] ?? 'Bronze', Icons.verified_rounded, cardColor, isDarkMode),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Edit Profile Section
                  if (_isEditing) ...[
                    Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameController,
                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                labelStyle: TextStyle(color: subtitleColor),
                                border: const OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline, color: subtitleColor),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _phoneController,
                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                labelStyle: TextStyle(color: subtitleColor),
                                border: const OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone_outlined, color: subtitleColor),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _addressController,
                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Address',
                                labelStyle: TextStyle(color: subtitleColor),
                                border: const OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on_outlined, color: subtitleColor),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE28766),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Save Changes',
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Menu Items
                  Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.shopping_bag_outlined,
                          title: 'My Orders',
                          subtitle: 'View all your orders',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CustomerOrdersScreen(),
                              ),
                            );
                          },
                          isDarkMode: isDarkMode,
                        ),
                        const Divider(),
                        _buildMenuItem(
                          icon: Icons.calendar_today_outlined,
                          title: 'Booked Services',
                          subtitle: 'View your service bookings',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BookingHistoryScreen(),
                              ),
                            );
                          },
                          isDarkMode: isDarkMode,
                        ),
                        const Divider(),
                        _buildMenuItem(
                          icon: Icons.location_on_outlined,
                          title: 'Saved Addresses',
                          subtitle: 'Manage your delivery addresses',
                          onTap: () {
                            _showAddressManagementDialog();
                          },
                          isDarkMode: isDarkMode,
                        ),
                        const Divider(),
                        _buildMenuItem(
                          icon: Icons.payment_outlined,
                          title: 'Payment Methods',
                          subtitle: 'Manage your payment options',
                          onTap: () {
                            _showPaymentMethodsDialog();
                          },
                          isDarkMode: isDarkMode,
                        ),
                        const Divider(),
                        _buildMenuItem(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Manage notification preferences',
                          onTap: () {
                            _showNotificationSettingsDialog();
                          },
                          isDarkMode: isDarkMode,
                        ),
                        const Divider(),
                        _buildMenuItem(
                          icon: Icons.logout,
                          title: 'Logout',
                          subtitle: 'Sign out of your account',
                          onTap: _logout,
                          isLogout: true,
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, dynamic value, IconData icon, Color cardColor, bool isDarkMode) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFE28766), size: 24),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF2D3A4B),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLogout ? Colors.red.withOpacity(0.1) : const Color(0xFFFDEEE9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isLogout ? Colors.red : const Color(0xFFE28766),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: isLogout ? Colors.red : (isDarkMode ? Colors.white : const Color(0xFF2D3A4B)),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isLogout ? Colors.red : (isDarkMode ? Colors.grey[400] : Colors.grey[400]),
      ),
      onTap: onTap,
    );
  }

  // Dialog methods...
  void _showAddressManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved Addresses'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFFE28766)),
              title: const Text('Home'),
              subtitle: Text(_userData['address'] ?? 'No address saved'),
              trailing: IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isEditing = true);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isEditing = true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE28766),
            ),
            child: const Text('Add New Address'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Methods'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.credit_card, color: Color(0xFFE28766)),
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay when you receive'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Color(0xFFE28766)),
              title: const Text('JazzCash'),
              subtitle: const Text('Coming soon'),
              trailing: const Icon(Icons.lock, size: 16, color: Colors.grey),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Color(0xFFE28766)),
              title: const Text('EasyPaisa'),
              subtitle: const Text('Coming soon'),
              trailing: const Icon(Icons.lock, size: 16, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Preferences'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Order Updates'),
              subtitle: const Text('Get notified about order status'),
              value: true,
              onChanged: (_) {},
              activeColor: const Color(0xFFE28766),
            ),
            SwitchListTile(
              title: const Text('Promotions'),
              subtitle: const Text('Get notified about special offers'),
              value: true,
              onChanged: (_) {},
              activeColor: const Color(0xFFE28766),
            ),
            SwitchListTile(
              title: const Text('Messages'),
              subtitle: const Text('Get notified about new messages'),
              value: true,
              onChanged: (_) {},
              activeColor: const Color(0xFFE28766),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// --- BOOKING HISTORY SCREEN ---
class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Booked Services',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFE28766),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_bookings')
            .where('customerId', isEqualTo: user?.uid)
            // Removed orderBy to avoid index requirement
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
                    'Error loading bookings',
                    style: GoogleFonts.poppins(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE28766),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
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
                  Icon(Icons.calendar_today, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No Bookings Yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book your first service now!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ServicesMenuScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE28766),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Browse Services'),
                  ),
                ],
              ),
            );
          }

          // Sort bookings manually in memory
          var bookings = snapshot.data!.docs.toList();
          bookings.sort((a, b) {
            var aData = a.data() as Map<String, dynamic>;
            var bData = b.data() as Map<String, dynamic>;
            var aTime = aData['createdAt'] as Timestamp?;
            var bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var doc = bookings[index];
              var data = doc.data() as Map<String, dynamic>;
              return _buildBookingCard(data, isDarkMode);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> data, bool isDarkMode) {
    String status = data['status'] ?? 'pending';
    Color statusColor;
    String statusLabel;
    
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusLabel = 'Confirmed';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusLabel = 'Cancelled';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusLabel = 'Completed';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Pending';
    }

    Timestamp? bookingDate = data['bookingDate'] as Timestamp?;
    String dateStr = 'No date';
    if (bookingDate != null) {
      dateStr = DateFormat('MMM d, yyyy').format(bookingDate.toDate());
    }

    return Card(
      color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['serviceName'] ?? 'Service',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : const Color(0xFF2D3A4B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  data['bookingTime'] ?? 'No time',
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Price: Rs. ${data['servicePrice'] ?? 0}',
              style: GoogleFonts.poppins(
                color: const Color(0xFFE28766),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}