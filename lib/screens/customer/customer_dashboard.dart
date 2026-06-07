// lib/screens/customer/customer_dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/dashboard/dashboard_app_bar.dart';
import '../../widgets/dashboard/welcome_section.dart';
import '../../widgets/dashboard/stats_row.dart';
import '../../widgets/dashboard/quick_actions_grid.dart';
import '../../widgets/dashboard/appointment_card.dart';
import '../../widgets/dashboard/ai_beauty_fab.dart';
import 'virtual_makeup_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5), // Premium Soft Ivory Silk background tone
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const DashboardAppBar(), 
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Decorative Welcome Cluster Card Base
                  const WelcomeSection(),
                  const SizedBox(height: 20),
                  
                  // Analytical Operational Status Counters Row
                  const StatsRow(),
                  const SizedBox(height: 28),
                  
                  // Interactive Immersive 3-Phases Architecture Track Panel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Intelligent Simulation Suite",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1E24),
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            "Deploy precision mapping pipelines across 3 modular phases",
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildVirtualModulePhasesTrack(context),
                  const SizedBox(height: 28),

                  // Section Header 2
                  Text(
                    "Exclusive AR Makeover Hub",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1E24),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Core Feature Access Navigation Grid Frame
                   QuickActionsGrid(), 
                  const SizedBox(height: 28),
                  
                  // Upcoming Engagements Module
                  const UpcomingAppointments(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const AIBeautyFAB(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFF2845C),
          unselectedItemColor: const Color(0xFFA0A0A0),
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 22), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded, size: 20), label: 'Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 22), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildVirtualModulePhasesTrack(BuildContext context) {
    final List<Map<String, dynamic>> phases = [
      {
        'phase': 'Phase 1',
        'title': 'Face & Chromatic Makeup',
        'subtitle': 'Lipstick, Eye Shadow & Foundation Swatches',
        'icon': Icons.face_retouching_natural_rounded,
        'color': const Color(0xFFF2845C),
        'targetCategory': 'Lipstick',
      },
      {
        'phase': 'Phase 2',
        'title': 'Premium Overlay Assets',
        'subtitle': 'Bridal Nath & Forehead Teeka Trackers',
        'icon': Icons.auto_awesome_rounded,
        'color': const Color(0xFFD15252),
        'targetCategory': 'Jewelry',
      },
      {
        'phase': 'Phase 3',
        'title': 'Forehead Henna Artistry',
        'subtitle': 'Dynamic Mehndi Layering Strips',
        'icon': Icons.brush_rounded,
        'color': const Color(0xFF4A2C00),
        'targetCategory': 'Mehndi',
      },
    ];

    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: phases.length,
        itemBuilder: (context, index) {
          final item = phases[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VirtualMakeupScreen(initialCategory: item['targetCategory'])),
            ),
            child: Container(
              width: 250,
              margin: const EdgeInsets.only(right: 14, bottom: 4, top: 2),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFF4EFEA), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: item['color'].withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item['icon'], color: item['color'], size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['phase'].toUpperCase(),
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: item['color'], letterSpacing: 0.5),
                        ),
                        Text(
                          item['title'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E1E24)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['subtitle'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}