// lib/screens/customer/nearby_salons.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/location_service.dart';

class NearbySalonsScreen extends StatefulWidget {
  const NearbySalonsScreen({super.key});

  @override
  State<NearbySalonsScreen> createState() => _NearbySalonsScreenState();
}

class _NearbySalonsScreenState extends State<NearbySalonsScreen> {
  static const _defaultCenter = LatLng(24.8607, 67.0011);

  bool _isMapView = false;
  bool _isLoading = true;
  bool _isGeocodingSearch = false;
  String _statusMessage = 'Finding salons near you...';
  LocationAccessStatus? _accessStatus;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  LatLng? _currentPosition;
  LatLng? _searchCenter;
  GoogleMapController? _mapController;

  List<DocumentSnapshot> _allSalons = [];
  List<DocumentSnapshot> _filteredSalons = [];
  final Map<String, LatLng> _geocodedCoords = {};
  final Set<Marker> _markers = {};

  StreamSubscription<QuerySnapshot>? _salonStreamSubscription;
  bool _isMapInitialized = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initializeLocationAndSalons();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _applyFilteringAndSorting();
    });
  }

  Future<void> _initializeLocationAndSalons() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Getting your location...';
    });

    try {
      final access = await LocationService.ensureAccess();
      _accessStatus = access.status;

      if (access.isGranted) {
        setState(() => _statusMessage = 'Finding your location...');
        final position = await LocationService.getCurrentPosition();
        if (position != null) {
          setState(() {
            _currentPosition = position;
          });
        }
      }

      if (!mounted) return;

      if (_currentPosition == null) {
        _currentPosition = _defaultCenter;
        if (!access.isGranted) {
          _statusMessage = access.message ?? 'Showing default location.';
        } else {
          _statusMessage = 'Could not get GPS fix. Showing default location.';
        }
      }

      _startSalonStream();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  void _startSalonStream() {
    setState(() => _statusMessage = 'Loading nearby salons...');

    _salonStreamSubscription?.cancel();
    _salonStreamSubscription = FirebaseFirestore.instance
        .collection('salons')
        .snapshots()
        .listen((snapshot) async {
      _allSalons = snapshot.docs;
      await _resolveMissingCoordinates();
      if (mounted) {
        _applyFilteringAndSorting();
        setState(() {
          _isLoading = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Could not load salons: $error';
        });
      }
    });
  }

  Future<void> _resolveMissingCoordinates() async {
    for (final doc in _allSalons) {
      if (_geocodedCoords.containsKey(doc.id)) continue;

      final data = doc.data() as Map<String, dynamic>? ?? {};
      final existing = LocationService.parseCoordinates(data);
      if (existing != null) {
        _geocodedCoords[doc.id] = existing;
        continue;
      }

      final address = (data['address'] ?? '').toString().trim();
      if (address.isEmpty) continue;

      final coords = await LocationService.geocodeAddress(address);
      if (coords != null) {
        _geocodedCoords[doc.id] = coords;
      }
    }
  }

  Map<String, dynamic> _salonData(DocumentSnapshot doc) {
    return doc.data() as Map<String, dynamic>? ?? {};
  }

  LatLng? _salonCoordinates(DocumentSnapshot doc) {
    final data = _salonData(doc);
    return LocationService.parseCoordinates(data) ?? _geocodedCoords[doc.id];
  }

  LatLng get _mapCenter => _searchCenter ?? _currentPosition ?? _defaultCenter;

  void _applyFilteringAndSorting() {
    var workingList = List<DocumentSnapshot>.from(_allSalons);

    if (_searchQuery.isNotEmpty) {
      workingList = workingList.where((doc) {
        final data = _salonData(doc);
        final name = (data['name'] ?? '').toString().toLowerCase();
        final address = (data['address'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery) || address.contains(_searchQuery);
      }).toList();
    }

    workingList.sort((a, b) {
      final dataA = _salonData(a);
      final dataB = _salonData(b);
      final distA = _distanceKm(dataA, doc: a) ?? double.maxFinite;
      final distB = _distanceKm(dataB, doc: b) ?? double.maxFinite;
      return distA.compareTo(distB);
    });

    _filteredSalons = workingList;
    _rebuildMapPins();
  }

  double? _distanceKm(Map<String, dynamic> data, {required DocumentSnapshot doc}) {
    final coords = _salonCoordinates(doc);
    if (_currentPosition == null || coords == null) return null;

    return LocationService.distanceKm(_currentPosition, {
      'latitude': coords.latitude,
      'longitude': coords.longitude,
    });
  }

  void _rebuildMapPins() {
    _markers.clear();

    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_user_position'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    }

    for (final doc in _filteredSalons) {
      final data = _salonData(doc);
      final coords = _salonCoordinates(doc);
      if (coords == null) continue;

      final distance = _distanceKm(data, doc: doc);
      final name = data['name'] ?? 'Salon';

      _markers.add(
        Marker(
          markerId: MarkerId(doc.id),
          position: coords,
          infoWindow: InfoWindow(
            title: name,
            snippet: distance != null
                ? '${distance.toStringAsFixed(1)} km away'
                : (data['address'] ?? '').toString(),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          onTap: () => _openDirections(coords),
        ),
      );
    }
  }

  Future<void> _searchByAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isGeocodingSearch = true);

    final coords = await LocationService.geocodeAddress(query);
    if (!mounted) return;

    setState(() => _isGeocodingSearch = false);

    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find that location.')),
      );
      return;
    }

    setState(() {
      _searchCenter = coords;
      _isMapView = true;
    });

    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(coords, 13.5),
      );
    }
  }

  Future<void> _openDirections(LatLng destination) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions')),
      );
    }
  }

  Future<void> _recenterOnUser() async {
    try {
      final access = await LocationService.ensureAccess();
      if (!access.isGranted) {
        _showLocationHelp(access);
        return;
      }

      final position = await LocationService.getCurrentPosition();
      if (position == null || !mounted) return;

      setState(() {
        _currentPosition = position;
        _searchCenter = null;
      });
      _applyFilteringAndSorting();
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(position, 13.5),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')),
      );
    }
  }

  void _showLocationHelp(LocationAccessResult access) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location needed'),
        content: Text(access.message ?? 'Please enable location to find nearby salons.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          if (access.status == LocationAccessStatus.serviceDisabled)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                LocationService.openLocationSettings();
              },
              child: const Text('Open settings'),
            ),
          if (access.status == LocationAccessStatus.permissionDeniedForever)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                LocationService.openAppSettings();
              },
              child: const Text('App settings'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _salonStreamSubscription?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Nearby Salons',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(
                _isMapView ? Icons.format_list_bulleted : Icons.map_outlined,
                color: const Color(0xFFF2845C),
              ),
              onPressed: () => setState(() => _isMapView = !_isMapView),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                if (_accessStatus != null && _accessStatus != LocationAccessStatus.granted)
                  _buildLocationBanner(),
                _buildSearchBar(),
                Expanded(
                  child: _isMapView ? _buildMapView() : _buildListView(),
                ),
              ],
            ),
      floatingActionButton: _isMapView && !_isLoading
          ? FloatingActionButton(
              onPressed: _recenterOnUser,
              backgroundColor: const Color(0xFFF2845C),
              child: const Icon(Icons.my_location, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildLocationBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3EE),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.location_off_outlined, color: Color(0xFFF2845C), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage,
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF7A4A3A)),
            ),
          ),
          TextButton(
            onPressed: _initializeLocationAndSalons,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2845C)),
                strokeWidth: 3.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(fontSize: 14),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _searchByAddress(),
        decoration: InputDecoration(
          hintText: 'Search salons or area...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFFF2845C)),
          suffixIcon: _isGeocodingSearch
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : (_searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchCenter = null);
                      },
                    )
                  : null),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFF1F3F4),
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (_filteredSalons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No salons found nearby',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for a different area',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSalons.length,
      itemBuilder: (context, index) {
        final doc = _filteredSalons[index];
        final data = _salonData(doc);
        final coords = _salonCoordinates(doc);
        final distance = _distanceKm(data, doc: doc);
        final name = data['name'] ?? 'Salon Hub';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3EE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.storefront, color: Color(0xFFF2845C)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['address'] ?? 'Address unavailable',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFF2845C), size: 15),
                          const SizedBox(width: 4),
                          Text(
                            (data['rating'] ?? 4.5).toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: const Color(0xFFF2845C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.navigation_outlined, size: 16, color: Color(0xFFF2845C)),
                        const SizedBox(width: 4),
                        Text(
                          distance != null
                              ? '${distance.toStringAsFixed(1)} km away'
                              : 'Location unavailable',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (coords != null)
                          TextButton(
                            onPressed: () => _openDirections(coords),
                            child: const Text('Directions'),
                          ),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Booking coming soon! We are partnering with this salon.'),
                                backgroundColor: Color(0xFFF2845C),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2845C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'View',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _mapCenter,
        zoom: 13.5,
      ),
      markers: _markers,
      myLocationEnabled: _accessStatus == LocationAccessStatus.granted,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        _isMapInitialized = true;
        if (_currentPosition != null) {
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition!, 13.5),
          );
        }
      },
    );
  }
}