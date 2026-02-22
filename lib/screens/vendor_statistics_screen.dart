import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Chart ke liye

class VendorStatisticsScreen extends StatefulWidget {
  const VendorStatisticsScreen({super.key});

  @override
  State<VendorStatisticsScreen> createState() => _VendorStatisticsScreenState();
}

class _VendorStatisticsScreenState extends State<VendorStatisticsScreen> {
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                _buildSummaryCard('Total Sales', 'Rs.45,200', Icons.trending_up,
                    Colors.green),
                const SizedBox(width: 15),
                _buildSummaryCard(
                    'Total Orders', '156', Icons.shopping_cart, Colors.blue),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildSummaryCard(
                    'Avg. Rating', '4.8 ⭐', Icons.star, Colors.amber),
                const SizedBox(width: 15),
                _buildSummaryCard(
                    'Products', '24', Icons.inventory, const Color(0xFFF2845C)),
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
            _buildTopProduct('Matte Lipstick', '42 sold', 'Rs.50,400'),
            _buildTopProduct('Foundation', '28 sold', 'Rs.70,000'),
            _buildTopProduct('Eyeliner', '56 sold', 'Rs.44,800'),
            _buildTopProduct('Face Cream', '35 sold', 'Rs.63,000'),
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

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
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
            BarChartRodData(
                toY: 5000, color: const Color(0xFFF2845C), width: 15)
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(
                toY: 7000, color: const Color(0xFFF2845C), width: 15)
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(
                toY: 4500, color: const Color(0xFFF2845C), width: 15)
          ]),
          BarChartGroupData(x: 3, barRods: [
            BarChartRodData(
                toY: 8000, color: const Color(0xFFF2845C), width: 15)
          ]),
          BarChartGroupData(x: 4, barRods: [
            BarChartRodData(
                toY: 6500, color: const Color(0xFFF2845C), width: 15)
          ]),
          BarChartGroupData(x: 5, barRods: [
            BarChartRodData(
                toY: 9000, color: const Color(0xFFF2845C), width: 15)
          ]),
          BarChartGroupData(x: 6, barRods: [
            BarChartRodData(
                toY: 7500, color: const Color(0xFFF2845C), width: 15)
          ]),
        ],
      ),
    );
  }

  Widget _buildTopProduct(String name, String sales, String revenue) {
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
                Text(sales,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
