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
  Map<String, Map<String, dynamic>> _combinedChats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllChats();
  }

  Future<void> _loadAllChats() async {
    setState(() => _isLoading = true);
    
    try {
      Map<String, Map<String, dynamic>> combinedChats = {};
      Set<String> uniqueParticipants = {};
      Map<String, String> customerNames = {};
      
      // 1. Load admin messages (from chat_messages collection)
      QuerySnapshot adminMessages = await _firestore
          .collection('chat_messages')
          .where('participants', arrayContains: user?.uid)
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in adminMessages.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String? senderId = data['senderId'];
        String? receiverId = data['receiverId'];
        
        String? otherParticipant;
        if (senderId == user?.uid) {
          otherParticipant = receiverId;
        } else {
          otherParticipant = senderId;
        }
        
        if (otherParticipant == null || otherParticipant == user?.uid) continue;
        
        bool isAdmin = otherParticipant == 'admin';
        String key = isAdmin ? 'admin' : 'customer_$otherParticipant';
        
        if (!uniqueParticipants.contains(otherParticipant)) {
          uniqueParticipants.add(otherParticipant);
          
          // Get customer name if not admin
          String displayName = isAdmin ? 'Admin Support' : 'Customer';
          if (!isAdmin) {
            try {
              DocumentSnapshot userDoc = await _firestore.collection('users').doc(otherParticipant).get();
              if (userDoc.exists) {
                var userData = userDoc.data() as Map<String, dynamic>;
                displayName = userData['name'] ?? 'Customer';
                customerNames[otherParticipant] = displayName;
              }
            } catch (e) {
              print('Error fetching customer name: $e');
            }
          }
          
          bool unread = data['read'] == false && data['senderId'] != user?.uid;
          
          combinedChats[key] = {
            'participantId': otherParticipant,
            'participantName': displayName,
            'lastMessage': data['message'] ?? '',
            'timestamp': data['timestamp'] as Timestamp?,
            'unread': unread,
            'isAdmin': isAdmin,
            'docId': doc.id,
          };
        } else {
          // Update if newer message
          var existing = combinedChats[key];
          var existingTimestamp = existing?['timestamp'] as Timestamp?;
          var newTimestamp = data['timestamp'] as Timestamp?;
          
          if (newTimestamp != null && (existingTimestamp == null || newTimestamp.compareTo(existingTimestamp) > 0)) {
            bool unread = data['read'] == false && data['senderId'] != user?.uid;
            combinedChats[key] = {
              'participantId': otherParticipant,
              'participantName': existing?['participantName'] ?? 'Customer',
              'lastMessage': data['message'] ?? '',
              'timestamp': newTimestamp,
              'unread': unread,
              'isAdmin': isAdmin,
              'docId': doc.id,
            };
          }
        }
      }

      // 2. Load customer chat messages (from customer_vendor_chat collection)
      QuerySnapshot customerChats = await _firestore
          .collection('customer_vendor_chat')
          .where('participants', arrayContains: user?.uid)
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in customerChats.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String? customerId = data['customerId'];
        
        if (customerId == null || customerId == user?.uid) continue;
        
        String key = 'customer_$customerId';
        
        // Get customer name if not already fetched
        String displayName = customerNames[customerId] ?? 'Customer';
        if (!customerNames.containsKey(customerId)) {
          try {
            DocumentSnapshot userDoc = await _firestore.collection('users').doc(customerId).get();
            if (userDoc.exists) {
              var userData = userDoc.data() as Map<String, dynamic>;
              displayName = userData['name'] ?? 'Customer';
              customerNames[customerId] = displayName;
            }
          } catch (e) {
            print('Error fetching customer name: $e');
          }
        }
        
        if (!uniqueParticipants.contains(customerId)) {
          uniqueParticipants.add(customerId);
          bool unread = data['read'] == false && data['senderId'] != user?.uid;
          
          combinedChats[key] = {
            'participantId': customerId,
            'participantName': displayName,
            'lastMessage': data['message'] ?? '',
            'timestamp': data['timestamp'] as Timestamp?,
            'unread': unread,
            'isAdmin': false,
            'docId': doc.id,
          };
        } else {
          // Update if newer message
          var existing = combinedChats[key];
          var existingTimestamp = existing?['timestamp'] as Timestamp?;
          var newTimestamp = data['timestamp'] as Timestamp?;
          
          if (newTimestamp != null && (existingTimestamp == null || newTimestamp.compareTo(existingTimestamp) > 0)) {
            bool unread = data['read'] == false && data['senderId'] != user?.uid;
            combinedChats[key] = {
              'participantId': customerId,
              'participantName': displayName,
              'lastMessage': data['message'] ?? '',
              'timestamp': newTimestamp,
              'unread': unread,
              'isAdmin': false,
              'docId': doc.id,
            };
          }
        }
      }

      setState(() {
        _combinedChats = combinedChats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chats: ${e.toString()}')),
      );
    }
  }

  // Mark messages as read when tapping on a chat
  Future<void> _markMessagesAsRead(String participantId, bool isAdmin) async {
    try {
      if (isAdmin) {
        // Mark admin messages as read
        QuerySnapshot snapshot = await _firestore
            .collection('chat_messages')
            .where('participants', arrayContains: user?.uid)
            .where('senderId', isEqualTo: 'admin')
            .where('read', isEqualTo: false)
            .get();
        
        for (var doc in snapshot.docs) {
          await doc.reference.update({'read': true});
        }
      } else {
        // Mark customer messages as read
        QuerySnapshot snapshot = await _firestore
            .collection('customer_vendor_chat')
            .where('participants', arrayContains: user?.uid)
            .where('senderId', isEqualTo: participantId)
            .where('read', isEqualTo: false)
            .get();
        
        for (var doc in snapshot.docs) {
          await doc.reference.update({'read': true});
        }
      }
      
      // Reload chats to update unread status
      await _loadAllChats();
    } catch (e) {
      print('Error marking messages as read: $e');
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
            onPressed: _loadAllChats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2845C)),
              ),
            )
          : _combinedChats.isEmpty
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
                        'Chat with admin or customers',
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
                  itemCount: _combinedChats.length,
                  itemBuilder: (context, index) {
                    var entry = _combinedChats.entries.elementAt(index);
                    var chatData = entry.value;
                    String participantId = chatData['participantId'] ?? '';
                    bool isAdmin = chatData['isAdmin'] ?? false;
                    String participantName = chatData['participantName'] ?? 'Customer';
                    
                    return isAdmin 
                        ? _buildAdminChatTile(chatData)
                        : _buildChatTile(
                            participantId: participantId,
                            participantName: participantName,
                            chatData: chatData,
                          );
                  },
                ),
    );
  }

  Widget _buildAdminChatTile(Map<String, dynamic> chatData) {
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
          child: const Icon(Icons.admin_panel_settings, color: Colors.white),
        ),
        title: const Text(
          'Admin Support',
          style: TextStyle(fontWeight: FontWeight.bold),
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
          await _markMessagesAsRead('admin', true);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorChatScreen(
                vendorId: user?.uid ?? '',
                vendorName: 'Admin Support',
                customerId: 'admin',
                isAdminChat: true,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatTile({
    required String participantId,
    required String participantName,
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
            participantName.isNotEmpty ? participantName[0].toUpperCase() : 'C',
            style: TextStyle(
              color: unread ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          participantName,
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
          await _markMessagesAsRead(participantId, false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorChatScreen(
                vendorId: user?.uid ?? '',
                vendorName: participantName,
                customerId: participantId,
                isAdminChat: false,
              ),
            ),
          );
        },
      ),
    );
  }
}