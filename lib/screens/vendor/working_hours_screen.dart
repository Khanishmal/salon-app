// lib/screens/working_hours_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WorkingHoursScreen extends StatefulWidget {
  final String vendorId;
  const WorkingHoursScreen({super.key, required this.vendorId});

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<bool> _selectedDays = List.filled(7, true);
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
  }

  Future<void> _loadWorkingHours() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('vendor_settings')
          .doc(widget.vendorId)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['workingHours'] != null) {
          var hours = data['workingHours'];
          
          // Parse start time
          if (hours['startTime'] != null) {
            var parts = hours['startTime'].split(':');
            _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
          
          // Parse end time
          if (hours['endTime'] != null) {
            var parts = hours['endTime'].split(':');
            _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
          
          // Parse selected days
          if (hours['days'] != null) {
            _selectedDays = List<bool>.from(hours['days']);
          }
        }
      }
    } catch (e) {
      print('Error loading working hours: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveHours() async {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _firestore.collection('vendor_settings').doc(widget.vendorId).set({
        'workingHours': {
          'startTime': '${_startTime!.hour}:${_startTime!.minute}',
          'endTime': '${_endTime!.hour}:${_endTime!.minute}',
          'days': _selectedDays,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Working hours saved successfully! ✨'),
            backgroundColor: Color(0xFFF2845C),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Set Working Hours',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Working Days',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (index) {
                      return FilterChip(
                        label: Text(_days[index]),
                        selected: _selectedDays[index],
                        onSelected: (selected) {
                          setState(() {
                            _selectedDays[index] = selected;
                          });
                        },
                        selectedColor: const Color(0xFFFDEEE9),
                        checkmarkColor: const Color(0xFFF2845C),
                      );
                    }),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Working Hours',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildTimePickerTile(
                    title: 'Start Time',
                    time: _startTime,
                    onTap: () async {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: _startTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => _startTime = time);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildTimePickerTile(
                    title: 'End Time',
                    time: _endTime,
                    onTap: () async {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: _endTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => _endTime = time);
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveHours,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2845C),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Working Hours',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimePickerTile({
    required String title,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFDEEE9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.access_time, color: Color(0xFFF2845C)),
        ),
        title: Text(title),
        subtitle: Text(
          time == null ? 'Not set' : time.format(context),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.edit, color: Color(0xFFF2845C)),
        onTap: onTap,
      ),
    );
  }
}