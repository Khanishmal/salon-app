class ProductImageHelper {
  static const Map<String, String> categoryImages = {
    'Lipsticks': 'assets/makeup_icons/lipstick.png',
    'Foundations': 'assets/makeup_icons/foundation.png',
    'Eyeliners': 'assets/makeup_icons/eyeliner.png',
    'Eyeshadow': 'assets/makeup_icons/eyeshadow.png',
    'Blush': 'assets/makeup_icons/blush.png',
    'Bronzer': 'assets/makeup_icons/bronzer.png',
    'Highlighter': 'assets/makeup_icons/highlighter.png',
    'Eyebrow': 'assets/makeup_icons/eyebrow.png',
    'Jewellery': 'assets/makeup_icons/jewellery.png',
    'Hair Accessories': 'assets/makeup_icons/hair_accessories.png',
    'Mehndi Templates': 'assets/makeup_icons/mehndi.png',
    'Makeup Deals': 'assets/makeup_icons/makeup_deals.png',
    'Other': 'assets/makeup_icons/default.png',
  };

  static String getImageForCategory(String category) {
    return categoryImages[category] ?? 'assets/makeup_icons/default.png';
  }

  static bool isMakeupCategory(String category) {
    final makeupCategories = [
      'Lipsticks',
      'Foundations',
      'Eyeliners',
      'Eyeshadow',
      'Blush',
      'Bronzer',
      'Highlighter',
      'Eyebrow',
    ];
    return makeupCategories.contains(category);
  }

  static bool isDealCategory(String category) {
    return category == 'Makeup Deals';
  }

  static String getProductImage(Map<String, dynamic> data) {
    String imageUrl = data['imageUrl'] ?? '';
    String category = data['category'] ?? 'Other';
    
    // If image is already a network URL or custom uploaded, use it
    if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      return imageUrl;
    }
    
    // Otherwise use default category image
    return getImageForCategory(category);
  }
}