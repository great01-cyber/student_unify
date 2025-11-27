// MapSelectionPage.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_places_autocomplete_widgets/address_autocomplete_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// *** REPLACE WITH YOUR API KEY (remove stray characters) ***
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

  // 🎯 CHANGED: Distance in MILES (default 5 miles)
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

  // --- Permission & Current Location Helpers (Unchanged) ---
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

  // Centers map to given LatLng (and optionally sets marker & updates address text)
  Future<void> _goToLocationAndMark(LatLng latLng, {String? address}) async {
    final infoTitle = address ?? _selectedPostcode;
    setState(() {
      _selectedMarker = Marker(
        markerId: const MarkerId('selected_location'),
        position: latLng,
        infoWindow: InfoWindow(title: infoTitle),
      );
      _selectedPostcode = address ?? infoTitle;
      _autocompleteController.text = _selectedPostcode;
    });

    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 15.0),
    );
  }

  // --- Autocomplete selection handler (Unchanged logic, ensures good address) ---
  void _onPlaceSelected(Place placeDetails) {
    if (placeDetails.lat == null || placeDetails.lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected place has no coordinates')),
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
        infoWindow: InfoWindow(title: infoTitle),
      );
      _autocompleteController.text = displayAddress;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 15.0),
    );
  }

  // --- Map tap -> reverse geocode & set marker (Unchanged logic, ensures readable address) ---
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
          infoWindow: InfoWindow(title: displayTitle),
        );
      });
    } catch (e) {
      setState(() {
        _selectedPostcode = "Selected Coordinates";
        _selectedMarker = Marker(
          markerId: const MarkerId("selected_location"),
          position: latLng,
          infoWindow: const InfoWindow(title: "Selected Coordinates"),
        );
      });
    }
  }

  // --- Confirm: returns "lat,lng||address||distance_mi" ---
  void _confirmLocation() {
    if (_selectedMarker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first.')),
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

    // 🎯 Use MILES in the return value
    // Format: "lat,lng||address||distance_mi"
    final String returnValue =
        "${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}||$addressToReturn||${_selectedDistance.toStringAsFixed(1)}";

    if (mounted) {
      Navigator.pop(context, returnValue);
    }
  }

  // -------------------------
  // UI build
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Pickup Location"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Stack(
        children: [
          // 1. Google Map (Covers the whole background)
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

          // 2. Control Panel Container (Search and Slider)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                color: Colors.white.withOpacity(0.95), // Slight opacity for map visibility
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Search Bar ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: AddressAutocompleteTextField(
                          mapsApiKey: kGoogleApiKey,
                          controller: _autocompleteController,
                          onSuggestionClick: _onPlaceSelected,
                          componentCountry: 'uk',
                          type: AutoCompleteType.postalCode,
                          decoration: InputDecoration(
                            hintText: "Search Postcode or Address...",
                            prefixIcon:
                            const Icon(Icons.search, color: Colors.deepPurple),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(top: 15),
                            suffixIcon: _autocompleteController.text.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _autocompleteController.clear(),
                            )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // --- Distance Slider (Now in miles and separate container) ---
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Search Radius: ${_selectedDistance.toStringAsFixed(0)} mi',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Slider(
                          value: _selectedDistance,
                          min: 1.0,
                          max: 30.0, // Increased max range for miles
                          divisions: 29,
                          label: '${_selectedDistance.toStringAsFixed(0)} mi',
                          activeColor: Colors.deepPurple,
                          onChanged: (double value) {
                            setState(() {
                              _selectedDistance = value;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('1 mi', style: TextStyle(fontSize: 12)),
                            Text('30 mi', style: TextStyle(fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Confirm Button (bottom)
          Positioned(
            bottom: 30,
            left: 50,
            right: 50,
            child: ElevatedButton(
              onPressed: _confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              child: Text(
                'Confirm: $_selectedPostcode',
                style: const TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // 4. My Location FAB (bottom-right)
          // 🎯 This is the "Use Current Location" button.
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'my_location_fab',
              onPressed: () async {
                if (!_hasLocationPermission) {
                  await _checkLocationPermission();
                  if (!_hasLocationPermission) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Location permission is required.')),
                    );
                    return;
                  }
                }
                final pos = await _getCurrentPosition();
                if (pos != null) {
                  final latLng = LatLng(pos.latitude, pos.longitude);

                  // Reverse geocode to find approximate address/postcode
                  String? addr;
                  try {
                    final places = await placemarkFromCoordinates(
                        pos.latitude, pos.longitude);
                    if (places.isNotEmpty) {
                      final pm = places.first;
                      // Build a clean address string
                      addr = [pm.street, pm.locality]
                          .where((s) => s != null && s.isNotEmpty)
                          .join(', ');
                    }
                  } catch (_) {
                    // ignore reverse-geocode failure
                  }

                  await _goToLocationAndMark(latLng, address: addr ?? 'My Current Location');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Unable to determine current location.')),
                  );
                }
              },
              child: _loadingLocation
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}