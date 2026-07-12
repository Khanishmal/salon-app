// lib/widgets/skin_analysis_widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/skin_analysis_models.dart';

// ===========================================================================
// RESULTS CARD
// ===========================================================================

class SkinResultsCard extends StatelessWidget {
  final SkinAnalysisResult analysis;

  const SkinResultsCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A2A5A).withOpacity(0.3),
            const Color(0xFF0E0A14).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF2845C).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(color: Colors.white24, height: 24),
          _buildSkinDetails(),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          _buildHealthMetrics(),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          _buildRecommendations(),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          _buildStyleSuggestions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.analytics_outlined, color: Color(0xFFF2845C), size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Analysis Results',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${DateFormat('MMM dd, yyyy').format(DateTime.parse(analysis.analysisDate))} • ${analysis.photoSource}',
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF2845C).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${analysis.confidence}%',
            style: GoogleFonts.poppins(
              color: const Color(0xFFF2845C),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkinDetails() {
    return Row(
      children: [
        _buildInfoChip(
          label: 'Skin Tone',
          value: analysis.skinTone,
          icon: Icons.palette_outlined,
          color: const Color(0xFFF2845C),
        ),
        const SizedBox(width: 12),
        _buildInfoChip(
          label: 'Skin Type',
          value: analysis.skinType,
          icon: Icons.water_drop_outlined,
          color: Colors.blueAccent,
        ),
        const SizedBox(width: 12),
        _buildInfoChip(
          label: 'Age',
          value: '${analysis.ageEstimate}',
          icon: Icons.cake_outlined,
          color: Colors.pinkAccent,
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              'Skin Health Metrics',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildHealthBar(
              label: 'Hydration',
              value: analysis.health.hydration.toDouble(),
              color: Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildHealthBar(
              label: 'Elasticity',
              value: analysis.health.elasticity.toDouble(),
              color: Colors.green,
            ),
            const SizedBox(width: 12),
            _buildHealthBar(
              label: 'Evenness',
              value: analysis.health.evenness.toDouble(),
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthBar({
    required String label,
    required double value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
              Text(
                '${value.round()}%',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.recommend_outlined, color: Color(0xFFF2845C), size: 20),
            const SizedBox(width: 8),
            Text(
              'Personalized Recommendations',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF2845C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildRecommendationTile(
          label: 'Lipstick',
          value: analysis.recommendations.lipstick.join(' · '),
          icon: Icons.format_color_fill,
        ),
        _buildRecommendationTile(
          label: 'Blush',
          value: analysis.recommendations.blush,
          icon: Icons.face,
        ),
        _buildRecommendationTile(
          label: 'Eyeshadow',
          value: analysis.recommendations.eyeshadow,
          icon: Icons.remove_red_eye,
        ),
        _buildRecommendationTile(
          label: 'Foundation',
          value: analysis.recommendations.foundation,
          icon: Icons.spa,
        ),
        _buildRecommendationTile(
          label: 'Skincare',
          value: analysis.recommendations.skincare.join(' → '),
          icon: Icons.health_and_safety,
        ),
        _buildRecommendationTile(
          label: 'Hairstyle',
          value: analysis.recommendations.hairStyle,
          icon: Icons.content_cut,
        ),
      ],
    );
  }

  Widget _buildRecommendationTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.style, color: Color(0xFFFFD700), size: 20),
            const SizedBox(width: 8),
            Text(
              'Style Inspiration',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: analysis.bestLooks.map((look) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF2845C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFF2845C).withOpacity(0.3),
                ),
              ),
              child: Text(
                '✨ $look',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFF2845C),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 12),
              Text(
                'Celebrity Match: ${analysis.celebrityMatch}',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// HISTORY ITEM
// ===========================================================================

class HistoryItemWidget extends StatelessWidget {
  final Map<String, dynamic> analysis;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HistoryItemWidget({
    super.key,
    required this.analysis,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}