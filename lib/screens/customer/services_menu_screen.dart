// lib/screens/customer/services_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ServicesMenuScreen extends StatefulWidget {
  const ServicesMenuScreen({super.key});

  @override
  State<ServicesMenuScreen> createState() => _ServicesMenuScreenState();
}

class _ServicesMenuScreenState extends State<ServicesMenuScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoadingCart = false;

  final List<String> _categories = [
    'All',
    'Hair',
    'Makeup',
    'Nails',
    'Spa',
    'Facial',
    'Bridal',
  ];

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCartItems() async {
    if (user == null) return;
    
    setState(() => _isLoadingCart = true);
    
    try {
      // Get all pending bookings for the customer
      QuerySnapshot snapshot = await _firestore
          .collection('service_bookings')
          .where('customerId', isEqualTo: user!.uid)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();
      
      setState(() {
        _cartItems = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'serviceName': data['serviceName'] ?? 'Service',
            'servicePrice': data['servicePrice'] ?? 0,
            'bookingDate': data['bookingDate'] as Timestamp?,
            'bookingTime': data['bookingTime'] ?? '',
            'status': data['status'] ?? 'pending',
          };
        }).toList();
        _isLoadingCart = false;
      });
    } catch (e) {
      print('Error loading cart items: $e');
      setState(() => _isLoadingCart = false);
    }
  }

  Future<void> _removeFromCart(String bookingId) async {
    try {
      // Update the booking status to 'cancelled' instead of deleting
      await _firestore.collection('service_bookings').doc(bookingId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Refresh cart
      await _loadCartItems();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service removed from cart'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing service: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FA);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Our Services',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFFE28766),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Cart Icon with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  _showCartDialog();
                },
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _cartItems.length > 9 ? '9+' : _cartItems.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFE28766), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),
          ),
          // Categories
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category, style: TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
                    selectedColor: const Color(0xFFFDEEE9),
                    checkmarkColor: const Color(0xFFE28766),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFFE28766) : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          // Services Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('services')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE28766)),
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
                        Text(
                          'Error loading services',
                          style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black),
                        ),
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
                        Icon(Icons.spa_outlined, size: 60, color: isDarkMode ? Colors.grey[600] : Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No Services Available',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new services',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var services = snapshot.data!.docs;

                if (_selectedCategory != 'All') {
                  services = services.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String category = data['category'] ?? '';
                    return category.toLowerCase() == _selectedCategory.toLowerCase();
                  }).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  services = services.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String name = (data['name'] ?? '').toString().toLowerCase();
                    String category = (data['category'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) || category.contains(_searchQuery);
                  }).toList();
                }

                if (services.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 40, color: isDarkMode ? Colors.grey[500] : Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No services found',
                          style: GoogleFonts.poppins(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 3,
                    childAspectRatio: isMobile ? 0.7 : 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    var doc = services[index];
                    var data = doc.data() as Map<String, dynamic>;
                    // Check if service is already in cart
                    bool isInCart = _cartItems.any((item) => item['serviceName'] == data['name']);
                    return _buildServiceCard(doc.id, data, isDarkMode, isMobile, isInCart);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String serviceId, Map<String, dynamic> data, bool isDarkMode, bool isMobile, bool isInCart) {
    String name = data['name'] ?? 'Service';
    double price = (data['price'] ?? 0).toDouble();
    int duration = data['duration'] ?? 60;
    String imageUrl = data['imageUrl'] ?? '';
    String category = data['category'] ?? '';
    double rating = (data['rating'] ?? 0).toDouble();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(serviceId: serviceId),
          ),
        ).then((_) => _loadCartItems()); // Refresh cart when returning
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isInCart ? Border.all(color: const Color(0xFFE28766), width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Section with Cart Indicator
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDEEE9),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: imageUrl.isNotEmpty
                        ? (imageUrl.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFFFDEEE9),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE28766)),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(0xFFFDEEE9),
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported, size: 40, color: Color(0xFFE28766)),
                                  ),
                                ),
                              )
                            : Image.asset(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFFFDEEE9),
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported, size: 40, color: Color(0xFFE28766)),
                                  ),
                                ),
                              ))
                        : const Center(
                            child: Icon(Icons.spa, size: 40, color: Color(0xFFE28766)),
                          ),
                  ),
                  // Cart Indicator Badge
                  if (isInCart)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE28766),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            const Text(
                              'In Cart',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 12 : 14,
                            color: isDarkMode ? Colors.white : const Color(0xFF2D3A4B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Rs. ${NumberFormat('#,###').format(price)}',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFE28766),
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                            ),
                            if (category.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE28766).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  category,
                                  style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    color: const Color(0xFFE28766),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: isMobile ? 10 : 12, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '$duration min',
                              style: TextStyle(
                                fontSize: isMobile ? 9 : 10,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Icon(Icons.star, size: isMobile ? 10 : 12, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: isMobile ? 9 : 10,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isInCart ? null : () {
                              _addToCart(serviceId, data);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInCart ? Colors.green : const Color(0xFFE28766),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              isInCart ? 'Added ✓' : 'Book Now',
                              style: TextStyle(
                                fontSize: isMobile ? 10 : 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(String serviceId, Map<String, dynamic> serviceData) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to book services'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to booking screen or show booking dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailScreen(serviceId: serviceId),
      ),
    ).then((_) => _loadCartItems());
  }

  void _showCartDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF1E1E24) 
                  : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart, color: Color(0xFFE28766)),
                          const SizedBox(width: 8),
                          Text(
                            'My Bookings',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white 
                                  : const Color(0xFF2D3A4B),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : Colors.grey[700],
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                if (_isLoadingCart)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE28766)),
                      ),
                    ),
                  )
                else if (_cartItems.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No bookings yet',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Browse services and book your first appointment',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE28766),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Browse Services'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        var item = _cartItems[index];
                        return _buildCartItem(item);
                      },
                    ),
                  ),
                // Footer with total
                if (_cartItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Bookings',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${_cartItems.length} services',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : const Color(0xFF2D3A4B),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to booking calendar or show all bookings
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE28766),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final status = item['status'] ?? 'pending';
    final statusColor = status == 'pending' ? Colors.orange : Colors.blue;
    final statusLabel = status == 'pending' ? 'Pending' : 'Confirmed';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFDEEE9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.spa,
                color: Color(0xFFE28766),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['serviceName'] ?? 'Service',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : const Color(0xFF2D3A4B),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      item['bookingDate'] != null 
                          ? DateFormat('MMM d, yyyy').format((item['bookingDate'] as Timestamp).toDate())
                          : 'No date',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      item['bookingTime'] ?? 'No time',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rs. ${NumberFormat('#,###').format(item['servicePrice'] ?? 0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFE28766),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red[400], size: 20),
            onPressed: () => _removeFromCart(item['id']),
            tooltip: 'Cancel booking',
          ),
        ],
      ),
    );
  }
}

