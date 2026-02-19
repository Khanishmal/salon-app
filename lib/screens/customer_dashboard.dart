//lib/screens/customer_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signin_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: _buildPremiumHeader(context),
      body: StreamBuilder<DocumentSnapshot>(
        // Real-time listener for user profile data (Loyalty, Status, Name)
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, userSnapshot) {
          // Change how you get the data safely
        final data = userSnapshot.data?.data() as Map<String, dynamic>?;

        if (data == null) return const Center(child: Text("Profile not found"));

          String name = data['name'] ?? "Guest";
          int points = (data['loyaltyPoints'] ?? 0) as int; // Cast to int safely
          String status = data['memberStatus'] ?? "Bronze";

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModernHero(name),
                const SizedBox(height: 40),
                
                // Real-time Stats Grid
                _buildRealTimeStatsGrid(points, status),
                const SizedBox(height: 50),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Content: Real-time Bookings
                    Expanded(flex: 2, child: _buildLiveAppointments()),
                    const SizedBox(width: 40),
                    // Sidebar: Premium Actions
                    Expanded(flex: 1, child: _buildPremiumSidebar(context)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildAIAdvisorButton(),
    );
  }

  // --- 1. PREMIUM APP BAR ---
  PreferredSizeWidget _buildPremiumHeader(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Image.asset('assets/logo_icon.png', height: 35, 
            errorBuilder: (c, e, s) => const Icon(Icons.auto_fix_high, color: Color(0xFFF2845C))),
          const SizedBox(width: 12),
          const Text("GlowSalon", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        ],
      ),
      actions: [
        _headerNavButton("Services"),
        _headerNavButton("Store"),
        const SizedBox(width: 20),
        const Icon(Icons.notifications_none_rounded, color: Colors.black54),
        const SizedBox(width: 20),
        CircleAvatar(
          backgroundColor: const Color(0xFFF2845C),
          child: Text(user?.email?[0].toUpperCase() ?? "U", style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 30),
      ],
    );
  }

  Widget _headerNavButton(String text) => TextButton(
    onPressed: () {}, 
    child: Text(text, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600))
  );

  // --- 2. GRADIENT HERO SECTION ---
  Widget _buildModernHero(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1C1E), Color(0xFF2D2F33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hello, $name 👋", style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Your beauty journey continues. You have 2 sessions left this month.", 
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18)),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2845C),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("Book New Session", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // --- 3. REAL-TIME STATS ---
  Widget _buildRealTimeStatsGrid(int points, String status) {
    return StreamBuilder<QuerySnapshot>(
      // Listen to booking count in real-time
      stream: FirebaseFirestore.instance.collection('bookings')
          .where('customerId', isEqualTo: user?.uid)
          .where('status', isEqualTo: 'Confirmed').snapshots(),
      builder: (context, snapshot) {
        int bookingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        
        return Row(
          children: [
            _statCard("$bookingCount", "Active Bookings", Icons.auto_awesome, Colors.blueAccent),
            _statCard("$points", "Glow Points", Icons.stars_rounded, Colors.orangeAccent),
            _statCard(status, "Membership", Icons.workspace_premium_rounded, Colors.purpleAccent),
          ],
        );
      },
    );
  }

  Widget _statCard(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 15),
            Text(val, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // --- 4. LIVE APPOINTMENT STREAM ---
  Widget _buildLiveAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Appointment Timeline", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bookings')
              .where('customerId', isEqualTo: user?.uid)
              .orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            if (snapshot.data!.docs.isEmpty) return _buildEmptyState();

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              separatorBuilder: (c, i) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                var booking = snapshot.data!.docs[index];
                return _appointmentCard(booking);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _appointmentCard(DocumentSnapshot doc) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            height: 60, width: 60,
            decoration: BoxDecoration(color: const Color(0xFFFDEEE9), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.content_cut_rounded, color: Color(0xFFF2845C)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc['serviceName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text("${doc['date']} at ${doc['time']}", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: doc['status'] == 'Confirmed' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(doc['status'], style: TextStyle(color: doc['status'] == 'Confirmed' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // --- 5. PREMIUM SIDEBAR ---
  Widget _buildPremiumSidebar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          _sidebarItem(Icons.camera_rounded, "AR Beauty Mirror", () {}),
          _sidebarItem(Icons.shopping_bag_outlined, "Product Orders", () {}),
          _sidebarItem(Icons.wallet_rounded, "Payment Methods", () {}),
          _sidebarItem(Icons.settings_suggest_rounded, "Personalization", () {}),
          const Divider(height: 40),
          _sidebarItem(Icons.logout_rounded, "Secure Sign Out", () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SignInScreen()));
          }, isRed: true),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, VoidCallback tap, {bool isRed = false}) {
    return ListTile(
      onTap: tap,
      leading: Icon(icon, color: isRed ? Colors.redAccent : Colors.black87),
      title: Text(label, style: TextStyle(color: isRed ? Colors.redAccent : Colors.black87, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text("No appointments found. Start your glow-up today!"));

  Widget _buildAIAdvisorButton() {
    return FloatingActionButton.extended(
      onPressed: () {},
      backgroundColor: const Color(0xFF1A1C1E),
      icon: const Icon(Icons.auto_awesome, color: Color(0xFFF2845C)),
      label: const Text("AI GLOW ADVISOR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}