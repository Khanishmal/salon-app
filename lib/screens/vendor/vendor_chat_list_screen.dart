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
    _loadCustomerChats();
  }

  Future<void> _loadCustomerChats() async {
    setState(() => _isLoading = true);
    
    try {
      Map<String, Map<String, dynamic>> customerChats = {};
      Set<String> uniqueCustomers = {};
      
      QuerySnapshot customerChatsSnapshot = await _firestore
          .collection('customer_vendor_chat')
          .where('participants', arrayContains: user?.uid)
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in customerChatsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String? customerId = data['customerId'];
        
        if (customerId == null || customerId == user?.uid) continue;
        
        if (!uniqueCustomers.contains(customerId)) {
          uniqueCustomers.add(customerId);
          
          String customerName = 'Customer';
          try {
            DocumentSnapshot userDoc = await _firestore.collection('users').doc(customerId).get();
            if (userDoc.exists) {
              var userData = userDoc.data() as Map<String, dynamic>;
              customerName = userData['name'] ?? 'Customer';
            }
          } catch (e) {
            print('Error fetching customer name: $e');
          }
          
          bool unread = data['read'] == false && data['senderId'] != user?.uid;
          
          customerChats[customerId] = {
            'customerId': customerId,
            'customerName': customerName,
            'lastMessage': data['message'] ?? '',
            'timestamp': data['timestamp'] as Timestamp?,
            'unread': unread,
            'docId': doc.id,
          };
        } else {
          var existing = customerChats[customerId];
          var existingTimestamp = existing?['timestamp'] as Timestamp?;
          var newTimestamp = data['timestamp'] as Timestamp?;
          
          if (newTimestamp != null && (existingTimestamp == null || newTimestamp.compareTo(existingTimestamp) > 0)) {
            bool unread = data['read'] == false && data['senderId'] != user?.uid;
            customerChats[customerId] = {
              'customerId': customerId,
              'customerName': existing?['customerName'] ?? 'Customer',
              'lastMessage': data['message'] ?? '',
              'timestamp': newTimestamp,
              'unread': unread,
              'docId': doc.id,
            };
          }
        }
      }

      setState(() {
        _customerChats = customerChats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chats: ${e.toString()}')),
      );
    }
  }

  Future<void> _markMessagesAsRead(String customerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('customer_vendor_chat')
          .where('participants', arrayContains: user?.uid)
          .where('senderId', isEqualTo: customerId)
          .where('read', isEqualTo: false)
          .get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.update({'read': true});
      }
      
      await _loadCustomerChats();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Chats',
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
            onPressed: _loadCustomerChats,
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
                        'No customer chats yet',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customers will contact you about products',
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
                    var chatData = entry.value;
                    String customerId = chatData['customerId'] ?? '';
                    String customerName = chatData['customerName'] ?? 'Customer';
                    
                    return _buildChatTile(
                      customerId: customerId,
                      customerName: customerName,
                      chatData: chatData,
                    );
                  },
                ),
    );
  }

  Widget _buildChatTile({
    required String customerId,
    required String customerName,
    required Map<String, dynamic> chatData,
  }) {
    String lastMessage = chatData['lastMessage'] ?? '';
    Timestamp? timestamp = chatData['timestamp'] as Timestamp?;
    bool unread = chatData['unread'] ?? false;
    
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
        onTap: () async {
          await _markMessagesAsRead(customerId);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorChatScreen(
                vendorId: user?.uid ?? '',
                vendorName: customerName,
                customerId: customerId,
                isAdminChat: false,
              ),
            ),
          );
        },
      ),
    );
  }
}