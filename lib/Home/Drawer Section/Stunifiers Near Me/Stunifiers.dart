import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ✅ UPDATE THESE IMPORT PATHS TO MATCH YOUR PROJECT
import 'package:student_unify_app/Models/DonateModel.dart';

import '../../widgets/chatpage.dart'; // Donation model
// ChatPage

const String kGoogleApiKey = "AIzaSyDEZD5JDtSClTS3qSrG0OU3dJGo-3OADwY";

// Color palette - consistent with the app
const Color primaryPink = Color(0xFFFF6786);
const Color lightPink = Color(0xFFFFE5EC);
const Color accentPink = Color(0xFFFF9BAD);
const Color darkText = Color(0xFF2D3748);
const Color lightText = Color(0xFF718096);

class DonationsMapPage extends StatefulWidget {
  const DonationsMapPage({super.key});

  @override
  State<DonationsMapPage> createState() => _DonationsMapPageState();
}

class _DonationsMapPageState extends State<DonationsMapPage> {
  GoogleMapController? _mapController;
  final LatLng _initialPosition = const LatLng(53.4808, -2.2426); // Manchester

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  Position? _currentPosition;
  bool _hasLocationPermission = false;
  bool _loadingLocation = false;
  bool _loadingDonations = false;

  double _searchRadius = 5.0; // in miles
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  List<Map<String, dynamic>> _nearbyDonations = [];
  Map<String, dynamic>? _selectedDonation;

