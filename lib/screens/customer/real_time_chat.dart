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
  final ScrollController _scrollController = ScrollController();
  String? _selectedSalonId;
  String? _selectedSalonName;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          _selectedSalonId == null ? "Messages" : _selectedSalonName ?? "Chat",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        leading: _selectedSalonId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
                onPressed: () {
                  setState(() {
                    _selectedSalonId = null;
                    _selectedSalonName = null;
                  });
                },
              )
            : null,
      ),
      body: Row(
        children: [
          // Salon Directory Side Navigation Panel
          Container(
            width: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.1))),
            ),
            child: _buildSalonList(),
          ),
          
          // Private Messaging Matrix Area
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF2845C)));
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No Salons\nAvailable",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var salon = snapshot.data!.docs[index];
            var data = salon.data() as Map<String, dynamic>;
            String salonName = data['name'] ?? 'Salon Business';
            bool isSelected = _selectedSalonId == salon.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSalonId = salon.id;
                  _selectedSalonName = salonName;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFDEEE9) : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: isSelected ? const Color(0xFFF2845C) : Colors.transparent,
                      width: 3.5,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: isSelected ? const Color(0xFFF2845C) : const Color(0xFFE2E8F0),
                      child: Text(
                        salonName.isNotEmpty ? salonName[0].toUpperCase() : 'S',
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF4A5568),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      salonName,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? const Color(0xFFF2845C) : const Color(0xFF2D3748),
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
          Icon(Icons.chat_bubble_outline, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Select a professional salon\nto view your private inbox thread",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    if (_selectedSalonId == null || user == null) return const SizedBox();

    // Isolated secure stream query bound to this exact customer UID and target business workspace
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('salonId', isEqualTo: _selectedSalonId)
          .where('userId', isEqualTo: user!.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF2845C)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 50, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  "No past logs found with this brand.",
                  style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
                ),
                Text(
                  "Send an inquiry message directly to the owner below!",
                  style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          reverse: true,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var msg = snapshot.data!.docs[index];
            var data = msg.data() as Map<String, dynamic>;
            bool isMe = data['senderId'] == user!.uid;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe) ...[
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFF2845C).withOpacity(0.1),
                      child: const Icon(Icons.store, size: 14, color: Color(0xFFF2845C)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFFF2845C) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 2),
                          bottomRight: Radius.circular(isMe ? 2 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        data['message'] ?? '',
                        style: GoogleFonts.poppins(
                          color: isMe ? Colors.white : const Color(0xFF2D3748),
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.person, size: 14, color: Color(0xFF718096)),
                    ),
                  ]
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.poppins(fontSize: 14),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Inquire about booking slots or styling options...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF1F3F4),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF2845C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final securedText = _messageController.text.trim();
    if (securedText.isEmpty || _selectedSalonId == null || user == null) return;

    _messageController.clear();

    await FirebaseFirestore.instance.collection('chats').add({
      'salonId': _selectedSalonId,
      'userId': user!.uid,        // Pairs this conversation strictly with this Customer account
      'senderId': user!.uid,      // Explicit tracking tag showing the customer initialized/wrote this specific node
      'message': securedText,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}