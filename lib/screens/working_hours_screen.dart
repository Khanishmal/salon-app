import 'package:flutter/material.dart';

class WorkingHoursScreen extends StatefulWidget {
  const WorkingHoursScreen({super.key});

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  // Working hours ke liye variables
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<bool> _selectedDays = List.filled(7, true); // Monday to Sunday

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Working Days',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Days selection
            Wrap(
              spacing: 8,
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

            // Start Time
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEEE9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.access_time, color: Color(0xFFF2845C)),
              ),
              title: const Text('Start Time'),
              subtitle: Text(
                _startTime == null ? 'Not set' : _startTime!.format(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.edit, color: Color(0xFFF2845C)),
              onTap: () async {
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    _startTime = time;
                  });
                }
              },
            ),

            // End Time
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEEE9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.access_time, color: Color(0xFFF2845C)),
              ),
              title: const Text('End Time'),
              subtitle: Text(
                _endTime == null ? 'Not set' : _endTime!.format(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.edit, color: Color(0xFFF2845C)),
              onTap: () async {
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    _endTime = time;
                  });
                }
              },
            ),

            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveHours,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2845C),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
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

  void _saveHours() {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Yahan Firebase mein save karenge (baad mein)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Working hours saved successfully! ✨'),
        backgroundColor: Color(0xFFF2845C),
      ),
    );
    Navigator.pop(context);
  }
}
