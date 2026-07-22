import 'dart:math';

class GeoMath {
  /// Generates a bounding box around a center point (lat, lng) for a given radius in km
  static Map<String, double> getBoundingBox(double lat, double lng, double radiusInKm) {
    const double latDegreePerKm = 1.0 / 111.045;
    final double lngDegreePerKm = 1.0 / (111.045 * cos(lat * pi / 180).abs());

    return {
      'minLat': lat - (radiusInKm * latDegreePerKm),
      'maxLat': lat + (radiusInKm * latDegreePerKm),
      'minLng': lng - (radiusInKm * lngDegreePerKm),
      'maxLng': lng + (radiusInKm * lngDegreePerKm),
    };
  }

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}