// lib/screens/vendor/vendor_statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorStatisticsScreen extends StatefulWidget {
  const VendorStatisticsScreen({super.key});

  @override
  State<VendorStatisticsScreen> createState() => _VendorStatisticsScreenState();
}

class _VendorStatisticsScreenState extends State<VendorStatisticsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      // Get products count
      QuerySnapshot productsSnapshot = await _firestore
          .collection('products')
          .where('vendorId', isEqualTo: user?.uid)
          .get();
      int productCount = productsSnapshot.docs.length;

      // Get orders
      QuerySnapshot ordersSnapshot = await _firestore
          .collection('orders')
          .where('vendorId', isEqualTo: user?.uid)
          .get();
      
      int totalOrders = ordersSnapshot.docs.length;
      double totalRevenue = 0;
      for (var doc in ordersSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        totalRevenue += (data['amount'] ?? 0).toDouble();
      }

      // Get pending earnings (simplified)
      double pendingEarnings = totalRevenue * 0.15;

      setState(() {
        _stats = {
          'productCount': productCount,
          'totalOrders': totalOrders,
          'totalRevenue': totalRevenue,
          'pendingEarnings': pendingEarnings,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading statistics: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistics Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      _buildSummaryCard('Total Sales', 'Rs.${NumberFormat('#,###').format(_stats['totalRevenue'] ?? 0)}', 
                          Icons.trending_up, Colors.green),
                      const SizedBox(width: 15),
                      _buildSummaryCard('Total Orders', '${_stats['totalOrders'] ?? 0}', 
                          Icons.shopping_cart, Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildSummaryCard('Products', '${_stats['productCount'] ?? 0}', 
                          Icons.inventory, const Color(0xFFF2845C)),
                      const SizedBox(width: 15),
                      _buildSummaryCard('Pending', 'Rs.${NumberFormat('#,###').format(_stats['pendingEarnings'] ?? 0)}', 
                          Icons.pending, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Weekly Sales Chart
                  const Text(
                    'Weekly Sales',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: _buildBarChart(),
                  ),
                  const SizedBox(height: 30),

                  // Top Products
                  const Text(
                    'Top Selling Products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildTopProductsList(),
                  const SizedBox(height: 30),

                  // Performance Metrics
                  const Text(
                    'Performance Metrics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildMetricRow('Conversion Rate', '24%', 0.24),
                  _buildMetricRow('Returning Customers', '35%', 0.35),
                  _buildMetricRow('Average Order Value', 'Rs.1,850', 0.60),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3A4B),
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10000,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(days[value.toInt()]);
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('Rs.${value.toInt()}');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(toY: 5000, color: const Color(0xFFF2845C), width: 15)
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(toY: 7000, color: const Color(0xFFF2845C), width: 15)
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(toY: 4500, color: const Color(0xFFF2845C), width: 15)
          ]),
          BarChartGroupData(x: 3, barRods: [
            BarChartRodData(toY: 8000, color: const Color(0xFFF2845C), width: 15)
          ]),
          BarChartGroupData(x: 4, barRods: [
            BarChartRodData(toY: 6500, color: const Color(0xFFF2845C), width: 15)
          ]),
          BarChartGroupData(x: 5, barRods: [
            BarChartRodData(toY: 9000, color: const Color(0xFFF2845C), width: 15)
          ]),
          BarChartGroupData(x: 6, barRods: [
            BarChartRodData(toY: 7500, color: const Color(0xFFF2845C), width: 15)
          ]),
        ],
      ),
    );
  }

  Widget _buildTopProductsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('products')
          .where('vendorId', isEqualTo: user?.uid)
          .orderBy('salesCount', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No products yet', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String name = data['name'] ?? 'Product';
            int salesCount = data['salesCount'] ?? 0;
            double price = (data['price'] ?? 0).toDouble();
            double revenue = price * salesCount;
            
            return _buildTopProduct(
              name: name,
              sales: '$salesCount sold',
              revenue: 'Rs.${NumberFormat('#,###').format(revenue)}',
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTopProduct({required String name, required String sales, required String revenue}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFDEEE9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, color: Color(0xFFF2845C), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(sales, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Text(revenue, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF2845C)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}