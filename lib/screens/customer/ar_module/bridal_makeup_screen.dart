import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class BridalMakeupScreen extends StatefulWidget {
  const BridalMakeupScreen({super.key});

  @override
  State<BridalMakeupScreen> createState() => _BridalMakeupScreenState();
}

class _BridalMakeupScreenState extends State<BridalMakeupScreen> {
  // ===========================================================================
  // STATE MANAGEMENT
  // ===========================================================================
  
  File? _sourceImage;
  bool _isProcessing = false;
  bool _showComparison = false;
  String? _errorMessage;
  String? _aiStyleBreakdown;
  bool _isFaceDetected = false;
  int _selectedStyleIndex = 0;

  // ===========================================================================
  // BRIDAL STYLES - Using Asset Images only for AFTER view
  // ===========================================================================
  
  final List<Map<String, dynamic>> _bridalStyles = [
    {
      'name': 'Royal Red',
      'image': 'assets/bridal/royal_red.jfif',
      'emoji': '👑',
      'icon': '👰',
      'color': const Color(0xFF8B0000),
      'bgColor': Color(0xFFF5E6E6),
      'description': 'Traditional red bridal look with gold jewelry and heavy embroidery',
      'details': '''
💄 **Royal Red Bridal Look**

A classic traditional Pakistani bridal look featuring:
• Deep red lehenga with heavy gold embroidery
• Traditional gold Jhoomar and Maang Tikka
• Classic bridal makeup with red lips
• Elegant dupatta drape with gold border
• Complete traditional bridal jewelry set

Perfect for: Traditional weddings, formal events
''',
    },
    {
      'name': 'Rose Gold',
      'image': 'assets/bridal/rose_gold.png',
      'emoji': '🌹',
      'icon': '💗',
      'color': const Color(0xFFD4A574),
      'bgColor': Color(0xFFF5EDE6),
      'description': 'Modern rose gold bridal with soft glam makeup',
      'details': '''
💄 **Rose Gold Bridal Look**

A contemporary yet elegant bridal look featuring:
• Rose gold lehenga with delicate floral work
• Modern lightweight jewelry
• Soft glam bridal makeup
• Sheer dupatta with rose gold detailing
• Subtle and sophisticated styling

Perfect for: Day weddings, garden ceremonies
''',
    },
    {
      'name': 'Pearl Glow',
      'image': 'assets/bridal/pearl_glow.jfif',
      'emoji': '✨',
      'icon': '🕊️',
      'color': const Color(0xFFE8DDD0),
      'bgColor': Color(0xFFF5F0EB),
      'description': 'Elegant pearl-inspired bridal with ethereal glow',
      'details': '''
💄 **Pearl Glow Bridal Look**

A dreamy ethereal bridal look featuring:
• Pearl white/ivory outfit with subtle shimmer
• Pearl jewelry with minimal design
• Dewy bridal makeup with pearl highlighter
• Soft flowing dupatta
• Angelic and glowing appearance

Perfect for: Night weddings, formal events
''',
    },
    {
      'name': 'Maharanee',
      'image': 'assets/bridal/maharanee.png',
      'emoji': '👸',
      'icon': '💎',
      'color': const Color(0xFF2D1B4E),
      'bgColor': Color(0xFFE8E0F0),
      'description': 'Royal Maharanee style with heavy traditional jewelry',
      'details': '''
💄 **Maharanee Bridal Look**

A royal and majestic bridal look featuring:
• Rich velvet or silk outfit with zardozi
• Heavy traditional jewelry including Rani Haar
• Royal makeup with bold eyes
• Majestic dupatta with gold border
• Complete regal bridal ensemble

Perfect for: Royal weddings, grand celebrations
''',
    },
  ];

  final ImagePicker _picker = ImagePicker();
  late FaceDetector _faceDetector;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  // ===========================================================================
  // IMAGE PICKING
  // ===========================================================================
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        final inputImage = InputImage.fromFile(file);
        final faces = await _faceDetector.processImage(inputImage);
        
        setState(() {
          _sourceImage = file;
          _isFaceDetected = faces.isNotEmpty;
          _showComparison = false;
          _errorMessage = null;
          _aiStyleBreakdown = null;
        });

