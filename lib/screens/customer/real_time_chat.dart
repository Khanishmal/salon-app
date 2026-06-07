// lib/screens/customer_modules/real_time_chat.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class RealTimeChatScreen extends StatefulWidget {
  const RealTimeChatScreen({super.key});

  @override
  State<RealTimeChatScreen> createState() => _RealTimeChatScreenState();
}

class _RealTimeChatScreenState extends State<RealTimeChatScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _messageController = TextEditingController();
  String? _selectedSalonId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Messages",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: Row(
        children: [
          // Salon List
          Container(
            width: 120,
            color: Colors.white,
            child: _buildSalonList(),
          ),
          // Chat Area
          Expanded(
            child: _selectedSalonId == null
                ? _buildNoChatSelected()
                : Column(
                    children: [
                      Expanded(
                        child: _buildChatMessages(),
                      ),
                      _buildMessageInput(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalonList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('salons').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var salon = snapshot.data!.docs[index];
            var data = salon.data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSalonId = salon.id;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedSalonId == salon.id
                      ? const Color(0xFFFDEEE9)
                      : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: _selectedSalonId == salon.id
                          ? const Color(0xFFF2845C)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFF2845C),
                      child: Text(
                        (data['name']?[0] ?? 'S').toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['name'] ?? 'Salon',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNoChatSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Select a salon to start chatting",
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    if (_selectedSalonId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('salonId', isEqualTo: _selectedSalonId)
          .where('userId', isEqualTo: user?.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message_outlined, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "No messages yet",
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  "Start a conversation!",
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          reverse: true,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var msg = snapshot.data!.docs[index];
            var data = msg.data() as Map<String, dynamic>;
            bool isMe = data['senderId'] == user?.uid;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isMe)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFF2845C),
                        child: const Icon(Icons.store, size: 16, color: Colors.white),
                      ),
                    ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFFF2845C) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        data['message'] ?? '',
                        style: GoogleFonts.poppins(
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  if (isMe)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, size: 16, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF1F3F4),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF2845C),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedSalonId == null) return;

    await FirebaseFirestore.instance.collection('chats').add({
      'salonId': _selectedSalonId,
      'userId': user?.uid,
      'senderId': user?.uid,
      'message': _messageController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    _messageController.clear();
  }
}