import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/salon_service.dart';
import '../../services/gemini_salon_service.dart';
import '../../utils/geo_math.dart';
import '../../models/salon_model.dart';

class NearbySalonsScreen extends StatefulWidget {
  const NearbySalonsScreen({super.key});

  @override
  State<NearbySalonsScreen> createState() => _NearbySalonsScreenState();
}

class _NearbySalonsScreenState extends State<NearbySalonsScreen> with SingleTickerProviderStateMixin {
  final SalonService _salonService = SalonService();
  final TextEditingController _searchController = TextEditingController();
  
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isFirstLoad = true;
  String _errorMsg = '';
  String _searchQuery = '';
  double _currentRadius = 15.0; // Increased to 15km
  String _selectedCategory = 'All';
  bool _showSuggestions = false;
  
  MapController? _mapController;
  List<Map<String, dynamic>> _salons = [];
  List<Map<String, dynamic>> _filteredSalons = [];
  List<String> _searchSuggestions = [];
  List<SalonRecommendation> _aiRecommendations = [];
  String _currentAddress = 'Getting your location...';
  String _currentCity = '';
  
  StreamSubscription? _salonSubscription;
  final List<String> _categories = ['All', 'Premium', 'Luxury', 'Affordable', 'Professional', "Men's"];
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _initLocation();
  }

  void _onSearchChanged() async {
    final query = _searchController.text;
    setState(() {
      _searchQuery = query.toLowerCase().trim();
    });
    
    if (query.length >= 2) {
      try {
        final suggestions = await GeminiSalonService.getSearchSuggestions(query);
        if (mounted) {
          setState(() {
            _searchSuggestions = suggestions.take(5).toList();
            _showSuggestions = suggestions.isNotEmpty;
          });
        }
      } catch (e) {
        setState(() {
          _searchSuggestions = [];
          _showSuggestions = false;
        });
      }
    } else {
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
      });
    }
    
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_salons);
    
    if (_selectedCategory != 'All') {
      filtered = filtered.where((salon) {
        final category = (salon['category'] ?? '').toString().toLowerCase();
        return category == _selectedCategory.toLowerCase();
      }).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((salon) {
        final name = (salon['name'] ?? '').toString().toLowerCase();
        final address = (salon['address'] ?? '').toString().toLowerCase();
        final category = (salon['category'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery) || 
               address.contains(_searchQuery) ||
               category.contains(_searchQuery);
      }).toList();
    }
    
    setState(() {
      _filteredSalons = filtered;
    });
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoading = true;
      _isFirstLoad = true;
    });

    try {
      final pos = await _salonService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
        await _getAddressFromCoords(pos);
        _startSalonStream(pos);
        
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _animationController.forward();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Unable to get location. Please check:\n• Internet connection\n• Location permissions\n• GPS is enabled';
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    }
  }

  Future<void> _getAddressFromCoords(Position pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        
        // Build full address
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
          _currentCity = place.locality!;
        } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
          _currentCity = place.administrativeArea!;
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          parts.add(place.postalCode!);
        }
        
        if (mounted) {
          setState(() {
            _currentAddress = parts.isNotEmpty ? parts.join(', ') : 'Islamabad, Pakistan';
          });
        }
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _currentAddress = 'Islamabad, Pakistan';
      });
    }
  }

  void _startSalonStream(Position pos) {
    _salonSubscription?.cancel();
    _salonSubscription = _salonService
        .streamNearbySalons(pos, _currentRadius)
        .listen(
          (salons) {
            if (mounted) {
              // Calculate distance for each salon
              final salonsWithDistance = salons.map((salon) {
                final distance = GeoMath.calculateDistance(
                  pos.latitude,
                  pos.longitude,
                  salon['latitude'] as double? ?? 0,
                  salon['longitude'] as double? ?? 0,
                );
                return {
                  ...salon,
                  'distance': distance,
                };
              }).toList();
              
              setState(() {
                _salons = salonsWithDistance;
                _filteredSalons = salonsWithDistance;
                _isLoading = false;
                _isFirstLoad = false;
              });
              
              if (salons.isNotEmpty) {
                _getAIRecommendations(pos, salonsWithDistance);
              }
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _errorMsg = 'Error loading salons: $error';
                _isLoading = false;
                _isFirstLoad = false;
              });
            }
          },
        );
  }

  Future<void> _getAIRecommendations(Position pos, List<Map<String, dynamic>> salons) async {
    try {
      final recs = await GeminiSalonService.getSalonRecommendations(
        userLat: pos.latitude,
        userLng: pos.longitude,
        nearbySalons: salons,
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory != 'All' ? _selectedCategory : null,
      );
      if (mounted) {
        setState(() {
          _aiRecommendations = recs;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  double _getDistance(Map<String, dynamic> salon) {
    return (salon['distance'] ?? 0.0).toDouble();
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }

    final displaySalons = _filteredSalons.take(20).toList();
    for (final salon in displaySalons) {
      final lat = salon['latitude'] as double?;
      final lng = salon['longitude'] as double?;
      
      if (lat == null || lng == null) continue;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => _showSalonDetails(salon),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF2845C), Color(0xFFFF6B4A)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF2845C).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.storefront,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _showSalonDetails(Map<String, dynamic> salon) {
    final lat = salon['latitude'] as double?;
    final lng = salon['longitude'] as double?;
    final distance = _getDistance(salon);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.35,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3EE),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.storefront, color: Color(0xFFF2845C), size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                salon['name'] ?? 'Salon',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Color(0xFFF2845C), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    (salon['rating'] ?? 0.0).toStringAsFixed(1),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: const Color(0xFFF2845C),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    distance > 0 ? '${distance.toStringAsFixed(1)} km away' : 'Location unavailable',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  
                  // Details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (salon['address'] != null)
                          _buildDetailRow(Icons.location_on, salon['address']),
                        if (salon['phone'] != null && salon['phone'] != 'N/A')
                          _buildDetailRow(Icons.phone, salon['phone']),
                        if (salon['category'] != null)
                          _buildCategoryChip(salon['category']),
                        if (salon['services'] != null && (salon['services'] as List).isNotEmpty)
                          _buildServicesList(salon['services']),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              if (lat != null && lng != null) {
                                _openDirections(lat, lng);
                              }
                            },
                            icon: const Icon(Icons.directions, size: 16),
                            label: const Text('Directions', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF2845C),
                              side: const BorderSide(color: Color(0xFFF2845C)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _shareSalon(salon);
                            },
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('Share', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF2845C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          category,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFFF2845C),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildServicesList(List services) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: services.map((service) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            service.toString(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _shareSalon(Map<String, dynamic> salon) {
    final distance = _getDistance(salon);
    final message = '''
✨ ${salon['name']}
📍 ${salon['address']}
⭐ Rating: ${salon['rating'] ?? 0.0}/5
📏 ${distance > 0 ? '${distance.toStringAsFixed(1)} km away' : 'Location unavailable'}
📞 ${salon['phone'] ?? 'N/A'}

Found on GlowSalon App! 🎀
''';
    Share.share(message);
  }

  Future<void> _openDirections(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open directions.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _recenterOnUser() async {
    if (_currentPosition == null) return;
    
    _mapController?.move(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      14.0,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _salonSubscription?.cancel();
    _mapController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _isFirstLoad) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: _buildLoadingState(),
      );
    }

    if (_errorMsg.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: _buildErrorState(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Nearby Salons',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFF2845C)),
            onPressed: () {
              if (_currentPosition != null) {
                setState(() {
                  _isLoading = true;
                });
                _startSalonStream(_currentPosition!);
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLocationInfo(),
          _buildSearchBar(),
          _buildCategoryFilter(),
          _buildRadiusFilter(),
          Expanded(
            child: _isLoading
                ? _buildLoadingSalons()
                : _salons.isEmpty
                    ? _buildEmptyState()
                    : _filteredSalons.isEmpty
                        ? _buildNoResultsState()
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Column(
                                children: [
                                  // Map
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.32,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                      child: FlutterMap(
                                        mapController: _mapController,
                                        options: MapOptions(
                                          initialCenter: LatLng(
                                            _currentPosition!.latitude,
                                            _currentPosition!.longitude,
                                          ),
                                          initialZoom: 13.0,
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName: 'com.example.salon_app',
                                            additionalOptions: const {
                                              'attribution': '© OpenStreetMap contributors',
                                            },
                                          ),
                                          MarkerLayer(
                                            markers: _buildMarkers(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // List
                                  Expanded(
                                    child: _buildSalonList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _recenterOnUser,
        backgroundColor: const Color(0xFFF2845C),
        child: const Icon(Icons.my_location, color: Colors.white),
        mini: true,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF3EE),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF2845C).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2845C)),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Finding nearby salons...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we locate you',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSalons() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2845C)),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text('Loading salons...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade50,
              ),
              child: Icon(Icons.signal_wifi_off, size: 40, color: Colors.red[300]),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Error',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMsg,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMsg = '';
                  _isLoading = true;
                  _isFirstLoad = true;
                });
                _initLocation();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2845C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.location_on, color: Color(0xFFF2845C), size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '📍 $_currentAddress',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_filteredSalons.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF2845C), Color(0xFFFF6B4A)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_filteredSalons.length}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search salons...',
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFF2845C), size: 18),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _showSuggestions = false;
                          _applyFilters();
                        });
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF1F3F4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onTap: () => setState(() => _showSuggestions = true),
            onSubmitted: (_) => setState(() => _showSuggestions = false),
          ),
          if (_showSuggestions && _searchSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchSuggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.lightbulb, size: 14, color: Color(0xFFF2845C)),
                    title: Text(
                      _searchSuggestions[index],
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    onTap: () {
                      _searchController.text = _searchSuggestions[index];
                      _searchQuery = _searchSuggestions[index].toLowerCase();
                      _showSuggestions = false;
                      _applyFilters();
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: FilterChip(
              label: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                  _applyFilters();
                });
              },
              backgroundColor: Colors.grey[100],
              selectedColor: const Color(0xFFFFF3EE),
              checkmarkColor: const Color(0xFFF2845C),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFF2845C) : Colors.grey[600],
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? const Color(0xFFF2845C) : Colors.transparent,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRadiusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.radar, size: 14, color: Color(0xFFF2845C)),
          const SizedBox(width: 6),
          Text(
            '${_currentRadius.toStringAsFixed(0)} km',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Slider(
              value: _currentRadius,
              min: 2,
              max: 30,
              divisions: 28,
              activeColor: const Color(0xFFF2845C),
              onChanged: (value) {
                setState(() {
                  _currentRadius = value;
                });
              },
              onChangeEnd: (value) {
                if (_currentPosition != null) {
                  setState(() {
                    _isLoading = true;
                  });
                  _startSalonStream(_currentPosition!);
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  });
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_filteredSalons.length}',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFFF2845C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF3EE),
            ),
            child: Icon(Icons.storefront_outlined, size: 40, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            'No salons found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try increasing the search radius',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (_currentPosition != null) {
                setState(() {
                  _isLoading = true;
                });
                _startSalonStream(_currentPosition!);
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              }
            },
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2845C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF3EE),
            ),
            child: Icon(Icons.search_off, size: 40, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            'No matching salons',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try different search terms',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _showSuggestions = false;
                _applyFilters();
              });
              FocusScope.of(context).unfocus();
            },
            icon: const Icon(Icons.clear, size: 14),
            label: const Text('Clear Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2845C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalonList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: _filteredSalons.length,
      itemBuilder: (context, index) {
        final salon = _filteredSalons[index];
        final distance = _getDistance(salon);
        final name = salon['name'] ?? 'Salon';
        final rating = salon['rating'] ?? 0.0;
        final address = salon['address'] ?? 'Address unavailable';
        final category = salon['category'] ?? '';

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showSalonDetails(salon),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3EE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.storefront, color: Color(0xFFF2845C), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3EE),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${distance.toStringAsFixed(1)} km',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      color: const Color(0xFFF2845C),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: Colors.grey[500],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(0xFFF2845C), size: 10),
                                const SizedBox(width: 2),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 9,
                                    color: const Color(0xFFF2845C),
                                  ),
                                ),
                                if (category.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3EE),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      category,
                                      style: GoogleFonts.poppins(
                                        fontSize: 7,
                                        color: const Color(0xFFF2845C),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[300],
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}