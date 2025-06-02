import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gymnex_find/utility/app_colors.dart';
import 'package:gymnex_find/utility/app_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class GymMapPage extends StatefulWidget {
  const GymMapPage({super.key});

  @override
  State<GymMapPage> createState() => _GymMapPageState();
}

class _GymMapPageState extends State<GymMapPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isLocationEnabled = false;
  String _selectedFilter = 'All';

  // Map settings
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.9271, 79.8612), // Colombo, Sri Lanka
    zoom: 14.0,
  );

  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  // Sample gym data with coordinates
  final List<Map<String, dynamic>> _gyms = [
    {
      'id': 'gym_1',
      'name': 'FitZone Gym',
      'address': '123 Main Street, Colombo 03',
      'latitude': 6.9271,
      'longitude': 79.8512,
      'rating': 4.5,
      'isOpen': true,
      'type': 'Commercial',
      'amenities': ['Cardio', 'Weights', 'Pool'],
      'price': 'LKR 5,000/month',
      'phone': '+94 11 234 5678',
      'image': 'assets/gym1.jpg',
    },
    {
      'id': 'gym_2',
      'name': 'PowerHouse Fitness',
      'address': '456 Galle Road, Colombo 04',
      'latitude': 6.8971,
      'longitude': 79.8612,
      'rating': 4.7,
      'isOpen': true,
      'type': 'CrossFit',
      'amenities': ['CrossFit', 'Yoga', 'Sauna'],
      'price': 'LKR 7,500/month',
      'phone': '+94 11 345 6789',
      'image': 'assets/gym2.jpg',
    },
    {
      'id': 'gym_3',
      'name': 'Elite Sports Club',
      'address': '789 Duplication Road, Colombo 04',
      'latitude': 6.9071,
      'longitude': 79.8712,
      'rating': 4.3,
      'isOpen': false,
      'type': 'Premium',
      'amenities': ['Tennis', 'Swimming', 'Spa'],
      'price': 'LKR 12,000/month',
      'phone': '+94 11 456 7890',
      'image': 'assets/gym3.jpg',
    },
    {
      'id': 'gym_4',
      'name': 'Urban Fitness',
      'address': '321 Baseline Road, Colombo 09',
      'latitude': 6.9171,
      'longitude': 79.8412,
      'rating': 4.1,
      'isOpen': true,
      'type': '24/7',
      'amenities': ['24/7 Access', 'Personal Training'],
      'price': 'LKR 4,500/month',
      'phone': '+94 11 567 8901',
      'image': 'assets/gym4.jpg',
    },
    {
      'id': 'gym_5',
      'name': 'Flex Gym',
      'address': '654 Nawala Road, Nugegoda',
      'latitude': 6.8771,
      'longitude': 79.8912,
      'rating': 4.4,
      'isOpen': true,
      'type': 'Budget',
      'amenities': ['Cardio', 'Basic Weights'],
      'price': 'LKR 2,500/month',
      'phone': '+94 11 678 9012',
      'image': 'assets/gym5.jpg',
    },
  ];

  final List<String> _filterOptions = [
    'All',
    'Commercial',
    'CrossFit',
    'Premium',
    '24/7',
    'Budget',
  ];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _checkLocationPermission();
    await _getCurrentLocation();
    _createMarkers();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    _isLocationEnabled = status.isGranted;

    if (!_isLocationEnabled) {
      _showLocationPermissionDialog();
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Location Permission', style: AppTypography.titleLarge),
            content: Text(
              'Location access is needed to show nearby gyms and your current position on the map.',
              style: AppTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: Text('Open Settings', style: AppTypography.labelLarge),
              ),
            ],
          ),
    );
  }

  Future<void> _getCurrentLocation() async {
    if (!_isLocationEnabled) return;

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_currentPosition != null) {
        _createLocationCircle();
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _createLocationCircle() {
    if (_currentPosition == null) return;

    _circles.add(
      Circle(
        circleId: const CircleId('user_location'),
        center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        radius: 1000, // 1km radius
        fillColor: AppColors.primary.withOpacity(0.1),
        strokeColor: AppColors.primary,
        strokeWidth: 2,
      ),
    );
  }

  void _createMarkers() {
    _markers.clear();

    // Add user location marker if available
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
        ),
      );
    }

    // Add gym markers
    for (var gym in _filteredGyms) {
      _markers.add(
        Marker(
          markerId: MarkerId(gym['id']),
          position: LatLng(gym['latitude'], gym['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            gym['isOpen'] ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: gym['name'],
            snippet: '${gym['rating']} ⭐ • ${gym['price']}',
            onTap: () => _showGymDetails(gym),
          ),
          onTap: () => _showGymBottomSheet(gym),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredGyms {
    if (_selectedFilter == 'All') {
      return _gyms;
    }
    return _gyms.where((gym) => gym['type'] == _selectedFilter).toList();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Move camera to user location if available
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _createMarkers();
    });
  }

  void _goToUserLocation() async {
    if (_mapController != null && _currentPosition != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 16.0,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location not available',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _showGymDetails(Map<String, dynamic> gym) {
    // Navigate to gym details page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening ${gym['name']} details...',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showGymBottomSheet(Map<String, dynamic> gym) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildGymBottomSheet(gym),
    );
  }

  Widget _buildGymBottomSheet(Map<String, dynamic> gym) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Gym header
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(gym['name'], style: AppTypography.titleMedium),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                gym['isOpen']
                                    ? AppColors.success
                                    : AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            gym['isOpen'] ? 'Open' : 'Closed',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.white,
                              fontWeight: AppTypography.medium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gym['address'],
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.caloriesBurned,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          gym['rating'].toString(),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          gym['price'],
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Amenities
          Text('Amenities', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children:
                (gym['amenities'] as List<String>).map((amenity) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      amenity,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Call gym
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Calling ${gym['phone']}...',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showGymDetails(gym);
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Nearby Gyms', style: AppTypography.titleLarge),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.primary),
            onPressed: _goToUserLocation,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
              : Column(
                children: [
                  // Filter chips
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filterOptions.length,
                      itemBuilder: (context, index) {
                        final filter = _filterOptions[index];
                        final isSelected = _selectedFilter == filter;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              filter,
                              style: AppTypography.bodyMedium.copyWith(
                                color:
                                    isSelected
                                        ? AppColors.white
                                        : AppColors.textSecondary,
                                fontWeight:
                                    isSelected
                                        ? AppTypography.medium
                                        : AppTypography.regular,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) => _onFilterChanged(filter),
                            backgroundColor: AppColors.surfaceVariant,
                            selectedColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : AppColors.borderPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Map
                  Expanded(
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: _initialPosition,
                      markers: _markers,
                      circles: _circles,
                      myLocationEnabled: _isLocationEnabled,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      style: '''
                    [
                      {
                        "featureType": "all",
                        "elementType": "geometry.fill",
                        "stylers": [
                          {
                            "weight": "2.00"
                          }
                        ]
                      },
                      {
                        "featureType": "all",
                        "elementType": "geometry.stroke",
                        "stylers": [
                          {
                            "color": "#9c9c9c"
                          }
                        ]
                      },
                      {
                        "featureType": "all",
                        "elementType": "labels.text",
                        "stylers": [
                          {
                            "visibility": "on"
                          }
                        ]
                      }
                    ]
                    ''',
                    ),
                  ),
                ],
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "zoom_in",
            mini: true,
            backgroundColor: AppColors.surface,
            onPressed: () {
              _mapController?.animateCamera(CameraUpdate.zoomIn());
            },
            child: const Icon(Icons.add, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "zoom_out",
            mini: true,
            backgroundColor: AppColors.surface,
            onPressed: () {
              _mapController?.animateCamera(CameraUpdate.zoomOut());
            },
            child: const Icon(Icons.remove, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
