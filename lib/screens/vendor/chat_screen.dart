// lib/screens/vendor/vendor_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorChatScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final String customerId;
  final bool isAdminChat;

  const VendorChatScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.customerId,
    this.isAdminChat = false,
  });

  @override
  State<VendorChatScreen> createState() => _VendorChatScreenState();
}

class _VendorChatScreenState extends State<VendorChatScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  String _participantName = '';

  @override
  void initState() {
    super.initState();
    _participantName = widget.vendorName;
    if (!widget.isAdminChat && widget.customerId != 'admin') {
      _loadCustomerName();
    }
  }

  Future<void> _loadCustomerName() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(widget.customerId)
          .get();
      
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _participantName = data['name'] ?? 'Customer';
        });
      }
    } catch (e) {
      print('Error loading customer name: $e');
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final message = _messageController.text.trim();
    _messageController.clear();
    setState(() => _isSending = true);

    try {
      if (widget.isAdminChat || widget.customerId == 'admin') {
        await _firestore.collection('chat_messages').add({
          'senderId': user?.uid,
          'receiverId': 'admin',
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'isAdminMessage': false,
          'isVendorMessage': true,
          'participants': [user?.uid, 'admin'],
        });
      } else {
        await _firestore.collection('customer_vendor_chat').add({
          'customerId': widget.customerId,
          'vendorId': widget.vendorId,
          'senderId': user?.uid,
          'receiverId': widget.customerId,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'isCustomer': false,
          'isVendor': true,
          'participants': [widget.customerId, widget.vendorId],
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: widget.isAdminChat 
                  ? Colors.blue.withOpacity(0.1)
                  : const Color(0xFFF2845C).withOpacity(0.1),
              child: Icon(
                widget.isAdminChat 
                    ? Icons.admin_panel_settings 
                    : Icons.person,
                size: 16,
                color: widget.isAdminChat ? Colors.blue : const Color(0xFFF2845C),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _participantName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.isAdminChat ? 'Admin' : 'Customer',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isAdminChat ? Colors.blue : const Color(0xFFF2845C),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF2845C),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.isAdminChat || widget.customerId == 'admin'
                  ? _firestore
                      .collection('chat_messages')
                      .where('participants', arrayContains: user?.uid)
                      .orderBy('timestamp', descending: true)
                      .snapshots()
                  : _firestore
                      .collection('customer_vendor_chat')
                      .where('participants', arrayContains: user?.uid)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2845C)),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
                        const SizedBox(height: 8),
                        const Text('Error loading messages'),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start chatting with ${_participantName}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == user?.uid;
                    bool isAdmin = data['isAdminMessage'] == true;

                    return _buildMessageBubble(
                      message: data['message'] ?? '',
                      isMe: isMe,
                      isAdmin: isAdmin,
                      timestamp: data['timestamp'] as Timestamp?,
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    required bool isAdmin,
    Timestamp? timestamp,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: widget.isAdminChat 
                  ? Colors.blue.withOpacity(0.1)
                  : const Color(0xFFF2845C).withOpacity(0.1),
              child: Icon(
                widget.isAdminChat 
                    ? Icons.admin_panel_settings 
                    : Icons.person,
                size: 14,
                color: widget.isAdminChat ? Colors.blue : const Color(0xFFF2845C),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? LinearGradient(
                            colors: [const Color(0xFFF2845C), const Color(0xFFFFB6A0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe ? null : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      if (isAdmin && !isMe) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('MMM d, h:mm a').format(timestamp.toDate()),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFF2845C).withOpacity(0.1),
              child: const Icon(Icons.store, size: 14, color: Color(0xFFF2845C)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_isSending,
              decoration: InputDecoration(
                hintText: widget.isAdminChat 
                    ? 'Reply to admin...' 
                    : 'Reply to customer...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF2845C),
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}