  BitmapDescriptor? _donationIcon;
  BitmapDescriptor? _currentLocationIcon;
  BitmapDescriptor? _studentIcon;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadCategories();
    _createCustomMarkerIcons();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ===================== ✅ CHAT NAVIGATION (CONTACT BUTTON) =====================
  Future<void> _openChatForDonation(Map<String, dynamic> donationMap) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showSnackBar('Please login to contact the donor', isError: true);
        return;
      }

      final donorId = (donationMap['donorId'] ?? '').toString();
      if (donorId.isEmpty) {
        _showSnackBar('Donation is missing donorId', isError: true);
        return;
      }

      if (donorId == currentUser.uid) {
        _showSnackBar("You can't contact yourself 😊", isError: true);
        return;
      }

      // ✅ Fetch donor user details
      final userSnap = await FirebaseFirestore.instance.collection('users').doc(donorId).get();
      final userData = userSnap.data() ?? {};

      final receiverName =
      (userData['displayName'] ?? userData['username'] ?? 'Student').toString();
      final receiverPhoto =
      (userData['photoUrl'] ?? userData['userPhotoUrl'] ?? '').toString();

      // ✅ Convert Map -> Donation model using YOUR Donation.fromMap()
      final donationModel = Donation.fromMap({
        ...donationMap,
        'id': donationMap['id'], // ensure id exists
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            receiverId: donorId,
            receiverName: receiverName,
            receiverPhoto: receiverPhoto,
            donation: donationModel,
            lendModel: null,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Chat open error: $e');
      _showSnackBar('Unable to open chat', isError: true);
    }
  }

  // ===================== Create custom marker icons =====================
  Future<void> _createCustomMarkerIcons() async {
    _donationIcon = await _createMarkerIcon(
      Icons.volunteer_activism_rounded,
      primaryPink,
      60,
    );

    _currentLocationIcon = await _createMarkerIcon(
      Icons.person_pin_circle_rounded,
      const Color(0xFF10B981),
      70,
    );

    _studentIcon = await _createMarkerIcon(
      Icons.school_rounded,
      accentPink,
      55,
    );
  }

  Future<BitmapDescriptor> _createMarkerIcon(
      IconData iconData,
      Color color,
      double size,
      ) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;

    // Draw circle background
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      borderPaint,
    );

    // Draw icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.5,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  // ===================== Location =====================
  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    setState(() {
      _hasLocationPermission = granted;
    });

    if (granted) {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _loadingLocation = true);

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      setState(() {
        _currentPosition = position;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          13.0,
        ),
      );

      await _loadNearbyDonations();
    } catch (e) {
      debugPrint('Error getting location: $e');
      _showSnackBar('Unable to get your location', isError: true);
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  // ===================== Categories =====================
  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('donations').get();

      final categories = <String>{'All'};
      for (var doc in snapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      setState(() {
        _categories = categories.toList()..sort();
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  // ===================== Load nearby donations =====================
  Future<void> _loadNearbyDonations() async {
    if (_currentPosition == null) return;

    setState(() => _loadingDonations = true);

    try {
      final snapshot = await FirebaseFirestore.instance.collection('donations').get();

      final nearbyDonations = <Map<String, dynamic>>[];
      final markers = <Marker>{};

      // Add current location marker
      if (_currentLocationIcon != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            icon: _currentLocationIcon!,
            infoWindow: const InfoWindow(
              title: 'Your Location',
              snippet: 'You are here',
            ),
          ),
        );
      }

      // Add search radius circle
      _circles = {
        Circle(
          circleId: const CircleId('search_radius'),
          center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          radius: _searchRadius * 1609.34, // miles to meters
          fillColor: primaryPink.withOpacity(0.15),
          strokeColor: primaryPink,
          strokeWidth: 2,
        ),
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final latAny = data['latitude'];
        final lngAny = data['longitude'];

        final double? lat = latAny is num ? latAny.toDouble() : null;
        final double? lng = lngAny is num ? lngAny.toDouble() : null;

        final category = (data['category'] as String?) ?? 'Other';

        if (lat == null || lng == null) continue;

        // Filter by category
        if (_selectedCategory != 'All' && category != _selectedCategory) continue;

        // Calculate distance
        final distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        ) /
            1609.34; // meters to miles

        if (distance <= _searchRadius) {
          final donationData = <String, dynamic>{
            ...data,
            'id': doc.id,
            'distance': distance,
          };

          nearbyDonations.add(donationData);

          // Add marker
          if (_donationIcon != null) {
            markers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(lat, lng),
                icon: _donationIcon!,
                infoWindow: InfoWindow(
                  title: (data['title'] ?? 'Donation').toString(),
                  snippet: '${distance.toStringAsFixed(1)} mi away • ${category.toString()}',
                ),
                onTap: () => _showDonationDetails(donationData),
              ),
            );
          }
        }
      }

      // Sort by distance
      nearbyDonations.sort(
            (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
      );

      setState(() {
        _nearbyDonations = nearbyDonations;
        _markers = markers;
      });
    } catch (e) {
      debugPrint('Error loading donations: $e');
      _showSnackBar('Error loading donations', isError: true);
    } finally {
      setState(() => _loadingDonations = false);
    }
  }

  // ===================== Details sheet =====================
  void _showDonationDetails(Map<String, dynamic> donation) {
    setState(() {
      _selectedDonation = donation;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DonationDetailSheet(
        donation: donation,
        onClose: () {
          setState(() => _selectedDonation = null);
          Navigator.pop(context);
        },
        onNavigate: () {
          final latAny = donation['latitude'];
          final lngAny = donation['longitude'];
          final double lat = (latAny as num).toDouble();
          final double lng = (lngAny as num).toDouble();

          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16.0),
          );
          Navigator.pop(context);
        },

        // ✅ CONTACT -> OPEN CHAT PAGE
        onContact: () async {
          Navigator.pop(context); // close bottom sheet first
          await _openChatForDonation(donation);
        },
      ),
    );
  }

  // ===================== SnackBar =====================
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Mont'),
        ),
        backgroundColor: isError ? Colors.red : primaryPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ===================== Filter Sheet =====================
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [primaryPink, accentPink],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                              fontFamily: 'Mont',
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: lightText),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search Radius Slider
                  Text(
                    'Search Radius: ${_searchRadius.toStringAsFixed(0)} miles',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: darkText,
                      fontFamily: 'Mont',
                      fontSize: 15,
                    ),
                  ),
                  Slider(
                    value: _searchRadius,
                    min: 1.0,
                    max: 30.0,
                    divisions: 29,
                    activeColor: primaryPink,
                    inactiveColor: lightPink,
                    thumbColor: primaryPink,
                    label: '${_searchRadius.toStringAsFixed(0)} mi',
                    onChanged: (value) {
                      setModalState(() => _searchRadius = value);
                      setState(() => _searchRadius = value);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Category Filter
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: darkText,
                      fontFamily: 'Mont',
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return FilterChip(
                        label: Text(
                          category,
                          style: const TextStyle(
                            fontFamily: 'Mont',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setModalState(() => _selectedCategory = category);
                          setState(() => _selectedCategory = category);
                        },
                        selectedColor: primaryPink,
                        backgroundColor: lightPink.withOpacity(0.3),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : darkText,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? primaryPink : lightPink,
                            width: 1.5,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadNearbyDonations();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mont',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    13.0,
                  ),
                );
              }
            },
            markers: _markers,
            circles: _circles,
            myLocationButtonEnabled: false,
            myLocationEnabled: _hasLocationPermission,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Back Button (Top Left)
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryPink, accentPink],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryPink.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  iconSize: 24,
                ),
              ),
            ),
          ),

          // Top Info Panel
          Positioned(
            top: 0,
            left: 70,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: lightPink.withOpacity(0.5), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPink.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryPink, accentPink],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.map_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nearby Donations',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: darkText,
                                  fontFamily: 'Mont',
                                ),
                              ),
                              Text(
                                '${_nearbyDonations.length} items within ${_searchRadius.toStringAsFixed(0)} mi',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: lightText,
                                  fontFamily: 'Mont',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: lightPink.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.tune_rounded, color: primaryPink, size: 22),
                            onPressed: _showFilterSheet,
                          ),
                        ),
                      ],
                    ),
                    if (_loadingDonations) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        color: primaryPink,
                        backgroundColor: lightPink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Donation List (Bottom Sheet)
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.1,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(color: lightPink, width: 2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPink.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryPink, accentPink],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: _nearbyDonations.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 70,
                              color: lightText.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No donations nearby',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: darkText,
                                fontFamily: 'Mont',
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try increasing your search radius',
                              style: TextStyle(
                                fontSize: 14,
                                color: lightText,
                                fontFamily: 'Mont',
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _nearbyDonations.length,
                        itemBuilder: (context, index) {
                          final donation = _nearbyDonations[index];
                          return DonationListCard(
                            donation: donation,
                            onTap: () => _showDonationDetails(donation),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Floating Action Buttons
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                // Refresh Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryPink.withOpacity(0.9),
                        accentPink.withOpacity(0.9),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryPink.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: 'refresh',
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    mini: true,
                    onPressed: _loadNearbyDonations,
                    child: _loadingDonations
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.refresh_rounded),
                  ),
                ),
                const SizedBox(height: 12),

                // My Location Button
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryPink, accentPink],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryPink.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: 'location',
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    onPressed: _getCurrentLocation,
                    child: _loadingLocation
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.my_location_rounded, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== Donation List Card Widget =====================
class DonationListCard extends StatelessWidget {
  final Map<String, dynamic> donation;
  final VoidCallback onTap;

