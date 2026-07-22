import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/geo_math.dart';

class SalonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current location with permission handling
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Stream salons within radius using bounding box filter
  Stream<List<Map<String, dynamic>>> streamNearbySalons(Position userPos, double radiusInKm) {
    final bounds = GeoMath.getBoundingBox(
      userPos.latitude,
      userPos.longitude,
      radiusInKm,
    );

    return _firestore
        .collection('salons')
        .where('isActive', isEqualTo: true)
        .where('latitude', isGreaterThanOrEqualTo: bounds['minLat'])
        .where('latitude', isLessThanOrEqualTo: bounds['maxLat'])
        .snapshots()
        .map((snapshot) {
          final filtered = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
              .where((salon) {
                final double? lng = salon['longitude'] as double?;
                final double? lat = salon['latitude'] as double?;
                
                if (lat == null || lng == null) return false;
                
                // Check longitude bounds
                final isInLngBounds = lng >= bounds['minLng']! && lng <= bounds['maxLng']!;
                
                // Verify actual distance
                if (isInLngBounds) {
                  final distance = GeoMath.calculateDistance(
                    userPos.latitude,
                    userPos.longitude,
                    lat,
                    lng,
                  );
                  return distance <= radiusInKm;
                }
                
                return false;
              })
              .toList();

          return filtered;
        });
  }

  /// Get a single salon by ID
  Future<Map<String, dynamic>?> getSalonById(String id) async {
    final doc = await _firestore.collection('salons').doc(id).get();
    if (doc.exists) {
      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    }
    return null;
  }
}