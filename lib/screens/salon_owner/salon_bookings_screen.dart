// lib/screens/salon_owner/salon_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SalonBookingsScreen extends StatefulWidget {
  const SalonBookingsScreen({super.key});

  @override
  State<SalonBookingsScreen> createState() => _SalonBookingsScreenState();
}

class _SalonBookingsScreenState extends State<SalonBookingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'All';
  String _selectedDateFilter = 'All'; // All, Today, This Week, This Month

  Color get _accentColor => const Color(0xFFE28766);
  Color get _primaryTextColor => Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1A1A1A);
  Color get _secondaryTextColor => Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _cardColor => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _borderColor => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D2D2D) : const Color(0xFFEAE6DF);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDarkMode
              ? [
                  const Color(0xFF0D0D0D),
                  const Color(0xFF1A0A0A),
                ]
              : [
                  const Color(0xFFFAF9F6),
                  const Color(0xFFFFF5F0),
                ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-Time Bookings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _primaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Live customer bookings and appointments',
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            // Filter Chips - Status
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('All', 'All', isDarkMode),
                  _buildFilterChip('Pending', 'pending', isDarkMode),
                  _buildFilterChip('Confirmed', 'confirmed', isDarkMode),
                  _buildFilterChip('Completed', 'completed', isDarkMode),
                  _buildFilterChip('Cancelled', 'cancelled', isDarkMode),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Date Filter Chips
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildDateFilterChip('All', 'All', isDarkMode),
                  _buildDateFilterChip('Today', 'Today', isDarkMode),
                  _buildDateFilterChip('This Week', 'ThisWeek', isDarkMode),
                  _buildDateFilterChip('This Month', 'ThisMonth', isDarkMode),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('service_bookings') // FIXED: Use correct collection name
                    .orderBy('createdAt', descending: true)
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
                          const SizedBox(height: 10),
                          Text(
                            'Error loading bookings: ${snapshot.error}',
                            style: TextStyle(color: _secondaryTextColor),
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
                          Icon(
                            Icons.calendar_today,
                            size: 60,
                            color: _secondaryTextColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No bookings yet',
                            style: TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bookings will appear here in real-time',
                            style: TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  var bookings = snapshot.data!.docs;

                  // Filter by status
                  if (_selectedFilter != 'All') {
                    bookings = bookings.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return data['status'] == _selectedFilter;
                    }).toList();
                  }

                  // Filter by date
                  if (_selectedDateFilter != 'All') {
                    final now = DateTime.now();
                    bookings = bookings.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      final bookingDate = data['bookingDate'] as Timestamp?;
                      if (bookingDate == null) return false;
                      final date = bookingDate.toDate();
                      
                      switch (_selectedDateFilter) {
                        case 'Today':
                          return date.year == now.year && 
                                 date.month == now.month && 
                                 date.day == now.day;
                        case 'ThisWeek':
                          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                          final endOfWeek = startOfWeek.add(const Duration(days: 7));
                          return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
                        case 'ThisMonth':
                          return date.year == now.year && date.month == now.month;
                        default:
                          return true;
                      }
                    }).toList();
                  }

                  if (bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_alt_off, size: 40, color: _secondaryTextColor),
                          const SizedBox(height: 8),
                          Text(
                            'No ${_selectedFilter != 'All' ? _selectedFilter : ''} bookings',
                            style: TextStyle(color: _secondaryTextColor),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      var doc = bookings[index];
                      var data = doc.data() as Map<String, dynamic>;
                      return _buildBookingCard(doc.id, data, isDarkMode);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDarkMode) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedFilter = value);
        },
        backgroundColor: _cardColor,
        selectedColor: _accentColor.withOpacity(0.15),
        labelStyle: TextStyle(
          color: isSelected ? _accentColor : _secondaryTextColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? _accentColor : _borderColor,
            width: 1,
          ),
        ),
        checkmarkColor: _accentColor,
      ),
    );
  }

  Widget _buildDateFilterChip(String label, String value, bool isDarkMode) {
    final isSelected = _selectedDateFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedDateFilter = value);
        },
        backgroundColor: _cardColor,
        selectedColor: _accentColor.withOpacity(0.1),
        labelStyle: TextStyle(
          color: isSelected ? _accentColor : _secondaryTextColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 11,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? _accentColor : _borderColor,
            width: 0.5,
          ),
        ),
        checkmarkColor: _accentColor,
      ),
    );
  }

  Widget _buildBookingCard(String bookingId, Map<String, dynamic> data, bool isDarkMode) {
    final status = data['status'] ?? 'pending';
    final statusColor = status == 'pending' ? Colors.orange :
                        status == 'confirmed' ? Colors.blue :
                        status == 'completed' ? Colors.green :
                        Colors.red;
    
    final statusLabel = status == 'pending' ? 'Pending' :
                        status == 'confirmed' ? 'Confirmed' :
                        status == 'completed' ? 'Completed' :
                        'Cancelled';

    // Use bookingDate instead of date
    final bookingDate = data['bookingDate'] as Timestamp?;
    final dateTime = bookingDate?.toDate();
    final formattedDate = dateTime != null 
        ? DateFormat('MMM d, yyyy').format(dateTime)
        : 'No date';

    return Card(
      color: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _borderColor),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _accentColor.withOpacity(0.1),
                  radius: 18,
                  child: Text(
                    (data['customerName'] ?? 'C')[0].toUpperCase(),
                    style: TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['customerName'] ?? 'Customer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        data['serviceName'] ?? 'Service',
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: _secondaryTextColor),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: _secondaryTextColor),
                const SizedBox(width: 4),
                Text(
                  data['bookingTime'] ?? '10:00',
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.attach_money, size: 14, color: _secondaryTextColor),
                const SizedBox(width: 4),
                Text(
                  'Rs. ${data['servicePrice'] ?? 0}',
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  onPressed: () => _confirmDeleteBooking(bookingId),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                if (status == 'pending') ...[
                  OutlinedButton(
                    onPressed: () {
                      _firestore
                          .collection('service_bookings')
                          .doc(bookingId)
                          .update({'status': 'confirmed'});
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Confirm', style: TextStyle(color: Colors.blue, fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                ],
                if (status == 'confirmed') ...[
                  OutlinedButton(
                    onPressed: () {
                      _firestore
                          .collection('service_bookings')
                          .doc(bookingId)
                          .update({'status': 'completed'});
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Complete', style: TextStyle(color: Colors.green, fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                ],
                if (status == 'pending' || status == 'confirmed') ...[
                  OutlinedButton(
                    onPressed: () {
                      _firestore
                          .collection('service_bookings')
                          .doc(bookingId)
                          .update({'status': 'cancelled'});
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 11)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBooking(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Delete Booking'),
        content: const Text('Are you sure you want to delete this booking? This will also remove it from the customer\'s view.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore.collection('service_bookings').doc(bookingId).delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting booking: ${e.toString()}')),
                  );
                }
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