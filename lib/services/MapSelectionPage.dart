import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapSelectionPage extends StatefulWidget {
  const MapSelectionPage({super.key});

  @override
  State<MapSelectionPage> createState() => _MapSelectionPage();
}

class _MapSelectionPage extends State<MapSelectionPage> {
  // --- Map State ---
  GoogleMapController? _mapController;
  final LatLng _initialPosition = const LatLng(53.4808, -2.2426); // Default: Manchester, UK
  Marker? _selectedMarker;

  // --- Postcode Search State ---
  final _postcodeController = TextEditingController();
  String _selectedPostcode = "No location selected";

  // --- Text Styles ---
  static const TextStyle _inputStyle = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w500,
  );
  static const TextStyle _hintStyle = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w400,
    color: Colors.grey,
  );

  // --- FIX: Add the dispose method ---
  @override
  void dispose() {
    _mapController?.dispose();
    _postcodeController.dispose();
    super.dispose();
  }
  // ---------------------------------

  // --- Function to search for postcode ---
  void _searchPostcode() async {
    if (_postcodeController.text.isEmpty) return;

    try {
      // Use geocoding to find the location
      List<Location> locations = await locationFromAddress(_postcodeController.text);

      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);

        // Update map and marker
        setState(() {
          _selectedPostcode = _postcodeController.text.toUpperCase();
          _selectedMarker = Marker(
            markerId: const MarkerId("selected_location"),
            position: latLng,
            infoWindow: InfoWindow(title: _selectedPostcode),
          );
        });

        // Move camera to new location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15.0), // Zoom in
        );
      }
    } catch (e) {
      // Handle error (e.g., postcode not found)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postcode not found. Please try again.')),
      );
    }
  }

  // --- Function to set marker on map tap ---
  void _onMapTapped(LatLng latLng) async {
    // Get address details from coordinates
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude,);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _selectedPostcode = placemark.postalCode ?? "Near ${placemark.street}";
      }
    } catch (e) {
      _selectedPostcode = "Selected Coordinates";
    }

    setState(() {
      _selectedMarker = Marker(
        markerId: const MarkerId("selected_location"),
        position: latLng,
        infoWindow: InfoWindow(title: _selectedPostcode),
      );
    });
  }

  // --- Function to confirm and return to Donate page ---
  void _confirmLocation() {
    if (_selectedMarker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first.')),
      );
      return;
    }
    // This pops the page and sends the string back
    if (mounted) { // FIX: Check if mounted
      Navigator.pop(context, _selectedPostcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Pickup Location", style: _inputStyle),
        backgroundColor: Colors.blueGrey,
      ),
      body: Stack(
        children: [
          // --- The Map ---
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped,
            markers: _selectedMarker != null ? {_selectedMarker!} : {},
          ),

          // --- Postcode Search Bar ---
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _postcodeController,
                      style: _inputStyle,
                      decoration: InputDecoration(
                        hintText: "Enter Postcode...",
                        hintStyle: _hintStyle,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(left: 20),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.deepPurple),
                    onPressed: _searchPostcode,
                  ),
                ],
              ),
            ),
          ),

          // --- Confirm Button ---
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
              child: const Text(
                'Confirm This Location',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}