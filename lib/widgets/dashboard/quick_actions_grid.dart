import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quick_action_card.dart';

// Import all screens for navigation
import '../../screens/customer/nearby_salons.dart';
import '../../screens/customer/booking_calendar.dart';
import '../../screens/customer/service_menu.dart';
import '../../screens/customer/product_shop.dart';
import '../../screens/customer/virtual_makeup_screen.dart';
import '../../screens/customer/real_time_chat.dart';
import '../../screens/customer/loyalty_screen.dart';

class QuickActionsGrid extends StatelessWidget {
  QuickActionsGrid({super.key});

  final List<QuickAction> actions = [
    const QuickAction('Nearby', Icons.map, Color(0xFFF2845C), NearbySalonsScreen()),
    const QuickAction('Book', Icons.calendar_today, Color(0xFF6C5CE7), BookingCalendarScreen()),
    const QuickAction('Services', Icons.spa, Color(0xFF00B894), ServiceMenuScreen()),
    const QuickAction('Shop', Icons.shopping_bag, Color(0xFFE17055), ProductShopScreen()),
    const QuickAction('AR Try-On', Icons.face_retouching_natural, Color(0xFF0984E3), VirtualMakeupScreen()),
    const QuickAction('Chat', Icons.message, Color(0xFF00B894), RealTimeChatScreen()),
    const QuickAction('Loyalty', Icons.card_giftcard, Color(0xFFE17055), LoyaltyScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              return QuickActionCard(action: actions[index]);
            },
          ),
        ],
      ),
    );
  }
}