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
  bool _isLoading = true;
  
  final List<String> _filters = ['All', 'Pending', 'Processing', 'Shipped', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _checkOrders();
  }

  Future<void> _checkOrders() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('vendorId', isEqualTo: user?.uid)
          .limit(1)
          .get();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
        ],
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2845C)),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('orders')
                        .where('vendorId', isEqualTo: user?.uid)
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
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'Please create the required Firestore index for orders.\n\nIndex: vendorId (Ascending) + createdAt (Descending)',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.filter_list_off, size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'No $_selectedFilter orders',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[500],
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
    String status = data['status'] ?? 'pending';
    String customerName = data['customerName'] ?? 'Customer';
    String customerEmail = data['customerEmail'] ?? '';
    double amount = (data['amount'] ?? 0).toDouble();
    int items = (data['items'] ?? []).length;
    Timestamp? createdAt = data['createdAt'] as Timestamp?;
    String shippingStatus = data['shippingStatus'] ?? 'pending';
    String shippingAddress = data['shippingAddress'] ?? 'No address provided';

    // Status colors and icons
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
      case 'shipped':
        statusColor = Colors.purple;
        statusIcon = Icons.local_shipping;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    // Shipping status colors
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Rs. ${NumberFormat('#,###').format(amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFF2845C),
                fontSize: 16,
              ),
            ),
            Text(
              formattedDate,
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
                // Customer Info
                _buildSectionHeader('Customer Information'),
                const SizedBox(height: 8),
                _buildDetailRow('Name', customerName),
                if (customerEmail.isNotEmpty)
                  _buildDetailRow('Email', customerEmail),
                _buildDetailRow('Order ID', orderId),
                _buildDetailRow('Date', formattedDate),
                _buildDetailRow('Total Amount', 'Rs. ${NumberFormat('#,###').format(amount)}'),
                _buildDetailRow('Items', items.toString()),
                _buildDetailRow('Status', status.toUpperCase()),
                _buildDetailRow('Shipping', shippingLabel),
                
                const SizedBox(height: 8),
                _buildSectionHeader('Shipping Address'),
                const SizedBox(height: 4),
                Text(
                  shippingAddress,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 16),
                _buildSectionHeader('Order Items'),
                const SizedBox(height: 8),
                
                if (data['items'] != null && data['items'].isNotEmpty)
                  ...List.generate(
                    (data['items'] as List).length,
                    (index) {
                      var item = data['items'][index];
                      return _buildOrderItemWidget(item);
                    },
                  ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                _buildActionButtons(orderId, status, shippingStatus),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Color(0xFF2D3A4B),
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2D3A4B),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemWidget(Map<String, dynamic> item) {
    String name = item['name'] ?? 'Product';
    int quantity = item['quantity'] ?? 1;
    double price = (item['price'] ?? 0).toDouble();
    String? imageUrl = item['imageUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
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
              image: imageUrl != null && imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null || imageUrl.isEmpty
                ? const Icon(
                    Icons.image,
                    color: Color(0xFFF2845C),
                    size: 24,
                  )
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
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Qty: $quantity',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rs. ${NumberFormat('#,###').format(price * quantity)}',
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

  Widget _buildActionButtons(String orderId, String status, String shippingStatus) {
    List<Widget> buttons = [];

    if (status == 'pending') {
      buttons.addAll([
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _updateOrderStatus(orderId, 'processing'),
            icon: const Icon(Icons.hourglass_top, size: 18),
            label: const Text('Process Order'),
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
      ]);
    }

    if (status == 'processing') {
      buttons.addAll([
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _updateShippingStatus(orderId, 'shipped'),
            icon: const Icon(Icons.local_shipping, size: 18),
            label: const Text('Mark Shipped'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
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
      ]);
    }

    if (status == 'shipped') {
      buttons.addAll([
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
      ]);
    }

    if (status == 'completed' || status == 'cancelled') {
      return const SizedBox();
    }

    return Column(
      children: [
        const Divider(),
        Row(
          children: buttons,
        ),
      ],
    );
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $status'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateShippingStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'shippingStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shipping status updated to $status'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating shipping: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}