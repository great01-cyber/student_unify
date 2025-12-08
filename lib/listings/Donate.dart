//
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// map selection page (should be returning either "lat,lng||address" or fallback address string)
import '../Models/DonateModel.dart';
import '../services/MapSelectionPage.dart';

// Required for embedded map preview
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Persistence
import 'package:shared_preferences/shared_preferences.dart';

// Firebase imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/New One.dart';

// 🎯 Ensure this path matches where you saved your Donation model

class Donate extends StatefulWidget {
  final String title;

  const Donate({
    super.key,
    required this.title,
  });

  @override
  State<Donate> createState() => _DonateState();
}

class _DonateState extends State<Donate> {
  // --- Form and Image State ---
  final _formKey = GlobalKey<FormState>();
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  // --- Controllers and Category State ---
  final List<String> _category = const [
    'Academic and Study Materials',
    'Sport and Leisure Wears',
    'Tech and Electronics',
    'Clothing and wears',
    'Dorm and Essential things',
    'Others',
  ];
  String? _selectedCategory;
  final _titleController = TextEditingController();
  final _kgController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _instructionsController = TextEditingController();

  DateTime? _availableFrom;
  DateTime? _availableUntil;

  // location
  String? _selectedLocationInfo;
  LatLng? _selectedLatLng;
  GoogleMapController? _locationMapController;

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }

  @override
  void dispose() {
    // Clean up controllers
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _instructionsController.dispose();
    _locationMapController?.dispose();
    _kgController.dispose();
    super.dispose();
  }

  // --- Load saved location from shared_preferences (format: "lat,lng||address") ---
  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('saved_pickup_location');
      if (saved == null) return;

      LatLng? newLatLng;
      String? info;

      if (saved.contains('||')) {
        final parts = saved.split('||');
        final coords = parts[0];
        info = parts.length > 1 ? parts[1] : null;

        final nums = coords.split(',');
        final lat = double.tryParse(nums[0]);
        final lng = double.tryParse(nums[1]);
        if (lat != null && lng != null) {
          newLatLng = LatLng(lat, lng);
        }
      } else if (saved.contains(',')) {
        final nums = saved.split(',');
        final lat = double.tryParse(nums[0]);
        final lng = double.tryParse(nums[1]);
        if (lat != null && lng != null) {
          newLatLng = LatLng(lat, lng);
        } else {
          info = saved;
        }
      } else {
        info = saved;
      }

      setState(() {
        _selectedLatLng = newLatLng;
        _selectedLocationInfo = info ?? saved;
      });

      // animate embedded map controller if present
      if (_selectedLatLng != null && _locationMapController != null) {
        _locationMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLatLng!, 15.0),
        );
      }
    } catch (e) {
      debugPrint('Failed to load saved location: $e');
    }
  }

  // --- Firebase Storage and Location Persistence Helpers ---

  Future<List<String>> _uploadImagesToFirebase(String docId) async {
    final List<String> urls = [];
    for (var i = 0; i < _images.length; i++) {
      final XFile file = _images[i];
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + file.name;
      final ref = _storage.ref().child('donations').child(docId).child(fileName);

      // Use putData for safer, platform-independent file upload
      final uploadTask = ref.putData(await file.readAsBytes());
      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _persistLocationString(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_pickup_location', value);
  }

  // --- Form Submission Logic (Primary Action) ---
  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must be signed in to post a donation.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please add at least one image.',
            style: TextStyle(fontFamily: 'Quicksand'),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (_selectedLocationInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please confirm your location.',
            style: TextStyle(fontFamily: 'Quicksand'),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      String? donorName = user.displayName;
      // Safely fetch displayName from Firestore, if available
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          donorName = userDoc.data()?['displayName'] as String? ?? user.displayName;
        }
      } catch (e) {
        debugPrint('Error fetching donor name: $e');
      }

      final String docId = _firestore.collection('donations').doc().id;
      final imageUrls = await _uploadImagesToFirebase(docId);

      final newDonation = Donation(
        id: docId,
        category: _selectedCategory ?? 'Unspecified',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: double.tryParse(_priceController.text),
        kg: double.tryParse(_kgController.text),
        imageUrls: imageUrls,
        availableFrom: _availableFrom,
        availableUntil: _availableUntil,
        instructions: _instructionsController.text.trim(),
        locationAddress: _selectedLocationInfo,
        latitude: _selectedLatLng?.latitude,
        longitude: _selectedLatLng?.longitude,

        /// REQUIRED FIELDS
        donorId: user.uid,
        donorName: user.displayName ?? "Unknown Donor",
        donorPhoto: user.photoURL ?? "",

        /// Owner fields — if owner is same as donor
        ownerId: user.uid,
        ownerName: user.displayName ?? "Unknown",
      );


      final Map<String, dynamic> donationData = newDonation.toJson();
      donationData['donorId'] = user.uid;
      donationData['donorEmail'] = user.email;
      donationData['donorName'] = donorName;

      // 1. Save the main donation document
      await _firestore.collection('donations').doc(docId).set(donationData);

      final locString = _selectedLatLng != null
          ? '${_selectedLatLng!.latitude},${_selectedLatLng!.longitude}||${_selectedLocationInfo ?? ''}'
          : (_selectedLocationInfo ?? '');
      await _persistLocationString(locString);

      // 2. 🎯 Trigger the Cloud Function asynchronously
      final notificationService = NotificationService();
      await notificationService.triggerNearbyNotification(
        donationId: docId,
        donationData: donationData,
      ); // No return value expected here

      if (mounted) {
        // Dismiss the loading dialog
        Navigator.of(context).pop();
      }

      setState(() => _isSubmitting = false);

      if (mounted) {
        // 3. ❌ REMOVED: $notificationCount is no longer available/needed.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Donation submitted! Nearby students are being notified.',
              style: TextStyle(fontFamily: 'Quicksand'),
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Clear form fields
      setState(() {
        _images.clear();
        _selectedCategory = null;
        _titleController.clear();
        _descController.clear();
        _priceController.clear();
        _kgController.clear();
        _instructionsController.clear();
      });
    } catch (e, st) {
      if (mounted) {
        // Dismiss the loading dialog on error
        Navigator.of(context).pop();
      }

      setState(() => _isSubmitting = false);

      debugPrint('Upload/save error: $e\n$st');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit donation: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // --- Color and Style Constants (Teal & Amber Scheme) ---
  // 🎨 Modern Donation Page Color Palette
  static const Color _primaryColor = Color(0xFF6366F1); // Vibrant Indigo
  static const Color _accentColor = Color(0xFF8B5CF6); // Purple accent
  static const Color _headerColor = Color(0xFF4F46E5); // Deep Indigo
  static const Color _successColor = Color(0xFF10B981); // Emerald green
  static const Color _warningColor = Color(0xFFF59E0B); // Amber
  static const Color _locationBgColor = Color(0xFFFEF3C7); // Warm cream
  static const Color _locationConfirmedBgColor = Color(0xFFD1FAE5); // Mint green

// Alternative warm palette option:
// static const Color _primaryColor = Color(0xFFEC4899); // Hot pink
// static const Color _accentColor = Color(0xFFF472B6); // Light pink
// static const Color _headerColor = Color(0xFFDB2777); // Deep pink

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Mont',
    fontWeight: FontWeight.w200,
    fontSize: 13,
    color: Color(0xFF4F46E5), // Matches header
  );

  static const TextStyle _inputStyle = TextStyle(
    fontFamily: 'Mont',
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: Color(0xFF1F2937), // Dark gray for readability
  );

  static const TextStyle _hintStyle = TextStyle(
    fontFamily: 'Mont',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: Color(0xFF9CA3AF), // Medium gray
  );

// --- Enhanced Input Decoration ---
  InputDecoration _fancifulDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: _labelStyle,
      hintStyle: _hintStyle,
      prefixIcon: Icon(icon, color: _accentColor, size: 22),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Donate',
          style: const TextStyle(fontFamily: 'Mont', fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          // Form widget for validation
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Category Field (Dropdown) ---
                _buildSectionHeader("Item Category"),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  style: _inputStyle.copyWith(color: Colors.black),
                  decoration: _fancifulDecoration("Select a category", Icons.category),
                  hint: Text(
                    "Select a Category",
                    style: _hintStyle,
                  ),
                  isExpanded: true,
                  items: _category.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (val) => val == null || val.isEmpty ? "Please select a category" : null,
                ),
                const SizedBox(height: 16),

                // --- Title Field (Detailed Name) ---
                _buildSectionHeader("Item Name"),
                TextFormField(
                  controller: _titleController,
                  style: _inputStyle,
                  decoration: _fancifulDecoration("Enter the specific item name", Icons.title),
                  validator: (val) => val!.isEmpty ? "Please enter a detailed item name" : null,
                ),
                const SizedBox(height: 16),

                // --- Description Field ---
                TextFormField(
                  controller: _descController,
                  style: _inputStyle,
                  maxLines: 4,
                  decoration: _fancifulDecoration("Description", Icons.description)
                      .copyWith(alignLabelWithHint: true),
                  validator: (val) => val!.isEmpty ? "Please enter a description" : null,
                ),
                const SizedBox(height: 16),

                // --- Estimated Price Field ---
                TextFormField(
                  controller: _priceController,
                  style: _inputStyle,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fancifulDecoration("Estimated Price (£)", Icons.currency_pound),
                  validator: (val) => val!.isEmpty ? "Please enter a price" : null,
                ),
                Text("This is how much you will be saving a student from spending. Thank you!.", style: TextStyle(fontSize: 10, fontFamily: 'Mont', color: Colors.black),),
                const SizedBox(height: 24),

                // --- Estimated Kg Field ---
                TextFormField(
                  controller: _kgController,
                  style: _inputStyle,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fancifulDecoration("Estimated Kg (Optional)", Icons.scale)
                      .copyWith(alignLabelWithHint: true),
                  // validator is optional as it is not required
                ),
                Text("This is how much you will be saving the environment.", style: TextStyle(fontSize: 10, fontFamily: 'Mont',),),
                const SizedBox(height: 16),

                // --- Image Uploader (Existing Code) ---
                _buildSectionHeader("Add Photos (up to 5)"),
                _buildImageUploader(),
                const SizedBox(height: 24),

                // --- Time Fields ---
                _buildSectionHeader("Availability"),
                Row(
                  children: [
                    Expanded(child: _buildDateTimePicker(
                      label: "From",
                      date: _availableFrom,
                      onTap: () => _selectDateTime(context, isFromDate: true),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDateTimePicker(
                      label: "Until",
                      date: _availableUntil,
                      onTap: () => _selectDateTime(context, isFromDate: false),
                    )),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Pickup Instructions ---
                _buildSectionHeader("Pickup Details"),
                TextFormField(
                  controller: _instructionsController,
                  style: _inputStyle,
                  maxLines: 3,
                  decoration: _fancifulDecoration("Pickup Instructions", Icons.directions)
                      .copyWith(alignLabelWithHint: true),
                ),
                const SizedBox(height: 24),

                // --- Location Section ---
                _buildSectionHeader("Confirm Your Location"),
                _buildLocationSelector(context),
                const SizedBox(height: 32),

                // --- Submit Button ---
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm, // Disable when submitting
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    disabledBackgroundColor: Colors.grey, // Visual feedback for disabled state
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Donate Now',
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper for Section Headers ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: _labelStyle,
        textAlign: TextAlign.right,
      ),
    );
  }

  // --- Helper for Date/Time Picker Fields ---
  Widget _buildDateTimePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    String text = date == null
        ? "Not Set"
        : DateFormat('MMM d, yyyy - hh:mm a').format(date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF6366F1), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _hintStyle.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              text,
              style: _inputStyle.copyWith(
                fontSize: 13,
                color: date == null ? Colors.grey[600] : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper for Location Selector Button / Map Preview ---
  Widget _buildLocationSelector(BuildContext context) {
    // If we have coordinates, show embedded map preview
    if (_selectedLatLng != null) {
      return Container(
        width: double.infinity,
        height: 180,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _locationConfirmedBgColor, // Use confirmed color
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF6366F1),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLatLng!,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('donation_location'),
                      position: _selectedLatLng!,
                    )
                  },
                  onMapCreated: (controller) {
                    _locationMapController = controller;
                  },
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  // Disable map interactions to make it a static preview
                  gestureRecognizers: {},
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedLocationInfo ?? 'Location Confirmed',
                    style: _inputStyle.copyWith(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    // Allow user to re-open the map selection and edit
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (context) => const MapSelectionPage()),
                    );
                    _handleMapResult(result);
                  },
                  icon: const Icon(Icons.edit_location, color: Color(0xFF6366F1)),
                  label: const Text("Change", style: TextStyle(color: Color(0xFF6366F1), fontFamily: 'Mont')),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default (no coordinates): show tappable card
    return InkWell(
      onTap: () async {
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (context) => const MapSelectionPage()),
        );

        _handleMapResult(result);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: _locationBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF6366F1),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.location_on, color: Colors.teal.shade700, size: 30),
            const SizedBox(height: 8),
            Text(
              _selectedLocationInfo ?? "Click to set pickup location",
              style: _inputStyle.copyWith(color: Colors.teal.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Parse / Handle result returned from MapSelectionPage ---
  void _handleMapResult(String? result) {
    if (result == null) return;

    // Reset existing map state
    LatLng? newLatLng;
    String? info;

    try {
      if (result.contains('||')) {
        // Format: "lat,lng||address"
        final parts = result.split('||');
        final coords = parts[0];
        info = parts.length > 1 ? parts[1] : null;

        final nums = coords.split(',');
        final lat = double.tryParse(nums[0]);
        final lng = double.tryParse(nums[1]);
        if (lat != null && lng != null) {
          newLatLng = LatLng(lat, lng);
        }
      } else if (result.contains(',')) {
        // Maybe just "lat,lng"
        final nums = result.split(',');
        final lat = double.tryParse(nums[0]);
        final lng = double.tryParse(nums[1]);
        if (lat != null && lng != null) {
          newLatLng = LatLng(lat, lng);
        } else {
          // Not parsable as coords, treat as address
          info = result;
        }
      } else {
        // Plain address/postcode string
        info = result;
      }
    } catch (_) {
      // Fallback: treat everything as text
      info = result;
    }

    setState(() {
      _selectedLatLng = newLatLng;
      _selectedLocationInfo = info ?? result;
      // Optionally, move embedded map camera if exists
      if (_selectedLatLng != null && _locationMapController != null) {
        _locationMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLatLng!, 15.0),
        );
      }
    });
  }

  // --- Function to handle Date & Time picking ---
  Future<void> _selectDateTime(BuildContext context, {required bool isFromDate}) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final fullDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      if (isFromDate) {
        _availableFrom = fullDate;
      } else {
        _availableUntil = fullDate;
      }
    });
  }

  // --- Image Picker Logic (Functions) ---
  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo', style: TextStyle(fontFamily: 'Quicksand')),
                onTap: () { _pickImage(ImageSource.camera); Navigator.of(context).pop(); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Library', style: TextStyle(fontFamily: 'Quicksand')),
                onTap: () { _pickImage(ImageSource.gallery); Navigator.of(context).pop(); },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only add up to 5 images.', style: TextStyle(fontFamily: 'Quicksand'))),
      );
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      setState(() { _images.add(pickedFile); });
    }
  }

  void _removeImage(int index) {
    setState(() { _images.removeAt(index); });
  }

  // --- Image Uploader UI (Widget) ---
  Widget _buildImageUploader() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(0xFF6366F1), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade50.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _images.length < 5 ? _images.length + 1 : 5,
        itemBuilder: (context, index) {
          if (index == _images.length) {
            return AddImageButton(onPressed: _showImagePickerSheet);
          }
          return ImageTile(
            file: File(_images[index].path),
            onRemove: () => _removeImage(index),
          );
        },
      ),
    );
  }
}

// --- Image Uploader Helper Widgets (Unchanged) ---
class AddImageButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AddImageButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(0xFF6366F1),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add_a_photo_outlined,
            color: Color(0xFF6366F1),
            size: 30,
          ),
        ),
      ),
    );
  }
}

class ImageTile extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const ImageTile({super.key, required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(file, fit: BoxFit.cover),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}