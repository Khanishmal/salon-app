class SalonModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String? phone;
  final double rating;
  final String description;
  final bool isActive;
  final String category;
  final double latitude;
  final double longitude;
  final List<String> services;
  final String? imageUrl;
  final double? distance;

  SalonModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.phone,
    required this.rating,
    required this.description,
    required this.isActive,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.services,
    this.imageUrl,
    this.distance,
  });

  factory SalonModel.fromMap(String id, Map<String, dynamic> data) {
    return SalonModel(
      id: id,
      name: data['name'] ?? 'Salon',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      phone: data['phone'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      category: data['category'] ?? 'General',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      services: List<String>.from(data['services'] ?? []),
      imageUrl: data['imageUrl'],
      distance: data['distance'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'phone': phone,
      'rating': rating,
      'description': description,
      'isActive': isActive,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'services': services,
      'imageUrl': imageUrl,
    };
  }
}

class SalonRecommendation {
  final String salonName;
  final String reason;
  final double matchScore;
  final List<String> bestServices;

  SalonRecommendation({
    required this.salonName,
    required this.reason,
    required this.matchScore,
    required this.bestServices,
  });

  factory SalonRecommendation.fromJson(Map<String, dynamic> json) {
    return SalonRecommendation(
      salonName: json['salonName'] ?? '',
      reason: json['reason'] ?? '',
      matchScore: (json['matchScore'] ?? 0).toDouble(),
      bestServices: List<String>.from(json['bestServices'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'salonName': salonName,
      'reason': reason,
      'matchScore': matchScore,
      'bestServices': bestServices,
    };
  }
}