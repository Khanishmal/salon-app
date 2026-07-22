// lib/screens/customer/booking_calendar.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingCalendarScreen extends StatefulWidget {
  const BookingCalendarScreen({super.key});

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedServiceId = '';
  TimeOfDay? _selectedTime;
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _bookedSlots = [];
  List<Map<String, dynamic>> _customerBookings = [];
  bool _isLoading = true;
  String _salonOpenTime = '09:00';
  String _salonCloseTime = '21:00';
  bool _showMyBookings = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadWorkingHours(),
      _loadServices(),
      _loadCustomerBookings(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadWorkingHours() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('settings')
          .doc('salon_settings')
          .get();
      
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _salonOpenTime = data['openTime'] ?? '09:00';
          _salonCloseTime = data['closeTime'] ?? '21:00';
        });
      }
    } catch (e) {
      print('Error loading working hours: $e');
    }
  }

  // Replace the _loadServices method in booking_calendar.dart with this:

Future<void> _loadServices() async {
  try {
    // FIXED: Query from 'services' collection, not 'service_bookings'
    QuerySnapshot snapshot = await _firestore
        .collection('services')
        .where('isActive', isEqualTo: true)
        .get();
    
    setState(() {
      _services = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Service',
          'price': data['price'] ?? 0,
          'duration': data['duration'] ?? 60,
          'category': data['category'] ?? '',
          'description': data['description'] ?? '',
        };
      }).toList();
    });
  } catch (e) {
    print('Error loading services: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading services: ${e.toString()}')),
    );
  }
}

  Future<void> _loadCustomerBookings() async {
    if (user == null) return;
    try {
      QuerySnapshot snapshot = await _firestore
    .collection('service_bookings')
    .where('customerId', isEqualTo: user!.uid)
    // Remove this line to avoid index requirement:
    // .orderBy('createdAt', descending: true)
    .get();
      
      print('Bookings found: ${snapshot.docs.length}'); // Debug log
      
      setState(() {
        _customerBookings = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          Timestamp? bookingDate = data['bookingDate'] as Timestamp?;
          return {
            'id': doc.id,
            'serviceName': data['serviceName'] ?? 'Service',
            'bookingDate': bookingDate,
            'bookingTime': data['bookingTime'] ?? 'N/A',
            'status': data['status'] ?? 'pending',
            'servicePrice': data['servicePrice'] ?? 0,
            'bookingDateFormatted': bookingDate != null 
                ? DateFormat('MMM d, yyyy').format(bookingDate.toDate())
                : 'Date not set',
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading customer bookings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bookings: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadBookedSlots(DateTime date) async {
    try {
      // Get start and end of day
      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      QuerySnapshot snapshot = await _firestore
          .collection('service_bookings')
          .where('bookingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('bookingDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();
      
      setState(() {
        _bookedSlots = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'time': data['bookingTime'] ?? '',
            'serviceName': data['serviceName'] ?? '',
            'customerName': data['customerName'] ?? '',
            'isMine': data['customerId'] == user?.uid,
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading booked slots: $e');
    }
  }

  List<String> _getAvailableTimeSlots() {
    List<String> allSlots = [];
    List<String> bookedTimes = _bookedSlots.map((s) => s['time'].toString()).toList();
    
    // Parse working hours
    int openHour = int.parse(_salonOpenTime.split(':')[0]);
    int openMinute = int.parse(_salonOpenTime.split(':')[1]);
    int closeHour = int.parse(_salonCloseTime.split(':')[0]);
    int closeMinute = int.parse(_salonCloseTime.split(':')[1]);
    
    // Generate time slots based on working hours
    for (int hour = openHour; hour <= closeHour; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        // Skip if before opening time
        if (hour == openHour && minute < openMinute) continue;
        // Skip if after closing time
        if (hour == closeHour && minute >= closeMinute) continue;
        if (hour > closeHour) break;
        
        String ampm = hour >= 12 ? 'PM' : 'AM';
        int displayHour = hour > 12 ? hour - 12 : hour;
        if (displayHour == 0) displayHour = 12;
        
        String time = '$displayHour:${minute.toString().padLeft(2, '0')} $ampm';
        if (!bookedTimes.contains(time)) {
          allSlots.add(time);
        }
      }
    }
    
    return allSlots;
  }

  Future<void> _bookService() async {
    if (_selectedDay == null || _selectedTime == null || _selectedServiceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service, date, and time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      var selectedService = _services.firstWhere((s) => s['id'] == _selectedServiceId);
      
      await _firestore.collection('service_bookings').add({
        'customerId': user?.uid,
        'customerName': user?.displayName ?? 'Customer',
        'customerEmail': user?.email ?? '',
        'serviceId': _selectedServiceId,
        'serviceName': selectedService['name'],
        'servicePrice': selectedService['price'],
        'serviceDuration': selectedService['duration'],
        'bookingDate': Timestamp.fromDate(_selectedDay!),
        'bookingTime': _selectedTime!.format(context),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh data
      await _loadBookedSlots(_selectedDay!);
      await _loadCustomerBookings();
      
      setState(() {
        _selectedTime = null;
        _selectedServiceId = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Book Appointment',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showMyBookings ? Icons.calendar_today : Icons.list_alt,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _showMyBookings = !_showMyBookings);
              if (_showMyBookings) {
                _loadCustomerBookings();
              }
            },
            tooltip: _showMyBookings ? 'View Calendar' : 'My Bookings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2845C)),
              ),
            )
          : _showMyBookings
              ? _buildMyBookings()
              : _buildBookingCalendar(),
    );
  }

  Widget _buildBookingCalendar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Working Hours Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDEEE9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFFF2845C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Working Hours',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Open: ${_formatTime(_salonOpenTime)} - Close: ${_formatTime(_salonCloseTime)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Service Selection
          const Text(
            'Select Service',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _selectedServiceId.isEmpty ? null : _selectedServiceId,
              hint: const Text('Choose a service'),
              isExpanded: true,
              underline: const SizedBox(),
              items: _services.map((service) {
                return DropdownMenuItem<String>(
                  value: service['id'],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          service['name'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        'Rs. ${service['price']}',
                        style: TextStyle(
                          color: const Color(0xFFF2845C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedServiceId = value!);
              },
            ),
          ),
          const SizedBox(height: 20),

          // Calendar
          const Text(
            'Select Date',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 60)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _loadBookedSlots(selectedDay);
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFFF2845C),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(
                  color: Colors.red.shade400,
                ),
                markersMaxCount: 3,
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  // Show dot for dates with bookings
                  if (_bookedSlots.isNotEmpty) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Booked Slots for Selected Day
          if (_selectedDay != null) ...[
            const Text(
              'Booked Slots',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            if (_bookedSlots.isEmpty)
              const Text(
                'No bookings for this day',
                style: TextStyle(color: Colors.grey),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _bookedSlots.map((slot) {
                    return Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(slot['time']),
                          if (slot['isMine'] == true) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'YOURS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      backgroundColor: slot['isMine'] == true 
                          ? Colors.green.shade100 
                          : Colors.red.shade100,
                      labelStyle: TextStyle(
                        color: slot['isMine'] == true 
                            ? Colors.green.shade700 
                            : Colors.red.shade700,
                        fontSize: 12,
                      ),
                      avatar: Icon(
                        slot['isMine'] == true 
                            ? Icons.check_circle 
                            : Icons.event_busy,
                        size: 14,
                        color: slot['isMine'] == true 
                            ? Colors.green 
                            : Colors.red,
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 20),
          ],

          // Time Slots
          if (_selectedDay != null) ...[
            const Text(
              'Available Time Slots',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_getAvailableTimeSlots().isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'No available slots for this day',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getAvailableTimeSlots().map((time) {
                  bool isSelected = _selectedTime != null &&
                      _selectedTime!.format(context) == time;
                  return FilterChip(
                    label: Text(time),
                    selected: isSelected,
                    onSelected: (_) {
                      final parts = time.split(' ');
                      final timeParts = parts[0].split(':');
                      int hour = int.parse(timeParts[0]);
                      int minute = int.parse(timeParts[1]);
                      if (parts[1] == 'PM' && hour != 12) hour += 12;
                      if (parts[1] == 'AM' && hour == 12) hour = 0;
                      setState(() {
                        _selectedTime = TimeOfDay(hour: hour, minute: minute);
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFFDEEE9),
                    checkmarkColor: const Color(0xFFF2845C),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFFF2845C) : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
          ],

          // Book Button
          if (_selectedDay != null && _selectedTime != null && _selectedServiceId.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _bookService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2845C),
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
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyBookings() {
    print('Building My Bookings, count: ${_customerBookings.length}'); // Debug log
    
    if (_customerBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No bookings yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Book your first appointment now!',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _showMyBookings = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2845C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Book Now'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _customerBookings.length,
      itemBuilder: (context, index) {
        var booking = _customerBookings[index];
        String status = booking['status'] ?? 'pending';
        Color statusColor;
        String statusLabel;
        
        switch (status) {
          case 'confirmed':
            statusColor = Colors.green;
            statusLabel = 'Confirmed';
            break;
          case 'cancelled':
            statusColor = Colors.red;
            statusLabel = 'Cancelled';
            break;
          case 'completed':
            statusColor = Colors.blue;
            statusLabel = 'Completed';
            break;
          default:
            statusColor = Colors.orange;
            statusLabel = 'Pending';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking['serviceName'] ?? 'Service',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      booking['bookingDateFormatted'] ?? 'No date',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      booking['bookingTime'] ?? 'No time',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Price: Rs. ${booking['servicePrice'] ?? 0}',
                  style: TextStyle(
                    color: const Color(0xFFF2845C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(String time) {
    try {
      var parts = time.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      String ampm = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour > 12 ? hour - 12 : hour;
      if (displayHour == 0) displayHour = 12;
      return '$displayHour:${minute.toString().padLeft(2, '0')} $ampm';
    } catch (e) {
      return time;
    }
  }
}