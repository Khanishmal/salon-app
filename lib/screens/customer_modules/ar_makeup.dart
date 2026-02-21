// lib/screens/customer_modules/ar_makeup.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class ARMakeupScreen extends StatefulWidget {
  const ARMakeupScreen({super.key});

  @override
  State<ARMakeupScreen> createState() => _ARMakeupScreenState();
}

class _ARMakeupScreenState extends State<ARMakeupScreen> {
  int _selectedCategory = 0;
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Lipstick', 'icon': Icons.face, 'colors': [
      Colors.red, Colors.pink, Colors.purple, Colors.orange, Colors.brown
    ]},
    {'name': 'Eyeshadow', 'icon': Icons.visibility, 'colors': [
      Colors.brown, Colors.grey, Colors.purple, Colors.blue, Colors.green
    ]},
    {'name': 'Blush', 'icon': Icons.favorite, 'colors': [
      Color(0xFFFFB6C1), Color(0xFFFF69B4), Color(0xFFFF1493)
    ]},
    {'name': 'Foundation', 'icon': Icons.face_retouching_natural, 'colors': [
      Color(0xFFF5DEB3), Color(0xFFDEB887), Color(0xFFD2B48C), Color(0xFFBC8F8F)
    ]},
  ];

  final List<Map<String, dynamic>> _accessories = [
    {'name': 'Nath', 'icon': '💍'},
    {'name': 'Jhumka', 'icon': '✨'},
    {'name': 'Tikka', 'icon': '💎'},
    {'name': 'Mehndi', 'icon': '🌸'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Placeholder for Unity View
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeIn(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF2845C), width: 3),
                      ),
                      child: const Icon(
                        Icons.face_retouching_natural,
                        size: 100,
                        color: Color(0xFFF2845C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Unity AR View",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Face detection ready",
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Bar
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.save, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Category Tabs
                Container(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: _selectedCategory == index
                                ? const Color(0xFFF2845C)
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _categories[index]['icon'],
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _categories[index]['name'],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Color Palette
                Container(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories[_selectedCategory]['colors'].length,
                    itemBuilder: (context, index) {
                      Color color = _categories[_selectedCategory]['colors'][index];
                      return Container(
                        width: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Accessories
                Container(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _accessories.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            _accessories[index]['icon'],
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF2845C),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Book with this look',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Buy products',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}