// lib/screens/vendor/vendor_chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';

class VendorChatListScreen extends StatefulWidget {
  const VendorChatListScreen({super.key});

  @override
  State<VendorChatListScreen> createState() => _VendorChatListScreenState();
}

class _VendorChatListScreenState extends State<VendorChatListScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, Map<String, dynamic>> _customerChats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all chats where vendor is participant
      QuerySnapshot snapshot = await _firestore
          .collection('customer_vendor_chat')
          .where('participants', arrayContains: user?.uid)
          .orderBy('timestamp', descending: true)
          .get();

      Map<String, Map<String, dynamic>> chats = {};
      
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String customerId = data['customerId'] ?? '';
        
        if (customerId.isNotEmpty) {
          if (!chats.containsKey(customerId)) {
            chats[customerId] = {
              'customerId': customerId,
              'lastMessage': data['message'] ?? '',
              'timestamp': data['timestamp'] as Timestamp?,
              'unread': data['read'] == false && data['senderId'] != user?.uid,
              'docId': doc.id,
            };
          } else {
            var existing = chats[customerId];
            var existingTimestamp = existing?['timestamp'] as Timestamp?;
            var newTimestamp = data['timestamp'] as Timestamp?;
            
            if (newTimestamp != null && (existingTimestamp == null || newTimestamp.compareTo(existingTimestamp) > 0)) {
              chats[customerId] = {
                'customerId': customerId,
                'lastMessage': data['message'] ?? '',
                'timestamp': newTimestamp,
                'unread': data['read'] == false && data['senderId'] != user?.uid,
                'docId': doc.id,
              };
            }
          }
        }
      }

      setState(() {
        _customerChats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chats: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadChats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2845C)),
              ),
            )
          : _customerChats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No chats yet',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customers will contact you here',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _customerChats.length,
                  itemBuilder: (context, index) {
                    var entry = _customerChats.entries.elementAt(index);
                    var customerId = entry.key;
                    var data = entry.value;
                    
                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(customerId).get(),
                      builder: (context, userSnapshot) {
                        String customerName = 'Customer';
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          customerName = userData['name'] ?? 'Customer';
                        }

                        return _buildChatTile(
                          customerId: customerId,
                          customerName: customerName,
                          lastMessage: data['lastMessage'] ?? '',
                          timestamp: data['timestamp'] as Timestamp?,
                          unread: data['unread'] ?? false,
                        );
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildChatTile({
    required String customerId,
    required String customerName,
    required String lastMessage,
    Timestamp? timestamp,
    required bool unread,
  }) {
    String formattedDate = timestamp != null
        ? DateFormat('MMM d, h:mm a').format(timestamp.toDate())
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: unread ? const Color(0xFFF2845C) : Colors.grey[300],
          child: Text(
            customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
            style: TextStyle(
              color: unread ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customerName,
          style: TextStyle(
            fontWeight: unread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: unread ? Colors.black : Colors.grey[600],
            fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (timestamp != null)
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            if (unread)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2845C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorChatScreen(
                vendorId: user?.uid ?? '',
                vendorName: 'Vendor',
                customerId: customerId,
              ),
            ),
          );
        },
      ),
    );
  }
}