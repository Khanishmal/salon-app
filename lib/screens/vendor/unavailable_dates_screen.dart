// lib/screens/unavailable_dates_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UnavailableDatesScreen extends StatefulWidget {
  final String vendorId;
  const UnavailableDatesScreen({super.key, required this.vendorId});

  @override
  State<UnavailableDatesScreen> createState() => _UnavailableDatesScreenState();
}

class _UnavailableDatesScreenState extends State<UnavailableDatesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DateTime> _selectedDates = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUnavailableDates();
  }

  Future<void> _loadUnavailableDates() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('vendor_settings')
          .doc(widget.vendorId)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['unavailableDates'] != null) {
          List dates = data['unavailableDates'];
          _selectedDates = dates.map((d) => (d as Timestamp).toDate()).toList();
        }
      }
    } catch (e) {
      print('Error loading unavailable dates: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      // Check if date already exists
      bool exists = _selectedDates.any((d) => 
        d.year == picked.year && d.month == picked.month && d.day == picked.day
      );
      if (!exists) {
        setState(() {
          _selectedDates.add(picked);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This date is already selected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _removeDate(int index) {
    setState(() {
      _selectedDates.removeAt(index);
    });
  }

  Future<void> _saveDates() async {
    setState(() => _isSaving = true);

    try {
      await _firestore.collection('vendor_settings').doc(widget.vendorId).set({
        'unavailableDates': _selectedDates.map((d) => Timestamp.fromDate(d)).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedDates.length} dates saved successfully! ✨'),
            backgroundColor: const Color(0xFFF2845C),
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
          'Unavailable Dates',
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
                    'Select dates when you are unavailable',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Add Unavailable Date'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2845C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Selected Dates',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  if (_selectedDates.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No unavailable dates selected',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedDates.length,
                      itemBuilder: (context, index) {
                        final date = _selectedDates[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDEEE9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.event_busy, color: Color(0xFFF2845C), size: 24),
                            ),
                            title: Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(date),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeDate(index),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 30),
                  if (_selectedDates.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveDates,
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
                                'Save Unavailable Dates',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}