  const DonationListCard({
    Key? key,
    required this.donation,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = (donation['imageUrls'] as List?)?.isNotEmpty == true ? donation['imageUrls'][0] : null;
    final distance = (donation['distance'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightPink.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl != null
                      ? Image.network(
                    imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                      : _buildPlaceholder(),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (donation['title'] ?? 'Donation').toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                          fontFamily: 'Mont',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: lightPink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (donation['category'] ?? 'Other').toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primaryPink,
                            fontFamily: 'Mont',
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: primaryPink),
                          const SizedBox(width: 4),
                          Text(
                            '${distance.toStringAsFixed(1)} miles away',
                            style: const TextStyle(
                              fontSize: 12,
                              color: primaryPink,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mont',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(Icons.chevron_right_rounded, color: primaryPink, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightPink.withOpacity(0.3), lightPink.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        color: primaryPink.withOpacity(0.5),
        size: 35,
      ),
    );
  }
}

// ===================== Donation Detail Sheet Widget =====================
class DonationDetailSheet extends StatelessWidget {
  final Map<String, dynamic> donation;
  final VoidCallback onClose;
  final VoidCallback onNavigate;

  // ✅ NEW: CONTACT CALLBACK
  final VoidCallback onContact;

  const DonationDetailSheet({
    Key? key,
    required this.donation,
    required this.onClose,
    required this.onNavigate,
    required this.onContact, // ✅
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = (donation['imageUrls'] as List?)?.isNotEmpty == true ? donation['imageUrls'][0] : null;
    final distance = (donation['distance'] as num).toDouble();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryPink, accentPink],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Image
          if (imageUrl != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (donation['title'] ?? 'Donation').toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                      fontFamily: 'Mont',
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: lightPink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (donation['category'] ?? 'Other').toString(),
                          style: const TextStyle(
                            color: primaryPink,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            fontFamily: 'Mont',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_rounded, size: 18, color: primaryPink),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} mi away',
                        style: const TextStyle(
                          color: lightText,
                          fontSize: 14,
                          fontFamily: 'Mont',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryPink, accentPink],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                          fontFamily: 'Mont',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    (donation['description'] ?? 'No description available').toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: darkText,
                      height: 1.5,
                      fontFamily: 'Mont',
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (donation['locationAddress'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: lightPink.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: lightPink, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [primaryPink, accentPink],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.place_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              (donation['locationAddress'] ?? '').toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: darkText,
                                fontFamily: 'Mont',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.directions_rounded),
                    label: const Text(
                      'View on Map',
                      style: TextStyle(fontFamily: 'Mont', fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryPink,
                      side: const BorderSide(color: primaryPink, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onContact, // ✅ OPEN CHAT
                    icon: const Icon(Icons.send_rounded),
                    label: const Text(
                      'Contact',
                      style: TextStyle(fontFamily: 'Mont', fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
