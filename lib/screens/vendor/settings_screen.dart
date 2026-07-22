import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../signin_screen.dart';
import 'profile_screen.dart';
import 'working_hours_screen.dart';
import 'unavailable_dates_screen.dart';
import 'promotions_screen.dart';
import 'announcements_screen.dart';
import 'vendor_chat_list_screen.dart';

class VendorSettingsScreen extends StatefulWidget {
  const VendorSettingsScreen({super.key});

  @override
  State<VendorSettingsScreen> createState() => _VendorSettingsScreenState();
}

class _VendorSettingsScreenState extends State<VendorSettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3A4B),
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: 'Update your business information',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendorProfileScreen(),
                  ),
                );
              },
              isDark: isDarkMode,
            ),
            _buildSettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'View announcements and updates',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendorAnnouncementsScreen(),
                  ),
                );
              },
              isDark: isDarkMode,
            ),
            
            const SizedBox(height: 20),

            // Business Section
            const Text(
              'Business',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3A4B),
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingsTile(
              icon: Icons.access_time,
              title: 'Working Hours',
              subtitle: 'Set your business hours',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkingHoursScreen(vendorId: user?.uid ?? ''),
                  ),
                );
              },
              isDark: isDarkMode,
            ),
            _buildSettingsTile(
              icon: Icons.event_busy,
              title: 'Unavailable Dates',
              subtitle: 'Mark holidays and days off',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UnavailableDatesScreen(vendorId: user?.uid ?? ''),
                  ),
                );
              },
              isDark: isDarkMode,
            ),
            _buildSettingsTile(
              icon: Icons.local_offer,
              title: 'Promotions',
              subtitle: 'Manage your discounts and offers',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendorPromotionsScreen(),
                  ),
                );
              },
              isDark: isDarkMode,
            ),
            _buildSettingsTile(
              icon: Icons.attach_money,
              title: 'Payout Settings',
              subtitle: 'Manage your payment preferences',
              onTap: () {
                // Navigate to payout settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payout settings will be available soon'),
                    backgroundColor: Color(0xFFF2845C),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              isDark: isDarkMode,
            ),
            
            const SizedBox(height: 20),

            // Support Section
            const Text(
              'Support',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3A4B),
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingsTile(
              icon: Icons.chat,
              title: 'Live Chat Support',
              subtitle: 'Chat with support team',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendorChatListScreen(),
                  ),
                );
              },
              isDark: isDarkMode,
            ),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              subtitle: 'View our terms and conditions',
              onTap: () {
                _showTermsDialog();
              },
              isDark: isDarkMode,
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Learn about our privacy practices',
              onTap: () {
                _showPrivacyDialog();
              },
              isDark: isDarkMode,
            ),
            
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoggingOut ? null : _showLogoutConfirmation,
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.logout),
                label: Text(
                  _isLoggingOut ? 'Logging Out...' : 'Secure Log Out',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Acceptance of Terms',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('By using GlowSalon, you agree to these terms.'),
              const SizedBox(height: 12),
              const Text(
                '2. Vendor Responsibilities',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('Vendors must provide accurate information and quality services.'),
              const SizedBox(height: 12),
              const Text(
                '3. Payments',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('All payments are processed securely through our platform.'),
              const SizedBox(height: 12),
              const Text(
                '4. Cancellations',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('Vendors must honor booking cancellations per our policy.'),
            ],
          ),
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

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Information We Collect',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('We collect business information, contact details, and service data.'),
              const SizedBox(height: 12),
              const Text(
                'How We Use Your Data',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('Your data is used to provide services, process bookings, and improve our platform.'),
              const SizedBox(height: 12),
              const Text(
                'Data Security',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('We implement industry-standard security measures to protect your data.'),
            ],
          ),
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFDEEE9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFF2845C), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF2D3A4B),
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 11,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutConfirmation() {
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
            onPressed: _performLogout,
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

  Future<void> _performLogout() async {
    setState(() => _isLoggingOut = true);
    
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }
}