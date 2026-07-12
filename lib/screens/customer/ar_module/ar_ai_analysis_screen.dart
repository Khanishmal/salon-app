// lib/screens/customer/ar_ai_analysis_screen.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../models/skin_analysis_models.dart';
import '../../../services/gemini_service.dart';
import '../../../services/face_detection_service.dart';
import '../../../widgets/skin_analysis_widgets.dart';

// =============================================================================
// AI SKIN ANALYSIS SCREEN - PROFESSIONAL VERSION
// =============================================================================

class ArAiAnalysisScreen extends StatefulWidget {
  const ArAiAnalysisScreen({super.key});

  @override
  State<ArAiAnalysisScreen> createState() => _ArAiAnalysisScreenState();
}

class _ArAiAnalysisScreenState extends State<ArAiAnalysisScreen>
    with SingleTickerProviderStateMixin {
  // ===========================================================================
  // STATE VARIABLES
  // ===========================================================================

  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _isDetectingFace = false;
  SkinAnalysisResult? _currentAnalysis;
  List<Map<String, dynamic>> _analysisHistory = [];
  int _selectedHistoryIndex = -1;

  int _selectedTab = 0;
  bool _showAROverlay = false;
  bool _isCameraMode = false;
  late TabController _tabController;

  // Chat State
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isChatMode = false;
  bool _isChatLoading = false;

  // Services
  final ImagePicker _picker = ImagePicker();
  final FaceDetectionService _faceDetectionService = FaceDetectionService();

  // Instructions Dialog
  bool _showInstructions = false;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalysisHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _faceDetectionService.dispose();
    super.dispose();
  }

  // ===========================================================================
  // HISTORY MANAGEMENT
  // ===========================================================================

  Future<void> _loadAnalysisHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('skin_analysis_history');
      if (historyJson != null) {
        final List<dynamic> history = jsonDecode(historyJson);
        setState(() {
          _analysisHistory = history.map((e) => e as Map<String, dynamic>).toList();
          _analysisHistory.sort((a, b) =>
              DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
        });
      }
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  Future<void> _saveAnalysis(SkinAnalysisResult analysis) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analysisWithTimestamp = {
        ...analysis.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      _analysisHistory.insert(0, analysisWithTimestamp);
      if (_analysisHistory.length > 20) {
        _analysisHistory = _analysisHistory.sublist(0, 20);
      }

      await prefs.setString('skin_analysis_history', jsonEncode(_analysisHistory));
      setState(() {});
    } catch (e) {
      print('Error saving analysis: $e');
    }
  }

  Future<void> _deleteAnalysis(String id) async {
    setState(() {
      _analysisHistory.removeWhere((item) => item['id'] == id);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('skin_analysis_history', jsonEncode(_analysisHistory));
  }

  // ===========================================================================
  // IMAGE PICKING WITH FACE DETECTION
  // ===========================================================================

  Future<void> _pickImage() async {
    // Show instructions first
    await _showPhotoInstructions();

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image != null) {
      await _processSelectedImage(File(image.path), isCamera: false);
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (image != null) {
      await _processSelectedImage(File(image.path), isCamera: true);
    }
  }

  Future<void> _processSelectedImage(File image, {required bool isCamera}) async {
    setState(() {
      _selectedImage = image;
      _isCameraMode = isCamera;
      _isDetectingFace = true;
      _currentAnalysis = null;
    });

    try {
      // Check if face is detected
      final result = await _faceDetectionService.detectFaceDetails(image);

      if (!result.hasFace) {
        // No face detected - show error dialog
        await _showNoFaceDialog();
        setState(() {
          _selectedImage = null;
          _isDetectingFace = false;
        });
        return;
      }

      // Face detected - proceed
      setState(() {
        _isDetectingFace = false;
      });
      
      // Show success message
      _showSnackBar(
        '✅ Face detected! ${result.faceCount > 1 ? '(${result.faceCount} faces found)' : ''}',
        Colors.green,
      );
    } catch (e) {
      setState(() {
        _isDetectingFace = false;
        _selectedImage = null;
      });
      _showSnackBar('Error detecting face: $e', Colors.red);
    }
  }

  // ===========================================================================
  // PHOTO INSTRUCTIONS DIALOG
  // ===========================================================================

  Future<void> _showPhotoInstructions() async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFF2845C), size: 28),
            const SizedBox(width: 10),
            Text(
              'Photo Tips',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInstructionItem(
              icon: Icons.face,
              text: 'Use a photo with the face facing straight on',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              icon: Icons.remove_red_eye,
              text: 'Make sure nothing is obstructing the face',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              icon: Icons.brightness_6,
              text: 'Ensure lighting is not too dim or too bright',
              color: Colors.yellow,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2845C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Upload Photo',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // NO FACE DETECTED DIALOG
  // ===========================================================================

  Future<void> _showNoFaceDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 10),
            Text(
              'No Face Detected',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'There was no face detected in the photo uploaded. Please try a different photo following the instructions.',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2845C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SKIN ANALYSIS
  // ===========================================================================

  // lib/screens/customer/ar_ai_analysis_screen.dart
// (Only showing the updated _analyzeSkin method and related parts)

// In the _analyzeSkin method, add better error handling:

Future<void> _analyzeSkin() async {
  if (_selectedImage == null) {
    _showSnackBar('Please select a photo first', Colors.orange);
    return;
  }

  // Check if face exists
  setState(() => _isDetectingFace = true);
  final result = await _faceDetectionService.detectFaceDetails(_selectedImage!);
  setState(() => _isDetectingFace = false);

  if (!result.hasFace) {
    await _showNoFaceDialog();
    setState(() => _selectedImage = null);
    return;
  }

  setState(() => _isAnalyzing = true);

  try {
    // Try to analyze with Gemini API
    SkinAnalysisResult? analysis;
    
    try {
      analysis = await GeminiService.analyzeSkin(_selectedImage!);
    } catch (e) {
      print('❌ Gemini analysis error: $e');
    }

    // If API fails, use demo analysis
    if (analysis == null) {
      print('⚠️ Using demo analysis (API failed or invalid key)');
      analysis = GeminiService.getDemoAnalysis(_selectedImage!);
      _showSnackBar(
        '⚠️ Using demo mode. Please check API key configuration.', 
        Colors.orange
      );
    }

    setState(() {
      _currentAnalysis = analysis;
      _showAROverlay = true;
    });
    
    await _saveAnalysis(analysis);
    _showSnackBar('✅ Analysis complete!', Colors.green);
    
  } catch (e) {
    print('❌ Analysis error: $e');
    _showSnackBar('Error: ${e.toString()}', Colors.red);
    
    // Fallback: use demo analysis
    final fallbackAnalysis = GeminiService.getDemoAnalysis(_selectedImage!);
    setState(() {
      _currentAnalysis = fallbackAnalysis;
      _showAROverlay = true;
    });
    await _saveAnalysis(fallbackAnalysis);
    _showSnackBar('✅ Using demo analysis', Colors.orange);
    
  } finally {
    setState(() => _isAnalyzing = false);
  }
}

  // ===========================================================================
  // CHAT FUNCTIONALITY
  // ===========================================================================

  void _sendChatMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(text: text, isUser: true);
    setState(() {
      _chatMessages.insert(0, userMessage);
      _messageController.clear();
      _isChatLoading = true;
    });

    try {
      String context = '';
      if (_currentAnalysis != null) {
        context = '''
Skin Tone: ${_currentAnalysis!.skinTone}
Skin Type: ${_currentAnalysis!.skinType}
Concerns: ${_currentAnalysis!.concerns.join(', ')}
Recommended Products: ${_currentAnalysis!.recommendations.skincare.join(', ')}
''';
      }

      final response = await GeminiService.sendChatMessage(text, context: context);

      setState(() {
        _chatMessages.insert(0, ChatMessage(text: response, isUser: false));
        _isChatLoading = false;
      });
    } catch (e) {
      setState(() {
        _chatMessages.insert(0, ChatMessage(
          text: 'I apologize, but I\'m having trouble connecting. Please try again.',
          isUser: false,
        ));
        _isChatLoading = false;
      });
    }
  }

  // ===========================================================================
  // UI HELPERS
  // ===========================================================================

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFF2845C)),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Use camera for analysis',
                  style: TextStyle(color: Colors.white54)),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFF2845C)),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Select existing photo',
                  style: TextStyle(color: Colors.white54)),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareResults() async {
    if (_currentAnalysis == null) return;
    _showSnackBar('Share feature coming soon!', Colors.blue);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0A14),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // ===========================================================================
  // APP BAR
  // ===========================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF2845C), Color(0xFFF5A97F)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'AI Beauty Studio',
            style: GoogleFonts.cormorantGaramond(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1A2A5A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isChatMode ? Icons.analytics_outlined : Icons.chat_outlined,
            color: Colors.white70,
          ),
          onPressed: () => setState(() => _isChatMode = !_isChatMode),
          tooltip: _isChatMode ? 'Analysis Mode' : 'Chat Mode',
        ),
        if (_currentAnalysis != null)
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white70),
            onPressed: _shareResults,
          ),
      ],
    );
  }

  // ===========================================================================
  // BODY
  // ===========================================================================

  Widget _buildBody() {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              color: const Color(0xFF1A2A5A).withOpacity(0.3),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFF2845C),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(icon: Icon(Icons.analytics), text: 'Analysis'),
                  Tab(icon: Icon(Icons.history), text: 'History'),
                  Tab(icon: Icon(Icons.trending_up), text: 'Progress'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAnalysisTab(),
                  _buildHistoryTab(),
                  _buildProgressTab(),
                ],
              ),
            ),
          ],
        ),
        if (_isChatMode) _buildChatOverlay(),
      ],
    );
  }

  // ===========================================================================
  // ANALYSIS TAB
  // ===========================================================================

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageUploadArea(),
          const SizedBox(height: 16),
          _buildActionButtons(),
          const SizedBox(height: 16),
          if (_isDetectingFace) _buildDetectingFaceIndicator(),
          if (_currentAnalysis != null) ...[
            SkinResultsCard(analysis: _currentAnalysis!),
            const SizedBox(height: 16),
            if (_showAROverlay) _buildAROverlay(),
          ],
          if (_isAnalyzing) _buildLoadingIndicator(),
        ],
      ),
    );
  }

  // ===========================================================================
  // IMAGE UPLOAD AREA
  // ===========================================================================

  Widget _buildImageUploadArea() {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(),
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedImage != null
                ? const Color(0xFFF2845C).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
          boxShadow: _selectedImage != null
              ? [
                  BoxShadow(
                    color: const Color(0xFFF2845C).withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: _selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                  if (_isCameraMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Camera',
                                style: TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _showImageSourceDialog(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.face_retouching_natural, size: 48, color: Colors.white38),
                  const SizedBox(height: 12),
                  Text(
                    'Upload Photo',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to upload or take a photo',
                    style: GoogleFonts.poppins(
                      color: Colors.white24,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ===========================================================================
  // ACTION BUTTONS
  // ===========================================================================

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library, size: 18),
            label: const Text('Gallery'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Camera'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: (_isAnalyzing || _selectedImage == null || _isDetectingFace)
                ? null
                : _analyzeSkin,
            icon: _isAnalyzing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.analytics, size: 18),
            label: Text(
              _isAnalyzing ? 'Analyzing...' : 'Analyze Skin',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2845C),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // DETECTING FACE INDICATOR
  // ===========================================================================

  Widget _buildDetectingFaceIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFFD700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Detecting face in photo...',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOADING INDICATOR
  // ===========================================================================

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFFF2845C),
            strokeWidth: 2,
          ),
          const SizedBox(height: 12),
          Text(
            'Analyzing your skin...',
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This may take a few seconds',
            style: GoogleFonts.poppins(
              color: Colors.white24,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // AR OVERLAY
  // ===========================================================================

  Widget _buildAROverlay() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C2B7A).withOpacity(0.3),
              const Color(0xFFF2845C).withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF2845C).withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2845C).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.view_in_ar,
                    color: Color(0xFFF2845C),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AR Recommendation Overlay',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Visualize recommended looks in real-time',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                  onPressed: () => setState(() => _showAROverlay = false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildAROverlayChip(
                  color: const Color(0xFFFF6B81),
                  label: '${_currentAnalysis!.glowScore}/10',
                  subtitle: 'Glow Score',
                ),
                const SizedBox(width: 8),
                _buildAROverlayChip(
                  color: const Color(0xFFF2845C),
                  label: _currentAnalysis!.bestLooks.isNotEmpty
                      ? _currentAnalysis!.bestLooks[0]
                      : 'Natural',
                  subtitle: 'Best Look',
                ),
                const SizedBox(width: 8),
                _buildAROverlayChip(
                  color: const Color(0xFF4CAF50),
                  label: '${_currentAnalysis!.health.hydration}%',
                  subtitle: 'Hydration',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/virtual_makeup',
                    arguments: _currentAnalysis!.recommendations.toJson(),
                  );
                },
                icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                label: Text(
                  'Try AR Makeup Now',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2845C),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAROverlayChip({
    required Color color,
    required String label,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HISTORY TAB (Same as before - keeping concise)
  // ===========================================================================

  Widget _buildHistoryTab() {
    if (_analysisHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'No Analysis History',
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first skin analysis to see history',
              style: GoogleFonts.poppins(
                color: Colors.white24,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2845C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Analyze Now'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _analysisHistory.length,
      itemBuilder: (context, index) {
        final analysis = _analysisHistory[index];
        final isSelected = _selectedHistoryIndex == index;

        return GestureDetector(
          onTap: () => setState(() {
            _selectedHistoryIndex = isSelected ? -1 : index;
            if (isSelected) {
              _currentAnalysis = null;
            } else {
              _currentAnalysis = SkinAnalysisResult.fromJson(analysis);
              _tabController.animateTo(0);
            }
          }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF2845C).withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFF2845C)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2845C).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.analytics_outlined,
                      color: const Color(0xFFF2845C),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${analysis['skinTone'] ?? 'N/A'} • ${analysis['skinType'] ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Glow: ${analysis['glowScore'] ?? 0}/10 • ${DateFormat('MMM dd, yyyy').format(DateTime.parse(analysis['timestamp']))}',
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (analysis['confidence'] ?? 0) > 80
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${analysis['confidence'] ?? 0}%',
                        style: GoogleFonts.poppins(
                          color: (analysis['confidence'] ?? 0) > 80
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 18),
                      onPressed: () => _deleteAnalysis(analysis['id']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // PROGRESS TAB
  // ===========================================================================

  Widget _buildProgressTab() {
    if (_analysisHistory.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Need More Data',
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete at least 2 analyses to see progress',
              style: GoogleFonts.poppins(
                color: Colors.white24,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final sortedHistory = List<Map<String, dynamic>>.from(_analysisHistory)
      ..sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressCard(
            title: 'Glow Score Progress',
            data: sortedHistory.map((item) {
              return {
                'label': DateFormat('MMM dd').format(DateTime.parse(item['timestamp'])),
                'value': (item['glowScore'] ?? 0).toDouble(),
                'color': const Color(0xFFF2845C),
              };
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildProgressCard(
            title: 'Skin Health Progress',
            data: sortedHistory.map((item) {
              final health = item['skinHealth'] ?? {};
              final avg = ((health['hydration'] ?? 0) +
                      (health['elasticity'] ?? 0) +
                      (health['evenness'] ?? 0)) /
                  3;
              return {
                'label': DateFormat('MMM dd').format(DateTime.parse(item['timestamp'])),
                'value': avg,
                'color': Colors.green,
              };
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildSummaryStats(),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required List<Map<String, dynamic>> data,
  }) {
    final maxValue = data.fold(0.0, (max, item) => item['value'] > max ? item['value'] : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data.map((item) {
              final value = item['value'];
              final label = item['label'];
              final color = item['color'] as Color;

              return Column(
                children: [
                  Container(
                    width: 30,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          height: (value / (maxValue + 2)) * 90,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${value.round()}',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 8,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    final sortedHistory = List<Map<String, dynamic>>.from(_analysisHistory)
      ..sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));

    final first = sortedHistory.first;
    final last = sortedHistory.last;

    final glowChange = (last['glowScore'] ?? 0) - (first['glowScore'] ?? 0);
    final confidenceChange = (last['confidence'] ?? 0) - (first['confidence'] ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A2A5A).withOpacity(0.3),
            const Color(0xFF0E0A14).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Summary',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                label: 'Glow Score',
                value: last['glowScore']?.toString() ?? 'N/A',
                change: glowChange,
                icon: Icons.star,
              ),
              _buildStatItem(
                label: 'Confidence',
                value: '${last['confidence'] ?? 0}%',
                change: confidenceChange,
                icon: Icons.trending_up,
              ),
              _buildStatItem(
                label: 'Analyses',
                value: '${_analysisHistory.length}',
                change: _analysisHistory.length,
                icon: Icons.history,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required dynamic change,
    required IconData icon,
  }) {
    final isPositive = change is num && change > 0;
    final changeText = change is num ? (change > 0 ? '+$change' : change.toString()) : '';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFF2845C), size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
            if (changeText.isNotEmpty)
              Text(
                changeText,
                style: GoogleFonts.poppins(
                  color: isPositive ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CHAT OVERLAY (Fixed Bottom Overflow)
  // ===========================================================================

  Widget _buildChatOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Chat Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A4A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2845C).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFF2845C),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Beauty Advisor',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _currentAnalysis != null
                              ? 'Analyzing your skin data'
                              : 'Ask me anything',
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => setState(() => _isChatMode = false),
                  ),
                ],
              ),
            ),

            // Chat Messages
            Expanded(
              child: _chatMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_outlined, size: 40, color: Colors.white24),
                          const SizedBox(height: 8),
                          Text(
                            'Ask about your skin analysis',
                            style: GoogleFonts.poppins(
                              color: Colors.white24,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'or get beauty advice',
                            style: GoogleFonts.poppins(
                              color: Colors.white24,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      itemCount: _chatMessages.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        final msg = _chatMessages[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          alignment: msg.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: msg.isUser
                                  ? const Color(0xFFF2845C)
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: Text(
                              msg.text,
                              style: GoogleFonts.poppins(
                                color: msg.isUser ? Colors.white : Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Chat Loading Indicator
            if (_isChatLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2845C).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF2845C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI is thinking...',
                      style: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Message Input
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A4A),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ask about your analysis...',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: _sendChatMessage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2845C),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: () => _sendChatMessage(_messageController.text),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}