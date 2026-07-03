import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum LocationAccessStatus {
  granted,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationAccessResult {
  const LocationAccessResult({
    required this.status,
    this.message,
  });

  final LocationAccessStatus status;
  final String? message;

  bool get isGranted => status == LocationAccessStatus.granted;
}

class LocationService {
  static Future<LocationAccessResult> ensureAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationAccessResult(
        status: LocationAccessStatus.serviceDisabled,
        message: 'Location services are disabled. Please turn them on.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationAccessResult(
        status: LocationAccessStatus.permissionDenied,
        message: 'Location permission denied. Allow access to find nearby salons.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationAccessResult(
        status: LocationAccessStatus.permissionDeniedForever,
        message: 'Location permission is blocked. Enable it in app settings.',
      );
    }

    return const LocationAccessResult(status: LocationAccessStatus.granted);
  }

  static Future<LatLng?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown == null) return null;
      return LatLng(lastKnown.latitude, lastKnown.longitude);
    }
  }

  static Future<LatLng?> geocodeAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return null;

    try {
      final results = await locationFromAddress(trimmed);
      if (results.isEmpty) return null;
      final location = results.first;
      return LatLng(location.latitude, location.longitude);
    } catch (_) {
      return null;
    }
  }

  static LatLng? parseCoordinates(Map<String, dynamic> data) {
    final lat = _toDouble(data['latitude']);
    final lng = _toDouble(data['longitude']);
    if (lat == null || lng == null || lat == 0.0 || lng == 0.0) return null;
    return LatLng(lat, lng);
  }

  static double? distanceKm(LatLng? from, Map<String, dynamic> data) {
    final target = parseCoordinates(data);
    if (from == null || target == null) return null;

    return Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          target.latitude,
          target.longitude,
        ) /
        1000.0;
  }

  static Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  static Future<void> openAppSettings() => Geolocator.openAppSettings();

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
