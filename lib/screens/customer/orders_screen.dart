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

  // REMOVED 'Placed' from filters - replaced with 'Pending'
  final List<String> _filters = ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        elevation: 0,
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
            color: Colors.white,
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
                    backgroundColor: Colors.grey[100],
                    selectedColor: const Color(0xFFFDEEE9),
                    checkmarkColor: const Color(0xFFF2845C),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFFF2845C) : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFF2845C) : Colors.transparent,
                      ),
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
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading orders',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please create the required Firestore index for orders.\n\nIndex: customerId (Ascending) + createdAt (Descending)',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2845C),
                            foregroundColor: Colors.white,
                          ),
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
                            fontWeight: FontWeight.w500,
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
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.shopping_bag),
                          label: const Text('Start Shopping'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2845C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                    final status = data['orderStatus'] ?? 'placed';
                    
                    // Map 'placed' to 'Pending' for display
                    String displayStatus = status == 'placed' ? 'Pending' : 
                        status.substring(0, 1).toUpperCase() + status.substring(1);
                    
                    return displayStatus == _selectedFilter;
                  }).toList();
                }

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list_off, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No $_selectedFilter orders',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
    // Convert status for display
    String displayStatus = status == 'placed' ? 'Pending' : 
        status.substring(0, 1).toUpperCase() + status.substring(1);
    
    double total = (data['total'] ?? 0).toDouble();
    int itemsCount = (data['items'] ?? []).length;
    Timestamp? createdAt = data['createdAt'] as Timestamp?;
    String deliveryMethod = data['deliveryLabel'] ?? 'Standard';
    String estimatedDelivery = data['estimatedDelivery'] ?? '';

    // Map status to config (using displayStatus for colors)
    Map<String, dynamic> statusConfig = _getStatusConfig(status);
    // Payment status - removed pending display
    Map<String, dynamic> paymentConfig = _getPaymentStatusConfig(data['paymentStatus'] ?? 'pending');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
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
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$itemsCount items • ${DateFormat('MMM d, yyyy').format(createdAt?.toDate() ?? DateTime.now())}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusConfig['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: statusConfig['color'],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Only show payment status if not pending
                if (data['paymentStatus'] != 'pending' && data['paymentStatus'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: paymentConfig['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
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
                if (deliveryMethod.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      deliveryMethod.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
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
            if (estimatedDelivery.isNotEmpty)
              Text(
                'Est: $estimatedDelivery',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
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
                const Text(
                  'Order Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF2D3A4B),
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Order ID', orderId),
                _buildDetailRow('Date', DateFormat('MMM d, yyyy • h:mm a').format(createdAt?.toDate() ?? DateTime.now())),
                _buildDetailRow('Status', displayStatus),
                // Only show payment if not pending
                if (data['paymentStatus'] != 'pending' && data['paymentStatus'] != null)
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
      default: // placed
        return {'color': Colors.grey, 'icon': Icons.pending, 'label': 'Pending'};
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
              color: Colors.grey[600],
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
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
                ? const Icon(Icons.image, color: Color(0xFFF2845C), size: 24)
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
                    color: Color(0xFF2D3A4B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Qty: ${item['quantity'] ?? 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
    List<Widget> actions = [];

    // Cancel button for pending/processing orders
    if (status == 'placed' || status == 'processing') {
      actions.add(
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
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }

    // Delete button for cancelled orders
    if (status == 'cancelled') {
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _deleteOrder(orderId),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete Order'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        const Divider(),
        Row(
          children: actions,
        ),
      ],
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    content: Text('Order cancelled successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                setState(() {});
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error cancelling order: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
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

  Future<void> _deleteOrder(String orderId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Order'),
        content: const Text('Are you sure you want to delete this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore.collection('orders').doc(orderId).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order deleted successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                setState(() {});
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting order: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}