        if (!_isFaceDetected) {
          _showErrorDialog(
            'No Face Detected',
            'Please upload a clear front-facing portrait photo.'
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "Failed to select image: $e");
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RESET
  // ===========================================================================

  void _resetAll() {
    setState(() {
      _sourceImage = null;
      _showComparison = false;
      _aiStyleBreakdown = null;
      _errorMessage = null;
      _isFaceDetected = false;
    });
  }

  // ===========================================================================
  // APPLY BRIDAL STYLE
  // ===========================================================================
  
  void _applyBridalStyle() {
    if (_sourceImage == null) {
      setState(() => _errorMessage = "Please upload a portrait image first.");
      return;
    }

    if (!_isFaceDetected) {
      _showErrorDialog(
        'No Face Detected',
        'Please upload a photo with a clear face.'
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Simulate processing delay for better UX
    Future.delayed(const Duration(seconds: 2), () {
      final style = _bridalStyles[_selectedStyleIndex];
      setState(() {
        _showComparison = true;
        _aiStyleBreakdown = style['details'];
        _isProcessing = false;
      });
    });
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF2D1B4E);
    final accentColor = const Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        title: Text(
          'BRIDAL STYLES',
          style: GoogleFonts.marcellus(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        backgroundColor: themeColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _resetAll,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWorkspace(accentColor, themeColor),
            const SizedBox(height: 16),

            if (_sourceImage != null)
              _buildFaceDetectionStatus(),

            if (_errorMessage != null) _buildErrorWidget(),

            if (!_isProcessing) ...[
              _buildStyleSelector(accentColor),
            ],

            const SizedBox(height: 20),

            if (_isProcessing)
              _buildProcessingIndicator(themeColor, accentColor)
            else
              _buildApplyButton(themeColor, accentColor),

            if (_aiStyleBreakdown != null && !_isProcessing) ...[
              const SizedBox(height: 16),
              _buildStyleBreakdown(accentColor, themeColor),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WORKSPACE
  // ===========================================================================

  Widget _buildWorkspace(Color accentColor, Color themeColor) {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_sourceImage == null)
            _buildUploadPlaceholder(themeColor)
          else if (_showComparison)
            _buildBeforeAfterView(accentColor)
          else
            _buildSingleImageView(accentColor),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder(Color themeColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.face_retouching_natural,
          size: 70,
          color: themeColor.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          'Upload Your Photo',
          style: GoogleFonts.marcellus(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: themeColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Try different Pakistani bridal styles',
          style: GoogleFonts.lato(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUploadButton(
              Icons.photo_library,
              'Gallery',
              () => _pickImage(ImageSource.gallery),
              themeColor,
            ),
            const SizedBox(width: 12),
            _buildUploadButton(
              Icons.camera_alt,
              'Camera',
              () => _pickImage(ImageSource.camera),
              themeColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBeforeAfterView(Color accentColor) {
    final style = _bridalStyles[_selectedStyleIndex];
    
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Image.file(_sourceImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              _buildBadge('BEFORE', Colors.black54),
            ],
          ),
        ),
        Container(
          width: 3,
          color: accentColor,
          child: const Center(
            child: Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Image.asset(
                style['image'],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              _buildBadge('AFTER', const Color(0xFFD4AF37)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleImageView(Color accentColor) {
    return Stack(
      children: [
        Image.file(_sourceImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: accentColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Select a bridal style and apply',
                  style: GoogleFonts.lato(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // FACE DETECTION STATUS
  // ===========================================================================

  Widget _buildFaceDetectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _isFaceDetected 
            ? Colors.green.withOpacity(0.08) 
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFaceDetected 
              ? Colors.green.withOpacity(0.2) 
              : Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isFaceDetected ? Icons.check_circle : Icons.warning,
            color: _isFaceDetected ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            _isFaceDetected 
                ? '✅ Face detected - Ready' 
                : '⚠️ No face detected',
            style: GoogleFonts.lato(
              color: _isFaceDetected ? Colors.green : Colors.orange,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STYLE SELECTOR - Professional Cards with Emojis
  // ===========================================================================

  Widget _buildStyleSelector(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.style, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Select Bridal Style',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: _bridalStyles.length,
            itemBuilder: (context, index) {
              final style = _bridalStyles[index];
              final isSelected = _selectedStyleIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedStyleIndex = index),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (style['bgColor'] as Color) 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected 
                          ? style['color'] as Color 
                          : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (style['color'] as Color).withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Large Emoji Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected 
                              ? (style['color'] as Color).withOpacity(0.12) 
                              : Colors.grey.shade50,
                        ),
                        child: Center(
                          child: Text(
                            style['emoji'],
                            style: const TextStyle(
                              fontSize: 30,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        style['name'],
                        style: GoogleFonts.lato(
                          color: isSelected ? Colors.black87 : Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        style['description'].split(' with')[0],
                        style: GoogleFonts.lato(
                          color: isSelected ? Colors.grey.shade700 : Colors.grey.shade500,
                          fontSize: 9,
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor,
                                accentColor.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'SELECTED',
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 8,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tap',
                                style: GoogleFonts.lato(
                                  color: Colors.grey.shade400,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // UPLOAD BUTTON
  // ===========================================================================

  Widget _buildUploadButton(
    IconData icon,
    String label,
    VoidCallback action,
    Color themeColor,
  ) {
    return ElevatedButton.icon(
      onPressed: action,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor.withOpacity(0.08),
        foregroundColor: themeColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ===========================================================================
  // PROCESSING INDICATOR
  // ===========================================================================

  Widget _buildProcessingIndicator(Color themeColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF2D1B4E),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Creating your bridal look...',
            style: GoogleFonts.lato(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Preserving your natural features',
            style: GoogleFonts.lato(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            backgroundColor: Colors.grey.shade200,
            color: accentColor,
            minHeight: 3,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // APPLY BUTTON
  // ===========================================================================

  Widget _buildApplyButton(Color themeColor, Color accentColor) {
    return ElevatedButton(
      onPressed: _sourceImage == null || !_isFaceDetected ? null : _applyBridalStyle,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2D1B4E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
        disabledBackgroundColor: Colors.grey.shade300,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showComparison ? Icons.refresh : Icons.auto_awesome,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            _showComparison 
                ? 'Try Different Style ✨' 
                : 'Apply Bridal Style ✨',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STYLE BREAKDOWN
  // ===========================================================================

  Widget _buildStyleBreakdown(Color accentColor, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: accentColor, size: 20),
              const SizedBox(width: 10),
              Text(
                'Style Details',
                style: GoogleFonts.marcellus(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Text(
            _aiStyleBreakdown!,
            style: GoogleFonts.lato(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ERROR WIDGET
  // ===========================================================================

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.lato(
                color: Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}