// --- SERVICE DETAIL SCREEN ---
class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _serviceData;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  Future<void> _loadService() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      DocumentSnapshot doc = await _firestore.collection('services').doc(widget.serviceId).get();
      if (doc.exists) {
        setState(() {
          _serviceData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      print('Error loading service: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _bookService() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('service_bookings').add({
        'serviceId': widget.serviceId,
        'customerId': user?.uid,
        'customerName': user?.displayName ?? 'Customer',
        'customerEmail': user?.email ?? '',
        'serviceName': _serviceData!['name'],
        'servicePrice': _serviceData!['price'],
        'serviceDuration': _serviceData!['duration'],
        'bookingDate': Timestamp.fromDate(_selectedDate!),
        'bookingTime': _selectedTime!.format(context),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service booked successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to indicate booking was made
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FA);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2D3A4B);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFFE28766),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE28766)),
          ),
        ),
      );
    }

    if (_hasError || _serviceData == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text('Service Not Found'),
          backgroundColor: const Color(0xFFE28766),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Service not found',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The service you are looking for does not exist',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE28766),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    String name = _serviceData!['name'] ?? 'Service';
    String description = _serviceData!['description'] ?? '';
    double price = (_serviceData!['price'] ?? 0).toDouble();
    int duration = _serviceData!['duration'] ?? 60;
    String imageUrl = _serviceData!['imageUrl'] ?? '';
    String category = _serviceData!['category'] ?? '';
    double rating = (_serviceData!['rating'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          name,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFFE28766),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 220,
              width: double.infinity,
              color: const Color(0xFFFDEEE9),
              child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE28766)),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.spa, size: 60, color: Colors.grey),
                      ),
                    )
                  : imageUrl.isNotEmpty
                      ? Image.asset(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.spa, size: 60, color: Colors.grey),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.spa, size: 60, color: Colors.grey),
                        ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      Text(
                        'Rs. ${NumberFormat('#,###').format(price)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE28766),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE28766).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFE28766),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$duration min',
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.amber.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Book This Service',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Date Picker
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null && mounted) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFFE28766)),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate != null
                                ? DateFormat('MMM d, yyyy').format(_selectedDate!)
                                : 'Select Date',
                            style: TextStyle(
                              color: _selectedDate != null ? textColor : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Time Picker
                  GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null && mounted) {
                        setState(() => _selectedTime = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFFE28766)),
                          const SizedBox(width: 12),
                          Text(
                            _selectedTime != null ? _selectedTime!.format(context) : 'Select Time',
                            style: TextStyle(
                              color: _selectedTime != null ? textColor : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _bookService,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE28766),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}