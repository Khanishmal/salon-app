// lib/utils/makeup_indices.dart

class MakeupIndices {
  // Outer perimeter loop of the lips
  static const List<int> outerLips = [
    61, 146, 91, 181, 84, 17, 314, 405, 321, 375,
    291, 308, 324, 318, 402, 317, 14, 87, 178, 88, 95, 78
  ];

  // Inner perimeter loop of the lips (for precise inner line containment)
  static const List<int> innerLips = [
    78, 191, 80, 81, 82, 13, 312, 311, 310, 415, 
    308, 324, 318, 402, 317, 14, 87, 178, 88, 95
  ];

  // Left and Right eye contours for eyeshadow shading application
  static const List<int> leftEyeShadow = [226, 247, 30, 29, 27, 28, 56, 190, 243, 112, 26, 22, 23, 24, 110, 157];
  static const List<int> rightEyeShadow = [463, 414, 286, 258, 257, 259, 260, 467, 341, 256, 252, 253, 254, 339, 384, 385];

  // Cheek clusters centers for applying soft round blush effects
  static const int leftCheekCenter = 117;
  static const int rightCheekCenter = 346;
}