//lib/screens/unavailable_dates_screen.dart
import 'package:flutter/material.dart';

class UnavailableDatesScreen extends StatefulWidget {
  const UnavailableDatesScreen({super.key});

  @override
  State<UnavailableDatesScreen> createState() => _UnavailableDatesScreenState();
}

class _UnavailableDatesScreenState extends State<UnavailableDatesScreen> {
  List<DateTime> _selectedDates = [];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDates.add(picked);
      });
    }
  }

  void _removeDate(int index) {
    setState(() {
      _selectedDates.removeAt(index);
    });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select dates when you are unavailable',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Add Date Button
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

            // Selected Dates List
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
                        child: const Icon(Icons.event_busy,
                            color: Color(0xFFF2845C), size: 24),
                      ),
                      title: Text(
                        '${date.day}/${date.month}/${date.year}',
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

            // Save Button
            if (_selectedDates.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveDates,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2845C),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
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

  void _saveDates() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedDates.length} dates saved successfully! ✨'),
        backgroundColor: const Color(0xFFF2845C),
      ),
    );
    Navigator.pop(context);
  }
}
