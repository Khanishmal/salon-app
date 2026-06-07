import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  
  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? const Color(0xFFF2845C);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: buttonColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: buttonColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: buttonColor, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: buttonColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}