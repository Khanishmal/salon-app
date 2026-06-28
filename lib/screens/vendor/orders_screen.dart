// lib/screens/vendor/vendor_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'All';
  
  final List<String> _filters = ['All', 'Pending', 'Processing', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Orders',
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
                    backgroundColor: Colors.grey.shade100,
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
                  .where('vendorId', isEqualTo: user?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
                        const SizedBox(height: 10),
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
                          'Orders will appear here once customers place them',
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

                // Apply filter
                if (_selectedFilter != 'All') {
                  orders = orders.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['status'] == _selectedFilter;
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
    String status = data['status'] ?? 'pending';
    String customerName = data['customerName'] ?? 'Customer';
    double amount = (data['amount'] ?? 0).toDouble();
    int items = (data['items'] ?? []).length;
    Timestamp? createdAt = data['createdAt'] as Timestamp?;
    String shippingStatus = data['shippingStatus'] ?? 'pending';

    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_top;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    Color shippingColor;
    String shippingLabel;
    
    switch (shippingStatus) {
      case 'delivered':
        shippingColor = Colors.green;
        shippingLabel = 'Delivered';
        break;
      case 'shipped':
        shippingColor = Colors.blue;
        shippingLabel = 'Shipped';
        break;
      case 'cancelled':
        shippingColor = Colors.red;
        shippingLabel = 'Cancelled';
        break;
      default:
        shippingColor = Colors.orange;
        shippingLabel = 'Processing';
    }

    String formattedDate = createdAt != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(createdAt.toDate())
        : 'No date';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(statusIcon, color: statusColor, size: 24),
        ),
        title: Text(
          'Order #${orderId.substring(0, 8)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3A4B),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$customerName • $items items',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: shippingColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    shippingLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: shippingColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          'Rs. ${NumberFormat('#,###').format(amount)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFF2845C),
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Details
                _buildDetailRow('Order ID', orderId),
                _buildDetailRow('Customer', customerName),
                _buildDetailRow('Date', formattedDate),
                _buildDetailRow('Total Amount', 'Rs. ${NumberFormat('#,###').format(amount)}'),
                _buildDetailRow('Items', items.toString()),
                _buildDetailRow('Status', status.toUpperCase()),
                _buildDetailRow('Shipping', shippingLabel),
                
                const SizedBox(height: 16),
                
                // Items List
                if (data['items'] != null && data['items'].isNotEmpty) ...[
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
                    (data['items'] as List).length,
                    (index) {
                      var item = data['items'][index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDEEE9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.image,
                                color: Color(0xFFF2845C),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'Product',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
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
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Action Buttons
                if (status == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateOrderStatus(orderId, 'processing'),
                          icon: const Icon(Icons.hourglass_top, size: 18),
                          label: const Text('Process'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateOrderStatus(orderId, 'cancelled'),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (status == 'processing') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateShippingStatus(orderId, 'shipped'),
                          icon: const Icon(Icons.local_shipping, size: 18),
                          label: const Text('Mark Shipped'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (status == 'shipped') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateOrderStatus(orderId, 'completed'),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Mark Completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order: $e')),
      );
    }
  }

  Future<void> _updateShippingStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'shippingStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shipping status updated to $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating shipping: $e')),
      );
    }
  }
}