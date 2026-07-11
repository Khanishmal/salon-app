//lib/services/salon_location_sync.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_service.dart';

/// Keeps vendor profile coordinates in sync with the salons map collection.
class SalonLocationSync {
  static Future<void> syncVendorSalon({
    required String vendorId,
    required Map<String, dynamic> vendorData,
    LatLng? coordinates,
  }) async {
    final address = (vendorData['address'] ?? '').toString().trim();
    final coords = coordinates ?? LocationService.parseCoordinates(vendorData);

    final payload = <String, dynamic>{
      'vendorId': vendorId,
      'name': vendorData['businessName'] ?? vendorData['name'] ?? 'Salon',
      'address': address,
      'rating': vendorData['rating'] ?? 0.0,
      'imageUrl': vendorData['profileImageUrl'] ?? vendorData['imageUrl'] ?? '',
      'phone': vendorData['phone'] ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (coords != null) {
      payload['latitude'] = coords.latitude;
      payload['longitude'] = coords.longitude;
    }

    await FirebaseFirestore.instance
        .collection('salons')
        .doc(vendorId)
        .set(payload, SetOptions(merge: true));

    if (coords != null) {
      await FirebaseFirestore.instance.collection('users').doc(vendorId).update({
        'latitude': coords.latitude,
        'longitude': coords.longitude,
      });
    }
  }
}
