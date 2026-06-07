//lib/screens/announcements_screen.dart
import 'package:flutter/material.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final List<Map<String, String>> _announcements = [
    {
      'title': 'New Product Launch!',
      'message': 'New makeup products available for vendors',
      'date': '22 Feb 2026',
      'type': 'info',
    },
    {
      'title': 'Commission Update',
      'message': 'Commission rate changed to 15% from March 1st',
      'date': '21 Feb 2026',
      'type': 'warning',
    },
    {
      'title': 'Maintenance Alert',
      'message': 'App maintenance on 25 Feb, 2AM-4AM',
      'date': '20 Feb 2026',
      'type': 'alert',
    },
    {
      'title': 'New Feature',
      'message': 'Statistics dashboard now available for vendors',
      'date': '19 Feb 2026',
      'type': 'success',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Announcements',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          return _buildAnnouncementCard(announcement);
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, String> announcement) {
    Color cardColor;
    IconData iconData;

    switch (announcement['type']) {
      case 'success':
        cardColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case 'warning':
        cardColor = Colors.orange;
        iconData = Icons.warning;
        break;
      case 'alert':
        cardColor = Colors.red;
        iconData = Icons.error;
        break;
      default:
        cardColor = Colors.blue;
        iconData = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: cardColor, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement['title']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    announcement['message']!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    announcement['date']!,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
