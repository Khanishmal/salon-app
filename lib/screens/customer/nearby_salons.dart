// lib/screens/customer_modules/nearby_salons.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class NearbySalonsScreen extends StatefulWidget {
  const NearbySalonsScreen({super.key});

  @override
  State<NearbySalonsScreen> createState() => _NearbySalonsScreenState();
}

class _NearbySalonsScreenState extends State<NearbySalonsScreen> {
  bool _isMapView = false;
  bool _isLoadingLocation = true;
  String _locationStatusMessage = "Initializing tracking services...";
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  
  // Real-time local memory structures
  List<DocumentSnapshot> _allSalons = [];
  List<DocumentSnapshot> _filteredSalons = [];
  final Set<Marker> _markers = {};
  
  StreamSubscription<QuerySnapshot>? _salonStreamSubscription;

  @override
  void initState() {
    super.initState();
    _determineAndRequestPermission();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilteringAndSorting();
    });
  }

  /// Explicitly handles the location lifecycle based on geolocator status rules
  Future<void> _determineAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _isLoadingLocation = true;
      _locationStatusMessage = "Checking location service state...";
    });

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _updateLoadingState("Location services are disabled on your device. Please turn them on.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _updateLoadingState("Location access permission denied. Enable it to view local salons.");
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _updateLoadingState("Location permissions are permanently blocked. Please enable them in your device settings.");
      return;
    }

    // Capture precise coordinates using high accuracy tracking parameters
    try {
      setState(() => _locationStatusMessage = "Locking onto satellites...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      
      _currentPosition = LatLng(position.latitude, position.longitude);
      _initializeRealTimeSalonStream();
    } catch (e) {
      // Fallback configuration if positioning takes too long or fails
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _currentPosition = LatLng(lastKnown.latitude, lastKnown.longitude);
        _initializeRealTimeSalonStream();
      } else {
        _updateLoadingState("Unable to lock precision coordinates. Retrying structural pipeline...");
      }
    }
  }

  void _updateLoadingState(String message) {
    setState(() {
      _locationStatusMessage = message;
      _isLoadingLocation = false;
    });
  }

  /// Binds a continuous listener directly to Firestore
  void _initializeRealTimeSalonStream() {
    setState(() => _locationStatusMessage = "Synchronizing local salons...");
    
    _salonStreamSubscription = FirebaseFirestore.instance
        .collection('salons')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
          _allSalons = snapshot.docs;
          _applyFilteringAndSorting();
          if (mounted) {
            setState(() => _isLoadingLocation = false);
          }
        }, onError: (error) {
          _updateLoadingState("Database sync error: $error");
        });
  }

  /// Processes math constraints, query filtering, and high-rating recommendations
  void _applyFilteringAndSorting() {
    if (_currentPosition == null) return;

    List<DocumentSnapshot> workingList = List.from(_allSalons);

    // 1. Text Query Filter Evaluation
    if (_searchQuery.isNotEmpty) {
      workingList = workingList.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final name = (data['name'] ?? '').toString().toLowerCase();
        final address = (data['address'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery) || address.contains(_searchQuery);
      }).toList();
    }

    // 2. Automated Smart Recommendation Sorting Routine
    // Priority Vector rule: (Is Recommended based on proximity < 5km AND rating >= 4.5) -> Sorts directly to the top
    workingList.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>? ?? {};
      final dataB = b.data() as Map<String, dynamic>? ?? {};

      final double distA = _getDirectDistanceKM(dataA);
      final double distB = _getDirectDistanceKM(dataB);
      
      final double ratingA = double.tryParse((dataA['rating'] ?? '0').toString()) ?? 0.0;
      final double ratingB = double.tryParse((dataB['rating'] ?? '0').toString()) ?? 0.0;

      final bool isRecA = distA <= 5.0 && ratingA >= 4.5;
      final bool isRecB = distB <= 5.0 && ratingB >= 4.5;

      if (isRecA && !isRecB) return -1; // Pull item A upward
      if (!isRecA && isRecB) return 1;  // Push item A downward
      
      // Secondary sorting metric fallback: Closest distance rank mapping
      return distA.compareTo(distB);
    });

    _filteredSalons = workingList;
    _rebuildMapPins();
  }

  /// Calculates the spherical coordinate distances using the Haversine formula
  double _getDirectDistanceKM(Map<String, dynamic> salonData) {
    if (_currentPosition == null) return double.maxFinite;
    final double lat = double.tryParse(salonData['latitude']?.toString() ?? '0') ?? 0.0;
    final double lng = double.tryParse(salonData['longitude']?.toString() ?? '0') ?? 0.0;
    
    if (lat == 0.0 || lng == 0.0) return double.maxFinite;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    ) / 1000.0;
  }

  /// Rebuilds map tracking descriptors cleanly from the current state
  void _rebuildMapPins() {
    _markers.clear();
    
    // Add User Current Coordinates Anchor Pin
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_user_position'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: "Your Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    }

    // Add dynamically evaluated Salon Anchor Nodes
    for (var doc in _filteredSalons) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final double lat = double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0;
      final double lng = double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0;
      final double rating = double.tryParse((data['rating'] ?? '0').toString()) ?? 0.0;
      final double distance = _getDirectDistanceKM(data);

      if (lat == 0.0 || lng == 0.0) continue;

      final bool highQualityRecommendation = distance <= 5.0 && rating >= 4.5;

      _markers.add(
        Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: "${data['name'] ?? 'Salon'} ${highQualityRecommendation ? '🔥 (Top Pick)' : ''}",
            snippet: "${distance.toStringAsFixed(1)} km away | ⭐ $rating",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            highQualityRecommendation ? BitmapDescriptor.hueRose : BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }
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
          "Discover Salons",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          if (!_isLoadingLocation && _currentPosition != null)
            IconButton(
              icon: Icon(_isMapView ? Icons.format_list_bulleted : Icons.map_outlined, color: const Color(0xFFF2845C)),
              onPressed: () => setState(() => _isMapView = !_isMapView),
            ),
        ],
      ),
      body: _isLoadingLocation 
          ? _buildLoadingStateOverlay()
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _isMapView ? _buildMapView() : _buildListView(),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingStateOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50, height: 50,
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2845C)), strokeWidth: 3.5),
            ),
            const SizedBox(height: 24),
            Text(
              _locationStatusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _determineAndRequestPermission,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Retry Connection"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2845C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
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
        decoration: InputDecoration(
          hintText: "Search local hubs or addresses...",
          prefixIcon: const Icon(Icons.search, color: Color(0xFFF2845C)),
          suffixIcon: _searchController.text.isNotEmpty 
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => _searchController.clear())
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          filled: true,
          fillColor: const Color(0xFFF1F3F4),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (_filteredSalons.isEmpty) {
      return Center(
        child: Text("No salons found nearby matching your request.", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSalons.length,
      itemBuilder: (context, index) {
        final doc = _filteredSalons[index];
        final data = doc.data() as Map<String, dynamic>? ?? {};
        
        final double distance = _getDirectDistanceKM(data);
        final double rating = double.tryParse((data['rating'] ?? '4.5').toString()) ?? 4.5;
        final bool isRecommended = distance <= 5.0 && rating >= 4.5;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 6)),
            ],
            border: isRecommended ? Border.all(color: const Color(0xFFF2845C).withOpacity(0.4), width: 1.5) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      data['imageUrl'] ?? 'https://via.placeholder.com/400x200',
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 160, color: Colors.grey[100],
                        child: const Icon(Icons.storefront, size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                  if (isRecommended)
                    Positioned(
                      top: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF2845C), Color(0xFFE05A47)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.thumb_up, color: Colors.white, size: 12),
                            const SizedBox(width: 6),
                            Text("HIGHLY RECOMMENDED", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? 'Salon Hub',
                                style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['address'] ?? 'Address details unavailable',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFFFF3EE), borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFF2845C), size: 15),
                              const SizedBox(width: 4),
                              Text(rating.toStringAsFixed(1), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFFF2845C))),
                            ],
                          ),
                        )
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
                              distance == double.maxFinite ? "Calculating distance..." : "${distance.toStringAsFixed(1)} km away",
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Link into reservation configuration views safely passing the document identifier mapping rules
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2845C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("Book", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 13.5),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // Custom actions keep the viewport centered clean
      zoomControlsEnabled: false,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
    );
  }
}