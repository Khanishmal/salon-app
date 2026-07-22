import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
// Remove the collection import or add it to pubspec.yaml
// If you add it to pubspec.yaml, keep this line:
// import 'package:collection/collection.dart';

class VendorStatisticsScreen extends StatefulWidget {
  const VendorStatisticsScreen({super.key});

  @override
  State<VendorStatisticsScreen> createState() => _VendorStatisticsScreenState();
}

class _VendorStatisticsScreenState extends State<VendorStatisticsScreen> with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _weeklySales = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all products
      QuerySnapshot productsSnapshot = await _firestore
          .collection('products')
          .where('vendorId', isEqualTo: user?.uid)
          .get();
      
      int productCount = productsSnapshot.docs.length;
      
      // Get all orders
      QuerySnapshot ordersSnapshot = await _firestore
          .collection('orders')
          .where('vendorId', isEqualTo: user?.uid)
          .get();
      
      int totalOrders = ordersSnapshot.docs.length;
      double totalRevenue = 0;
      int pendingOrders = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      
      // Weekly sales data
      Map<String, double> weeklySalesMap = {};
      List<Map<String, dynamic>> productSalesList = []; // Fixed: Changed from Set to List
      
      for (var doc in ordersSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double amount = (data['amount'] ?? 0).toDouble();
        totalRevenue += amount;
        
        String status = data['status'] ?? data['orderStatus'] ?? 'pending';
        if (status == 'pending' || status == 'processing') {
          pendingOrders++;
        } else if (status == 'delivered' || status == 'completed') {
          completedOrders++;
        } else if (status == 'cancelled') {
          cancelledOrders++;
        }
        
        // Weekly sales
        Timestamp? timestamp = data['createdAt'] as Timestamp?;
        if (timestamp != null) {
          DateTime date = timestamp.toDate();
          String weekKey = DateFormat('yyyy-MM-dd').format(date);
          weeklySalesMap[weekKey] = (weeklySalesMap[weekKey] ?? 0) + amount;
        }
        
        // Product sales
        List items = data['items'] ?? [];
        for (var item in items) {
          String productName = item['name'] ?? 'Unknown Product';
          double itemPrice = (item['price'] ?? 0).toDouble();
          int quantity = item['quantity'] ?? 1;
          double total = itemPrice * quantity;
          
          // Manual find instead of using collection package
          var existingIndex = -1;
          for (var i = 0; i < productSalesList.length; i++) {
            if (productSalesList[i]['name'] == productName) {
              existingIndex = i;
              break;
            }
          }
          
          if (existingIndex != -1) {
            productSalesList[existingIndex]['sales'] = (productSalesList[existingIndex]['sales'] ?? 0) + total;
            productSalesList[existingIndex]['quantity'] = (productSalesList[existingIndex]['quantity'] ?? 0) + quantity;
          } else {
            productSalesList.add({
              'name': productName,
              'sales': total,
              'quantity': quantity,
              'imageUrl': item['imageUrl'] ?? '',
            });
          }
        }
      }
      
      // Sort products by sales
      productSalesList.sort((a, b) => (b['sales'] ?? 0).compareTo(a['sales'] ?? 0));
      _topProducts = productSalesList.take(5).toList();
      
      // Sort weekly sales
      var sortedWeekly = weeklySalesMap.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      _weeklySales = sortedWeekly.take(7).map((e) => {
        'date': e.key,
        'amount': e.value,
      }).toList();
      
      setState(() {
        _stats = {
          'productCount': productCount,
          'totalOrders': totalOrders,
          'totalRevenue': totalRevenue,
          'pendingOrders': pendingOrders,
          'completedOrders': completedOrders,
          'cancelledOrders': cancelledOrders,
          'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
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
          'Analytics Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Products'),
          ],
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
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildProductsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildSummaryCard(
                'Total Revenue',
                'Rs.${NumberFormat('#,###').format(_stats['totalRevenue'] ?? 0)}',
                Icons.trending_up,
                Colors.green.shade700,
                '${_calculateGrowth()}% growth',
              ),
              _buildSummaryCard(
                'Total Orders',
                '${_stats['totalOrders'] ?? 0}',
                Icons.shopping_cart,
                Colors.blue.shade700,
                '${_stats['completedOrders'] ?? 0} completed',
              ),
              _buildSummaryCard(
                'Pending Orders',
                '${_stats['pendingOrders'] ?? 0}',
                Icons.pending_actions,
                Colors.orange.shade700,
                'Need attention',
              ),
              _buildSummaryCard(
                'Avg Order Value',
                'Rs.${NumberFormat('#,###').format(_stats['averageOrderValue'] ?? 0)}',
                Icons.attach_money,
                const Color(0xFFF2845C),
                'Per order average',
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Weekly Sales Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
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
                      'Weekly Sales',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2845C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Last 7 Days',
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFFF2845C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildBarChart(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Performance Metrics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Metrics',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMetricRow(
                  'Order Completion Rate',
                  _calculateCompletionRate(),
                  _getCompletionRateProgress(),
                ),
                _buildMetricRow(
                  'Customer Satisfaction',
                  _calculateSatisfaction(),
                  _getSatisfactionProgress(),
                ),
                _buildMetricRow(
                  'Revenue Growth',
                  _calculateGrowth(),
                  _getGrowthProgress(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Products
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2845C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Color(0xFFF2845C),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Products',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${_stats['productCount'] ?? 0}',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to add product
                    Navigator.pushNamed(context, '/vendor/add-product');
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2845C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Top Products List
          Text(
            'Top Selling Products',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ..._topProducts.map((product) => _buildTopProduct(
            name: product['name'] ?? 'Unknown Product',
            sales: product['sales'] ?? 0.0,
            quantity: product['quantity'] ?? 0,
            imageUrl: product['imageUrl'] ?? '',
          )),
          
          if (_topProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    'No sales data yet',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    if (_weeklySales.isEmpty) {
      return Center(
        child: Text(
          'No sales data available',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    double maxAmount = _weeklySales.fold(0.0, (max, item) => 
      (item['amount'] ?? 0) > max ? (item['amount'] ?? 0) : max
    );
    maxAmount = maxAmount > 0 ? maxAmount * 1.2 : 1000;

    List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    Map<String, double> salesByDay = {};
    
    for (var sale in _weeklySales) {
      try {
        DateTime date = DateTime.parse(sale['date']!);
        String day = days[date.weekday - 1];
        salesByDay[day] = (salesByDay[day] ?? 0) + (sale['amount'] ?? 0.0);
      } catch (e) {
        // Skip invalid dates
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxAmount,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Rs.${NumberFormat('#,###').format(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String label = days[value.toInt()] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt() >= 1000 ? '${(value.toInt() / 1000).toStringAsFixed(0)}K' : value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            left: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        barGroups: days.map((day) {
          double amount = salesByDay[day] ?? 0;
          return BarChartGroupData(
            x: days.indexOf(day),
            barRods: [
              BarChartRodData(
                toY: amount,
                color: const Color(0xFFF2845C),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopProduct({required String name, required double sales, required int quantity, required String imageUrl}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFDEEE9),
              borderRadius: BorderRadius.circular(10),
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl.isEmpty
                ? const Icon(Icons.image, color: Color(0xFFF2845C), size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$quantity units sold',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rs.${NumberFormat('#,###').format(sales)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFF2845C),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF2845C), Color(0xFFFFB6A0)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for metrics
  String _calculateCompletionRate() {
    int total = (_stats['totalOrders'] ?? 0);
    int completed = (_stats['completedOrders'] ?? 0);
    if (total == 0) return '0%';
    return '${((completed / total) * 100).toStringAsFixed(1)}%';
  }

  double _getCompletionRateProgress() {
    int total = (_stats['totalOrders'] ?? 0);
    int completed = (_stats['completedOrders'] ?? 0);
    if (total == 0) return 0;
    return completed / total;
  }

  String _calculateSatisfaction() {
    // In real app, use reviews data from Firestore
    return '4.5 ★';
  }

  double _getSatisfactionProgress() {
    // In real app, calculate from reviews
    return 0.9;
  }

  String _calculateGrowth() {
    // In real app, compare with previous period
    return '12.5';
  }

  double _getGrowthProgress() {
    return 0.75;
  }
}