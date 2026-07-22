// lib/screens/help_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  GenerativeModel? _model;
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoadingHistory = true;
  bool _geminiInitialized = false;
  bool _isDeleting = false;
  bool _useGemini = false; // Toggle for using Gemini or fallback

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _loadChatHistory();
  }

  Future<void> _initializeGemini() async {
    try {
      const apiKey = 'Gemini Api key'; // Replace with your actual API key
      
      _model = GenerativeModel(
        model: 'gemini-3.5-flash',
        apiKey: apiKey,
      );
      
      // Test the model
      final testResponse = await _model!.generateContent(
        [Content.text('Hello')]
      );
      
      if (testResponse.text != null) {
        setState(() {
          _geminiInitialized = true;
          _useGemini = true;
        });
        print('✅ Gemini initialized successfully');
      }
    } catch (e) {
      print('❌ Error initializing Gemini: $e');
      setState(() {
        _geminiInitialized = false;
        _useGemini = false;
      });
    }
  }

  Future<void> _loadChatHistory() async {
    if (user == null) {
      setState(() {
        _isLoadingHistory = false;
        _addWelcomeMessage();
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('help_chat_history')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('timestamp', descending: false)
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> loadedMessages = [];
        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          loadedMessages.add({
            'isUser': data['isUser'] ?? false,
            'message': data['message'] ?? '',
            'timestamp': (data['timestamp'] as Timestamp).toDate(),
            'docId': doc.id,
          });
        }
        setState(() {
          _messages = loadedMessages;
          _isLoadingHistory = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _isLoadingHistory = false;
          _addWelcomeMessage();
        });
      }
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        _isLoadingHistory = false;
        _addWelcomeMessage();
      });
    }
  }

  Future<void> _saveMessageToHistory(bool isUser, String message, DateTime timestamp) async {
    if (user == null) return;
    
    try {
      await _firestore.collection('help_chat_history').add({
        'userId': user!.uid,
        'userEmail': user!.email ?? '',
        'isUser': isUser,
        'message': message,
        'timestamp': Timestamp.fromDate(timestamp),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving message: $e');
    }
  }

  Future<void> _deleteSingleMessage(String docId, int index) async {
    if (user == null || docId.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() => _isDeleting = true);
              try {
                await _firestore.collection('help_chat_history').doc(docId).delete();
                setState(() {
                  _messages.removeAt(index);
                  _isDeleting = false;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message deleted'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                setState(() => _isDeleting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting message: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllChatHistory() async {
    if (user == null || _messages.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Chat History'),
        content: const Text('Are you sure you want to delete all your chat history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() => _isDeleting = true);
              try {
                QuerySnapshot snapshot = await _firestore
                    .collection('help_chat_history')
                    .where('userId', isEqualTo: user!.uid)
                    .get();
                
                for (var doc in snapshot.docs) {
                  await doc.reference.delete();
                }
                
                setState(() {
                  _messages.clear();
                  _addWelcomeMessage();
                  _isDeleting = false;
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All chat history deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                setState(() => _isDeleting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting history: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      final welcomeMsg = '👋 Hello! I\'m your GlowSalon AI Assistant.\n\nI can help you with:\n• Booking appointments\n• Shopping for products\n• Understanding app features\n• Getting started as a vendor\n• General knowledge questions\n• And much more!\n\nWhat would you like to know?';
      _messages.add({
        'isUser': false,
        'message': welcomeMsg,
        'timestamp': DateTime.now(),
        'docId': '',
      });
      if (user != null) {
        _saveMessageToHistory(false, welcomeMsg, DateTime.now());
      }
      setState(() {});
    }
  }

  Future<void> _sendQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _isLoading || _isDeleting) return;

    final now = DateTime.now();
    _messages.add({
      'isUser': true,
      'message': query,
      'timestamp': now,
      'docId': '',
    });
    _queryController.clear();
    setState(() => _isLoading = true);
    
    // Save user message to history
    String? userDocId;
    if (user != null) {
      try {
        final docRef = await _firestore.collection('help_chat_history').add({
          'userId': user!.uid,
          'userEmail': user!.email ?? '',
          'isUser': true,
          'message': query,
          'timestamp': Timestamp.fromDate(now),
          'createdAt': FieldValue.serverTimestamp(),
        });
        userDocId = docRef.id;
        setState(() {
          _messages[_messages.length - 1]['docId'] = userDocId;
        });
      } catch (e) {
        print('Error saving user message: $e');
      }
    }
    
    _scrollToBottom();

    try {
      String answer;
      
      // Try Gemini first if available
      if (_useGemini && _model != null) {
        try {
          final prompt = '''
You are GlowSalon AI Assistant. You are a helpful, friendly, and knowledgeable assistant.
Answer the following question accurately and concisely.

Context about GlowSalon app:
- Beauty and salon management app
- Features: Book appointments, Shop products, AR Makeup Try-On, Orders, Chat with vendors
- Users: Customers, Vendors, Admin
- Vendors need admin approval

Question: $query

Please provide a helpful and accurate response. If the question is not related to the app, answer it generally.
''';
          
          final response = await _model!.generateContent(
            [Content.text(prompt)]
          );
          answer = response.text ?? _getFallbackResponse(query);
        } catch (e) {
          print('Gemini error: $e');
          answer = _getFallbackResponse(query);
        }
      } else {
        // Use fallback responses
        answer = _getFallbackResponse(query);
      }
      
      final responseTime = DateTime.now();
      final responseIndex = _messages.length;
      _messages.add({
        'isUser': false,
        'message': answer,
        'timestamp': responseTime,
        'docId': '',
      });
      
      // Save AI response to history
      if (user != null) {
        try {
          final docRef = await _firestore.collection('help_chat_history').add({
            'userId': user!.uid,
            'userEmail': user!.email ?? '',
            'isUser': false,
            'message': answer,
            'timestamp': Timestamp.fromDate(responseTime),
            'createdAt': FieldValue.serverTimestamp(),
          });
          setState(() {
            _messages[responseIndex]['docId'] = docRef.id;
          });
        } catch (e) {
          print('Error saving AI response: $e');
        }
      }
      
    } catch (e) {
      final responseTime = DateTime.now();
      final errorMsg = 'Error: ${e.toString()}\n\nPlease try again or contact support.';
      final errorIndex = _messages.length;
      _messages.add({
        'isUser': false,
        'message': errorMsg,
        'timestamp': responseTime,
        'docId': '',
      });
      
      if (user != null) {
        try {
          final docRef = await _firestore.collection('help_chat_history').add({
            'userId': user!.uid,
            'userEmail': user!.email ?? '',
            'isUser': false,
            'message': errorMsg,
            'timestamp': Timestamp.fromDate(responseTime),
            'createdAt': FieldValue.serverTimestamp(),
          });
          setState(() {
            _messages[errorIndex]['docId'] = docRef.id;
          });
        } catch (e) {
          print('Error saving error message: $e');
        }
      }
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  String _getFallbackResponse(String query) {
    final lowerQuery = query.toLowerCase();
    
    // General knowledge questions
    if (lowerQuery.contains('capital') && lowerQuery.contains('pakistan')) {
      return 'The capital of Pakistan is Islamabad. It is located in the Islamabad Capital Territory and is the country\'s ninth-largest city.';
    } else if (lowerQuery.contains('capital') && lowerQuery.contains('india')) {
      return 'The capital of India is New Delhi. It is located in the National Capital Territory of Delhi.';
    } else if (lowerQuery.contains('capital') && lowerQuery.contains('china')) {
      return 'The capital of China is Beijing. It is one of the most populous cities in the world.';
    } else if (lowerQuery.contains('population') && lowerQuery.contains('pakistan')) {
      return 'Pakistan has a population of approximately 240 million people (as of 2023). It is the 5th most populous country in the world.';
    } else if (lowerQuery.contains('currency') && lowerQuery.contains('pakistan')) {
      return 'The official currency of Pakistan is the Pakistani Rupee (PKR).';
    } else if (lowerQuery.contains('language') && lowerQuery.contains('pakistan')) {
      return 'Urdu is the national language of Pakistan, and English is widely used as an official language. There are also several regional languages including Punjabi, Sindhi, Pashto, and Balochi.';
    
    // App related questions
    } else if (lowerQuery.contains('book') || lowerQuery.contains('appointment')) {
      return 'To book an appointment:\n1. Go to the "Book Now" section\n2. Select a service (Hair, Makeup, Spa, Nails, Facials)\n3. Choose a date and time\n4. Confirm your booking\n\nYou can also book through the "Services" menu.';
    } else if (lowerQuery.contains('shop') || lowerQuery.contains('product') || lowerQuery.contains('buy')) {
      return 'To shop for products:\n1. Go to the "Shop" section\n2. Browse products from various vendors\n3. Click on a product to view details\n4. Add to cart and checkout\n\nYou can also chat with vendors for more information.';
    } else if (lowerQuery.contains('vendor') || lowerQuery.contains('become') || lowerQuery.contains('sell')) {
      return 'To become a vendor:\n1. Go to "Become a Vendor" in the app\n2. Fill in your business details\n3. Submit your application\n4. Wait for admin approval\n\nYou\'ll be notified once your account is approved.';
    } else if (lowerQuery.contains('payment') || lowerQuery.contains('pay') || lowerQuery.contains('money')) {
      return 'Payment options available:\n• Cash on Delivery (COD)\n• JazzCash\n• EasyPaisa\n• Bank Transfer\n\nPayments are secure and processed through our trusted partners.';
    } else if (lowerQuery.contains('reset') || lowerQuery.contains('password') || lowerQuery.contains('forgot')) {
      return 'To reset your password:\n1. Go to the Sign In screen\n2. Tap "Forgot password?"\n3. Enter your email address\n4. Check your inbox for the reset link\n5. Follow the link to set a new password';
    } else if (lowerQuery.contains('dummy') || lowerQuery.contains('test') || lowerQuery.contains('email')) {
      return 'Yes, you can use dummy email for testing purposes. However, for real usage, we recommend using a valid email address to receive important notifications and updates.';
    } else if (lowerQuery.contains('purpose') || lowerQuery.contains('app')) {
      return 'GlowSalon is a beauty and salon management app that helps customers book appointments, shop for products, and discover beauty services. It also allows vendors to manage their products and orders, and admins to manage the entire platform.';
    } else if (lowerQuery.contains('hi') || lowerQuery.contains('hello') || lowerQuery.contains('hey')) {
      return 'Hello! 👋 How can I help you today? I can assist with booking appointments, shopping, becoming a vendor, payments, general knowledge questions, and more!';
    
    // General fallback
    } else {
      return 'I\'m here to help! You can ask me about:\n• Booking appointments\n• Shopping for products\n• Becoming a vendor\n• Payments\n• Password reset\n• General knowledge (like capitals, population, etc.)\n• And more!\n\nWhat would you like to know?';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_messages.isNotEmpty && _messages.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: _deleteAllChatHistory,
              tooltip: 'Delete All Chat History',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
            tooltip: 'Refresh Chat',
          ),
          // Toggle between AI and Fallback
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _useGemini = !_useGemini;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_useGemini ? 'AI Mode: Gemini' : 'AI Mode: Fallback'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _useGemini ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _useGemini ? 'AI' : 'Offline',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Quick Action Chips
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickActionChip('📅 Book Appointment', () {
                          _queryController.text = 'How do I book an appointment?';
                          _sendQuery();
                        }),
                        const SizedBox(width: 8),
                        _buildQuickActionChip('🛍️ Shop Products', () {
                          _queryController.text = 'How do I shop for products?';
                          _sendQuery();
                        }),
                        const SizedBox(width: 8),
                        _buildQuickActionChip('👨‍💼 Become Vendor', () {
                          _queryController.text = 'How do I become a vendor?';
                          _sendQuery();
                        }),
                        const SizedBox(width: 8),
                        _buildQuickActionChip('💳 Payments', () {
                          _queryController.text = 'How do payments work?';
                          _sendQuery();
                        }),
                        const SizedBox(width: 8),
                        _buildQuickActionChip('🔄 Reset Password', () {
                          _queryController.text = 'How do I reset my password?';
                          _sendQuery();
                        }),
                        const SizedBox(width: 8),
                        _buildQuickActionChip('📧 General Query', () {
                          _queryController.text = 'Tell me something interesting';
                          _sendQuery();
                        }),
                      ],
                    ),
                  ),
                ),
                // Chat Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['isUser'] as bool;
                      final text = message['message'] as String;
                      final timestamp = message['timestamp'] as DateTime;
                      final docId = message['docId'] as String;

                      return _buildMessageBubble(
                        message: text,
                        isUser: isUser,
                        timestamp: timestamp,
                        docId: docId,
                        index: index,
                      );
                    },
                  ),
                ),
                if (_isLoading || _isDeleting)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(
                      color: Color(0xFFF2845C),
                    ),
                  ),
                // Input Field
                Container(
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
                          controller: _queryController,
                          enabled: !_isLoading && !_isDeleting,
                          decoration: InputDecoration(
                            hintText: 'Ask me anything...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onSubmitted: (_) => _sendQuery(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: (_isLoading || _isDeleting) ? null : _sendQuery,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF2845C),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            (_isLoading || _isDeleting) ? Icons.close : Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickActionChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFDEEE9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF2845C).withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFFF2845C),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isUser,
    required DateTime timestamp,
    required String docId,
    required int index,
  }) {
    // Don't show delete for welcome message or if docId is empty
    final showDelete = docId.isNotEmpty && index > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF2845C).withOpacity(0.1),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Color(0xFFF2845C),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFF2845C) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('hh:mm a').format(timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser ? Colors.white.withOpacity(0.7) : Colors.grey[500],
                        ),
                      ),
                      if (showDelete) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _deleteSingleMessage(docId, index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              child: const Icon(
                Icons.person,
                size: 16,
                color: Color(0xFF718096),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
