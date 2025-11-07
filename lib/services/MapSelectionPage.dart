import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_places_autocomplete_widgets/address_autocomplete_widgets.dart';

// !!! REPLACE WITH YOUR ACTUAL GOOGLE MAPS API KEY !!!
const String kGoogleApiKey = "AIzaSyDEZD5JDtSClTS3qSrG0OU3dJGo-3OADwY";

class MapSelectionPage extends StatefulWidget {
  const MapSelectionPage({super.key});

  @override
  State<MapSelectionPage> createState() => _MapSelectionPage();
}

class _MapSelectionPage extends State<MapSelectionPage> {
  // --- Map State ---
  GoogleMapController? _mapController;
  final LatLng _initialPosition = const LatLng(53.4808, -2.2426); // Manchester, UK
  Marker? _selectedMarker;

  // Controller for the AddressAutocompleteTextField
  final TextEditingController _autocompleteController = TextEditingController();

  // --- Location State ---
  String _selectedPostcode = "No location selected";

  // --- Text Styles ---
  static const TextStyle _inputStyle = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w500,
  );

  @override
  void dispose() {
    _mapController?.dispose();
    _autocompleteController.dispose();
    super.dispose();
  }

  // --- Handle Place Selection from Autocomplete ---
  void _onPlaceSelected(Place placeDetails) {
    if (placeDetails.lat == null || placeDetails.lng == null) {
      debugPrint("⚠️ No coordinates found for selected place.");
      return;
    }

    final latLng = LatLng(placeDetails.lat!, placeDetails.lng!);

    // Extract postcode or fallback to address
    String postcode = placeDetails.zipCode ??
        placeDetails.formattedAddress ??
        "Selected Location";

    String infoTitle = placeDetails.name ??
        placeDetails.formattedAddress ??
        "Selected Location";

    setState(() {
      _selectedPostcode = postcode.toUpperCase();
      _selectedMarker = Marker(
        markerId: const MarkerId("selected_location"),
        position: latLng,
        infoWindow: InfoWindow(title: infoTitle),
      );
    });

    // Move the camera to the selected location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 15.0),
    );
  }

  // --- Handle Tap on Map (Reverse Geocoding) ---
  void _onMapTapped(LatLng latLng) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

      String displayTitle;
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _selectedPostcode = placemark.postalCode ??
            "${placemark.street}, ${placemark.locality}";
        displayTitle = _selectedPostcode;

        // Update autocomplete field
        _autocompleteController.text = _selectedPostcode;
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

  // --- Confirm and Return Selected Location ---
  void _confirmLocation() {
    if (_selectedMarker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first.')),
      );
      return;
    }

    // Get coords from selected marker
    final LatLng pos = _selectedMarker!.position;
    final double lat = pos.latitude;
    final double lng = pos.longitude;

    // Prefer a human-readable address if available; otherwise use the postcode string
    final String addressOrPostcode = (_selectedMarker!.infoWindow.title != null &&
        _selectedMarker!.infoWindow.title!.isNotEmpty)
        ? _selectedMarker!.infoWindow.title!
        : _selectedPostcode;

    // Build the return value in the format your Donate page expects:
    // "lat,lng||address"
    final String returnValue = "${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}||$addressOrPostcode";

    if (mounted) {
      Navigator.pop(context, returnValue);
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
          // --- Google Map ---
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped,
            markers: _selectedMarker != null ? {_selectedMarker!} : {},
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
          ),

          // --- Autocomplete Text Field ---
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: SafeArea(
              child: Container(
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
              child: Text(
                'Confirm: $_selectedPostcode',
                textAlign: TextAlign.center,
                style: const TextStyle(
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
