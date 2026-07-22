import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

enum LocationAccessStatus {
  granted,
  denied,
  serviceDisabled,
  permissionDeniedForever,
  notDetermined,
}

class LocationAccessResult {
  final LocationAccessStatus status;
  final String? message;

  const LocationAccessResult({required this.status, this.message});

  bool get isGranted => status == LocationAccessStatus.granted;
}

class LocationService {
  static Future<LocationAccessResult> ensureAccess() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationAccessResult(
          status: LocationAccessStatus.serviceDisabled,
          message: 'Location services are disabled. Please enable them to find nearby salons.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationAccessResult(
            status: LocationAccessStatus.denied,
            message: 'Location permission is required to find nearby salons.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationAccessResult(
          status: LocationAccessStatus.permissionDeniedForever,
          message: 'Location permission is permanently denied. Please enable it in app settings.',
        );
      }

      return const LocationAccessResult(
        status: LocationAccessStatus.granted,
      );
    } catch (e) {
      return LocationAccessResult(
        status: LocationAccessStatus.denied,
        message: 'Error checking location: ${e.toString()}',
      );
    }
  }

  static Future<LatLng?> getCurrentPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting position: $e');
      return null;
    }
  }

  static Future<String?> getAddressFromCoords(LatLng position) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      final parts = <String>[];
      if (place.subLocality != null && place.subLocality!.isNotEmpty) 
        parts.add(place.subLocality!);
      if (place.locality != null && place.locality!.isNotEmpty) 
        parts.add(place.locality!);
      if (place.postalCode != null && place.postalCode!.isNotEmpty) 
        parts.add(place.postalCode!);
      if (place.country != null && place.country!.isNotEmpty) 
        parts.add(place.country!);
      return parts.isNotEmpty ? parts.join(', ') : null;
    }
  } catch (e) {
    print('Error getting address: $e');
  }
  return null;
}

  static Future<LatLng?> geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        return LatLng(loc.latitude, loc.longitude);
      }
    } catch (e) {
      print('Error geocoding address: $e');
    }
    return null;
  }

  // Fixed distance calculation using dart:math
  static double distanceKm(LatLng point1, Map<String, dynamic> point2) {
    const double earthRadius = 6371; // km
    final lat1 = point1.latitude;
    final lon1 = point1.longitude;
    final lat2 = (point2['latitude'] ?? point2['lat']).toDouble();
    final lon2 = (point2['longitude'] ?? point2['lng']).toDouble();

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  static LatLng? parseCoordinates(Map<String, dynamic> data) {
    try {
      final lat = data['latitude'] ?? data['lat'];
      final lng = data['longitude'] ?? data['lng'];
      if (lat != null && lng != null) {
        return LatLng(
          double.parse(lat.toString()),
          double.parse(lng.toString()),
        );
      }
    } catch (_) {}
    return null;
  }
}