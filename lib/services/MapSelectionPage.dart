// MapSelectionPage.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_places_autocomplete_widgets/address_autocomplete_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Color palette - consistent with the app
const Color primaryPink = Color(0xFFFF6786);
const Color lightPink = Color(0xFFFFE5EC);
const Color accentPink = Color(0xFFFF9BAD);
const Color darkText = Color(0xFF2D3748);
const Color lightText = Color(0xFF718096);

const String kGoogleApiKey = "AIzaSyDEZD5JDtSClTS3qSrG0OU3dJGo-3OADwY";

class MapSelectionPage extends StatefulWidget {
  const MapSelectionPage({super.key});

  @override
  State<MapSelectionPage> createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage> {
  GoogleMapController? _mapController;
  final LatLng _initialPosition = const LatLng(53.4808, -2.2426); // Manchester
  Marker? _selectedMarker;
  final TextEditingController _autocompleteController = TextEditingController();

  String _selectedPostcode = "No location selected";
  bool _hasLocationPermission = false;
  bool _loadingLocation = false;

  double _selectedDistance = 5.0;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _autocompleteController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (!mounted) return;
    setState(() {
      _hasLocationPermission = granted;
    });
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      setState(() => _loadingLocation = true);
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      return pos;
    } catch (e) {
      debugPrint('getCurrentPosition error: $e');
      return null;
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _goToLocationAndMark(LatLng latLng, {String? address}) async {
    final infoTitle = address ?? _selectedPostcode;
    setState(() {
      _selectedMarker = Marker(
        markerId: const MarkerId('selected_location'),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        infoWindow: InfoWindow(title: infoTitle),
      );
      _selectedPostcode = address ?? infoTitle;
      _autocompleteController.text = _selectedPostcode;
    });

    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 15.0),
    );
  }

  void _onPlaceSelected(Place placeDetails) {
    if (placeDetails.lat == null || placeDetails.lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selected place has no coordinates'),
          backgroundColor: primaryPink,
        ),
      );
      return;
    }
    final latLng = LatLng(placeDetails.lat!, placeDetails.lng!);
    String displayAddress = placeDetails.formattedAddress ?? "Selected Location";
    String infoTitle = placeDetails.name ?? displayAddress;

    setState(() {
      _selectedPostcode = displayAddress;
      _selectedMarker = Marker(
        markerId: const MarkerId("selected_location"),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        infoWindow: InfoWindow(title: infoTitle),
      );
      _autocompleteController.text = displayAddress;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 15.0),
    );
  }

  void _onMapTapped(LatLng latLng) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

      String displayTitle;
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final streetAndCity = [placemark.street, placemark.locality]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');

        final candidate = streetAndCity.isNotEmpty
            ? streetAndCity
            : placemark.postalCode ?? "Selected Location";

        _selectedPostcode = candidate;
        displayTitle = candidate;
        _autocompleteController.text = candidate;
      } else {
        _selectedPostcode = "Selected Coordinates";
        displayTitle = _selectedPostcode;
      }

      setState(() {
        _selectedMarker = Marker(
          markerId: const MarkerId("selected_location"),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: InfoWindow(title: displayTitle),
        );
      });
    } catch (e) {
      setState(() {
        _selectedPostcode = "Selected Coordinates";
        _selectedMarker = Marker(
          markerId: const MarkerId("selected_location"),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: const InfoWindow(title: "Selected Coordinates"),
        );
      });
    }
  }

  void _confirmLocation() {
    if (_selectedMarker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a location first.'),
          backgroundColor: primaryPink,
        ),
      );
      return;
    }

    final LatLng pos = _selectedMarker!.position;
    final double lat = pos.latitude;
    final double lng = pos.longitude;

    final String addressToReturn = (_selectedMarker!.infoWindow.title != null &&
        _selectedMarker!.infoWindow.title!.isNotEmpty)
        ? _selectedMarker!.infoWindow.title!
        : _selectedPostcode;

    final String returnValue =
        "${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}||$addressToReturn||${_selectedDistance.toStringAsFixed(1)}";

    if (mounted) {
      Navigator.pop(context, returnValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Select Pickup Location",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPink, accentPink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition:
            CameraPosition(target: _initialPosition, zoom: 12),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped,
            markers: _selectedMarker != null ? {_selectedMarker!} : {},
            myLocationButtonEnabled: false,
            myLocationEnabled: _hasLocationPermission,
            zoomControlsEnabled: false,
          ),

          // Control Panel Container
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPink.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: lightPink.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: lightPink, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: AddressAutocompleteTextField(
                          mapsApiKey: kGoogleApiKey,
                          controller: _autocompleteController,
                          onSuggestionClick: _onPlaceSelected,
                          componentCountry: 'uk',
                          type: AutoCompleteType.postalCode,
                          decoration: InputDecoration(
                            hintText: "Search Postcode or Address...",
                            hintStyle: TextStyle(color: lightText),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: primaryPink, size: 24),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(top: 15),
                            suffixIcon: _autocompleteController.text.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: lightText),
                              onPressed: () =>
                                  _autocompleteController.clear(),
                            )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Distance Slider
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: lightPink.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.radar_rounded,
                                  color: primaryPink, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Search Radius: ${_selectedDistance.toStringAsFixed(0)} mi',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: darkText,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: primaryPink,
                              inactiveTrackColor: lightPink,
                              thumbColor: primaryPink,
                              overlayColor: primaryPink.withOpacity(0.2),
                              valueIndicatorColor: primaryPink,
                              valueIndicatorTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Slider(
                              value: _selectedDistance,
                              min: 1.0,
                              max: 30.0,
                              divisions: 29,
                              label: '${_selectedDistance.toStringAsFixed(0)} mi',
                              onChanged: (double value) {
                                setState(() {
                                  _selectedDistance = value;
                                });
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('1 mi',
                                  style: TextStyle(
                                      fontSize: 12, color: lightText)),
                              Text('30 mi',
                                  style: TextStyle(
                                      fontSize: 12, color: lightText)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Confirm Button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryPink.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _confirmLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 24),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _selectedPostcode == "No location selected"
                            ? 'Select a Location'
                            : 'Confirm Location',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // My Location FAB
          Positioned(
            bottom: 100,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [primaryPink, accentPink],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryPink.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'my_location_fab',
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: () async {
                  if (!_hasLocationPermission) {
                    await _checkLocationPermission();
                    if (!_hasLocationPermission) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Location permission is required.'),
                          backgroundColor: primaryPink,
                        ),
                      );
                      return;
                    }
                  }
                  final pos = await _getCurrentPosition();
                  if (pos != null) {
                    final latLng = LatLng(pos.latitude, pos.longitude);

                    String? addr;
                    try {
                      final places = await placemarkFromCoordinates(
                          pos.latitude, pos.longitude);
                      if (places.isNotEmpty) {
                        final pm = places.first;
                        addr = [pm.street, pm.locality]
                            .where((s) => s != null && s.isNotEmpty)
                            .join(', ');
                      }
                    } catch (_) {
                      // ignore reverse-geocode failure
                    }

                    await _goToLocationAndMark(latLng,
                        address: addr ?? 'My Current Location');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Unable to determine current location.'),
                        backgroundColor: primaryPink,
                      ),
                    );
                  }
                },
                child: _loadingLocation
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.my_location_rounded, size: 28),
              ),
            ),
          ),

          // Instruction Badge (Optional - adds helpful hint)
          if (_selectedMarker == null)
            Positioned(
              top: 220,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: primaryPink, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap on the map or search to select a location',
                        style: TextStyle(
                          fontSize: 13,
                          color: darkText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}