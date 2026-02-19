//vendor_product_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorProductScreen extends StatefulWidget {
  const VendorProductScreen({super.key});

  @override
  State<VendorProductScreen> createState() => _VendorProductScreenState();
}

class _VendorProductScreenState extends State<VendorProductScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Vendor Portal", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.black), onPressed: () {}), // Real-time Chat
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEarningsProjection(), // Track Commissions
            const SizedBox(height: 30),
            _buildSectionHeader("Product Portfolio", "Add New"), // Portfolio Management
            _buildProductGrid(),
            const SizedBox(height: 30),
            _buildAvailabilityCard(), // Availability Management
          ],
        ),
      ),
    );
  }

  // --- EARNINGS & COMMISSIONS ---
  Widget _buildEarningsProjection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Earnings Projection", style: TextStyle(color: Colors.white70, fontSize: 16)),
              Icon(Icons.trending_up, color: Colors.green),
            ],
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Rs. 45,200", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          ),
          const Divider(color: Colors.white24, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat("Commission (15%)", "Rs. 6,780"),
              _miniStat("Pending Payout", "Rs. 12,000"),
            ],
          )
        ],
      ),
    );
  }

  // --- PORTFOLIO / PRODUCT GRID ---
  Widget _buildProductGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8),
      itemCount: 4,
      itemBuilder: (context, index) => _productCard(),
    );
  }

  Widget _productCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Expanded(child: Container(color: Colors.grey.shade100, child: const Icon(Icons.image_outlined))),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Matte Lipstick", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Text("Rs. 1,200", style: TextStyle(color: Color(0xFFF2845C))),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- AVAILABILITY MANAGEMENT ---
  Widget _buildAvailabilityCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const Icon(Icons.access_time, color: Color(0xFFF2845C)),
        title: const Text("Manage Working Hours"),
        subtitle: const Text("Set your active sales and support hours"),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {}, // Set working hours
      ),
    );
  }

  Widget _miniStat(String label, String val) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      TextButton(onPressed: () {}, child: Text(action, style: const TextStyle(color: Color(0xFFF2845C)))),
    ]);
  }
}