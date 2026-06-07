import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ARExperienceCarousel extends StatelessWidget {
  const ARExperienceCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "AR Experiences",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text("Try Now", style: TextStyle(color: Color(0xFFF2845C))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _getExperiences().length,
              itemBuilder: (context, index) {
                final ar = _getExperiences()[index];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, ar['route'] as String),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (ar['color'] as Color).withOpacity(0.9),
                          (ar['color'] as Color).withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (ar['color'] as Color).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(ar['icon'] as IconData, color: ar['color'] as Color, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ar['name'] as String,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getExperiences() {
    return [
      {'name': 'Virtual Makeup', 'icon': Icons.face_retouching_natural, 'color': const Color(0xFF0984E3), 'route': '/virtual-makeup'},
      {'name': 'Live AR Suite', 'icon': Icons.flash_on, 'color': const Color(0xFFD91A5B), 'route': '/quick-ar'},
      {'name': 'Henna Studio', 'icon': Icons.brush, 'color': const Color(0xFF8B3A0F), 'route': '/henna'},
      {'name': 'Jewelry Try-On', 'icon': Icons.diamond, 'color': const Color(0xFFF2845C), 'route': '/jewelry'},
    ];
  }
}