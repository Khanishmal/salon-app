// lib/screens/customer/customer_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Placed', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFFDEEE9),
                    checkmarkColor: const Color(0xFFF2845C),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFFF2845C) : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('orders')
                  .where('customerId', isEqualTo: user?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2845C)),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
                        const SizedBox(height: 8),
                        const Text('Error loading orders'),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
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
                        Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No Orders Yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start shopping to place your first order',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var orders = snapshot.data!.docs;

                if (_selectedFilter != 'All') {
                  orders = orders.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['orderStatus'] == _selectedFilter.toLowerCase();
                  }).toList();
                }

                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      'No $_selectedFilter orders',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var doc = orders[index];
                    var data = doc.data() as Map<String, dynamic>;
                    return _buildOrderCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> data) {
    String status = data['orderStatus'] ?? 'placed';
    String paymentStatus = data['paymentStatus'] ?? 'pending';
    double total = (data['total'] ?? 0).toDouble();
    int itemsCount = (data['items'] ?? []).length;
    Timestamp? createdAt = data['createdAt'] as Timestamp?;
    String deliveryMethod = data['deliveryLabel'] ?? 'Standard';
    String estimatedDelivery = data['estimatedDelivery'] ?? '';

    Map<String, dynamic> statusConfig = _getStatusConfig(status);
    Map<String, dynamic> paymentConfig = _getPaymentStatusConfig(paymentStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusConfig['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            statusConfig['icon'],
            color: statusConfig['color'],
            size: 24,
          ),
        ),
        title: Text(
          'Order #${orderId.substring(0, 8).toUpperCase()}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3A4B),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$itemsCount items • ${DateFormat('MMM d, yyyy').format(createdAt?.toDate() ?? DateTime.now())}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusConfig['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: statusConfig['color'],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: paymentConfig['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    paymentConfig['label'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: paymentConfig['color'],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Rs. ${NumberFormat('#,###').format(total)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFF2845C),
                fontSize: 16,
              ),
            ),
            Text(
              deliveryMethod,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Details
                _buildDetailRow('Order ID', orderId),
                _buildDetailRow('Date', DateFormat('MMM d, yyyy • h:mm a').format(createdAt?.toDate() ?? DateTime.now())),
                _buildDetailRow('Status', status.toUpperCase()),
                _buildDetailRow('Payment', paymentConfig['label']),
                _buildDetailRow('Delivery', deliveryMethod),
                if (estimatedDelivery.isNotEmpty)
                  _buildDetailRow('Estimated Delivery', estimatedDelivery),
                _buildDetailRow('Total', 'Rs. ${NumberFormat('#,###').format(total)}'),
                
                const SizedBox(height: 16),
                const Text(
                  'Order Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2D3A4B),
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  (data['items'] ?? []).length,
                  (index) {
                    var item = data['items'][index];
                    return _buildOrderItem(item);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Order Actions
                if (status == 'placed' || status == 'processing')
                  _buildOrderActions(orderId, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'delivered':
        return {'color': Colors.green, 'icon': Icons.check_circle, 'label': 'Delivered'};
      case 'shipped':
        return {'color': Colors.blue, 'icon': Icons.local_shipping, 'label': 'Shipped'};
      case 'processing':
        return {'color': Colors.orange, 'icon': Icons.hourglass_top, 'label': 'Processing'};
      case 'cancelled':
        return {'color': Colors.red, 'icon': Icons.cancel, 'label': 'Cancelled'};
      default:
        return {'color': Colors.grey, 'icon': Icons.pending, 'label': 'Placed'};
    }
  }

  Map<String, dynamic> _getPaymentStatusConfig(String status) {
    switch (status) {
      case 'completed':
        return {'color': Colors.green, 'label': 'Paid'};
      case 'failed':
        return {'color': Colors.red, 'label': 'Failed'};
      default:
        return {'color': Colors.orange, 'label': 'Pending'};
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2D3A4B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFDEEE9),
              borderRadius: BorderRadius.circular(8),
              image: item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(item['imageUrl']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item['imageUrl'] == null || item['imageUrl'].toString().isEmpty
                ? const Icon(Icons.image, color: Color(0xFFF2845C))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Qty: ${item['quantity'] ?? 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rs. ${NumberFormat('#,###').format((item['price'] ?? 0) * (item['quantity'] ?? 1))}',
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

  Widget _buildOrderActions(String orderId, String status) {
    return Column(
      children: [
        const Divider(),
        Row(
          children: [
            if (status == 'placed') ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancelOrder(orderId),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Cancel Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore.collection('orders').doc(orderId).update({
                  'orderStatus': 'cancelled',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order cancelled'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error cancelling order: ${e.toString()}')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}