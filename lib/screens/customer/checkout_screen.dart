import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'orders_screen.dart'; // Import orders screen
import 'product_shop.dart';

class CheckoutScreen extends StatefulWidget {
  final double total;
  final List items;

  const CheckoutScreen({
    super.key,
    required this.total,
    required this.items,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  
  // Customer Info
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // Address
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  
  // Delivery
  String _deliveryMethod = 'standard';
  String _paymentMethod = 'cod';
  String _orderNotes = '';
  
  // Delivery Charges
  double _deliveryCharge = 150;
  double _subtotal = 0;
  double _totalAmount = 0;
  bool _isPlacingOrder = false;

  final Map<String, dynamic> _deliveryMethods = {
    'standard': {'label': 'Standard Delivery', 'days': '3-5 days', 'charge': 150},
    'express': {'label': 'Express Delivery', 'days': '1-2 days', 'charge': 350},
    'pickup': {'label': 'Store Pickup', 'days': 'Free', 'charge': 0},
  };

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'cod', 'name': 'Cash on Delivery', 'icon': Icons.money, 'color': Colors.green},
    {'id': 'jazzcash', 'name': 'JazzCash', 'icon': Icons.account_balance_wallet, 'color': Colors.orange},
    {'id': 'easypaisa', 'name': 'EasyPaisa', 'icon': Icons.account_balance_wallet, 'color': Colors.blue},
    {'id': 'bank_transfer', 'name': 'Bank Transfer', 'icon': Icons.account_balance, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _calculateTotal();
    _loadUserData();
  }

  void _calculateTotal() {
    _subtotal = widget.total;
    _totalAmount = _subtotal + _deliveryCharge;
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _fullNameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _updateDeliveryCharge() {
    setState(() {
      _deliveryCharge = _deliveryMethods[_deliveryMethod]?['charge'] ?? 0;
      _totalAmount = _subtotal + _deliveryCharge;
    });
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isPlacingOrder) return;
    
    setState(() => _isPlacingOrder = true);

    try {
      // Get vendor ID from first item
      String? vendorId;
      if (widget.items.isNotEmpty && widget.items[0]['vendorId'] != null) {
        vendorId = widget.items[0]['vendorId'];
      }

      final orderData = {
        'customerId': user?.uid,
        'customerName': _fullNameController.text.trim(),
        'customerPhone': _phoneController.text.trim(),
        'customerEmail': _emailController.text.trim(),
        'shippingAddress': _addressController.text.trim(),
        'shippingCity': _cityController.text.trim(),
        'shippingState': _stateController.text.trim(),
        'shippingZipCode': _zipCodeController.text.trim(),
        'items': widget.items,
        'subtotal': _subtotal,
        'deliveryCharge': _deliveryCharge,
        'total': _totalAmount,
        'deliveryMethod': _deliveryMethod,
        'deliveryLabel': _deliveryMethods[_deliveryMethod]?['label'],
        'deliveryDays': _deliveryMethods[_deliveryMethod]?['days'],
        'paymentMethod': _paymentMethod,
        'paymentStatus': 'pending',
        'orderStatus': 'placed',
        'vendorId': vendorId ?? '',
        'orderNotes': _orderNotes.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'estimatedDelivery': _getEstimatedDeliveryDate(),
      };

      await _firestore.collection('orders').add(orderData);

      // Clear cart
      await _firestore.collection('carts').doc(user?.uid).delete();

      // Show success dialog
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        _showOrderSuccessDialog();
      }
      
    } catch (e) {
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getEstimatedDeliveryDate() {
    final now = DateTime.now();
    final days = _deliveryMethods[_deliveryMethod]?['days'] ?? '3-5 days';
    if (days == 'Free') return 'Store Pickup Available';
    
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(days);
    if (match != null) {
      final maxDays = int.parse(match.group(0)!);
      final deliveryDate = now.add(Duration(days: maxDays));
      return DateFormat('MMM d, yyyy').format(deliveryDate);
    }
    return 'Within 3-5 days';
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Order Placed!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your order has been placed successfully.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEEE9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order Total:'),
                      Text(
                        'Rs. ${NumberFormat('#,###').format(_totalAmount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF2845C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status:'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PENDING',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery:'),
                      Text(_deliveryMethods[_deliveryMethod]?['label'] ?? 'Standard'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Delivery:'),
                      Text(
                        _getEstimatedDeliveryDate(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The vendor will confirm your order soon.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Navigate to Orders Screen instead of going back to cart
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const CustomerOrdersScreen()),
                (route) => false,
              );
            },
            child: const Text('View My Orders'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Navigate to Shop
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const ProductShopScreen()),
                (route) => false,
              );
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3A4B),
                        ),
                      ),
                      const Divider(),
                      ...widget.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item['name']} x${item['quantity']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              'Rs. ${NumberFormat('#,###').format((item['price'] * item['quantity']))}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )),
                      const Divider(),
                      _buildPriceRow('Subtotal', _subtotal),
                      _buildPriceRow(
                        'Delivery',
                        _deliveryCharge,
                        subtitle: _deliveryMethods[_deliveryMethod]?['label'],
                      ),
                      const Divider(),
                      _buildPriceRow(
                        'Total',
                        _totalAmount,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Delivery Method
              const Text(
                'Delivery Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3A4B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _deliveryMethods.keys.map((key) {
                  var method = _deliveryMethods[key];
                  bool isSelected = _deliveryMethod == key;
                  return FilterChip(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(method['label']),
                        Text(
                          method['charge'] == 0 ? 'Free' : 'Rs. ${method['charge']}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? const Color(0xFFF2845C) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _deliveryMethod = key;
                        _updateDeliveryCharge();
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFFDEEE9),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Customer Information
              const Text(
                'Customer Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3A4B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter your full name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFF2845C)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '03XX-XXXXXXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFFF2845C)),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFF2845C)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Shipping Address
              const Text(
                'Shipping Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3A4B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Delivery Address *',
                  hintText: 'House #, Street, Area',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFFF2845C)),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter delivery address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City *',
                        hintText: 'Enter city',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.location_city, color: Color(0xFFF2845C)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        hintText: 'Enter state',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.map, color: Color(0xFFF2845C)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _zipCodeController,
                decoration: InputDecoration(
                  labelText: 'Zip Code',
                  hintText: 'Enter zip code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.code, color: Color(0xFFF2845C)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Payment Method
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3A4B),
                ),
              ),
              const SizedBox(height: 8),
              ..._paymentMethods.map((method) => 
                _buildPaymentOption(method)
              ).toList(),
              const SizedBox(height: 16),

              // Order Notes
              TextField(
                controller: TextEditingController(text: _orderNotes),
                decoration: InputDecoration(
                  labelText: 'Order Notes (Optional)',
                  hintText: 'Special instructions for delivery...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.note_outlined, color: Color(0xFFF2845C)),
                ),
                maxLines: 2,
                onChanged: (value) {
                  _orderNotes = value;
                },
              ),
              const SizedBox(height: 24),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2845C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isPlacingOrder
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Place Order - Rs. ${NumberFormat('#,###').format(_totalAmount)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {String? subtitle, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 16 : 14,
                  color: isTotal ? const Color(0xFF2D3A4B) : Colors.grey.shade700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
          Text(
            'Rs. ${NumberFormat('#,###').format(amount)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? const Color(0xFFF2845C) : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(Map<String, dynamic> method) {
    bool isSelected = _paymentMethod == method['id'];
    return GestureDetector(
      onTap: () {
        setState(() => _paymentMethod = method['id']);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFDEEE9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFF2845C) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              method['icon'],
              color: isSelected ? const Color(0xFFF2845C) : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method['name'],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFFF2845C) : Colors.grey.shade700,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFF2845C), size: 20),
          ],
        ),
      ),
    );
  }
}