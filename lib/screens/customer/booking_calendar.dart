//lib/screens/customer_modules/booking_calendar.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingCalendarScreen extends StatefulWidget {
  const BookingCalendarScreen({super.key});

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Appointment")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 60)), // 60-day window
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(color: Color(0xFFF2845C), shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedDay != null)
            Expanded(
              child: _buildAvailableTimeSlots(), // Pull real time slots from Firestore
            )
        ],
      ),
    );
  }

  Widget _buildAvailableTimeSlots() {
    // Return a GridView of available slots (e.g., 10:00 AM, 11:00 AM)
    return Center(child: Text("Slots for ${_selectedDay.toString().split(' ')[0]}"));
  }
}