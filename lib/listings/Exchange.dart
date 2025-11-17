import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/MapSelectionPage.dart';
import 'BorrowPage.dart';
// import '../Models/ExchangeModel.dart'; // 🎯 You must create this model

class ExchangePage extends StatefulWidget {
  final String title;

  const ExchangePage({
    super.key,
    required this.title,
  });

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> {
  // --- Form and Image State ---
  final _formKey = GlobalKey<FormState>();
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  // --- Controllers and Category State ---
  final List<String> _category = const [
    'Free Academic and Study Materials',
    'Sport and Leisure Wears',
    'Free Tech and Electronics',
    'Free clothing and wears',
    'Dorm and Essential things',
    'Others',
  ];
  String? _selectedCategory;

  // Fields for the item the user HAS (Offered)
  final _offeredTitleController = TextEditingController();
  final _offeredDescController = TextEditingController();

  // Fields for the item the user WANTS (Wanted)
  final _wantedTitleController = TextEditingController();
  final _wantedDescController = TextEditingController();

  // Terms and conditions for the swap
  final _termsController = TextEditingController();

  // location
  String? _selectedLocationInfo;
  LatLng? _selectedLatLng;
  GoogleMapController? _locationMapController;

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collectionName = 'exchanges'; // 🎯 NEW COLLECTION

  bool _isSubmitting = false;

  // --- Color and Style Constants (Orange/Amber Scheme) ---
  static final Color _primaryColor = Colors.orange.shade700; // 🎯 CHANGE
  static final Color _accentColor = Colors.amber.shade400;  // 🎯 CHANGE
  static final Color _headerColor = Colors.orange.shade800;  // 🎯 CHANGE
  static final Color _locationBgColor = Colors.orange.shade50; // 🎯 CHANGE
  static final Color _locationConfirmedBgColor = Colors.orange.shade50; // 🎯 CHANGE

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Colors.orange, // 🎯 CHANGE
  );
  static const TextStyle _inputStyle = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );
  static const TextStyle _hintStyle = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w400,
    color: Colors.grey,
  );


  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }

  @override
  void dispose() {
    _offeredTitleController.dispose();
    _offeredDescController.dispose();
    _wantedTitleController.dispose();
    _wantedDescController.dispose();
    _termsController.dispose();
    _locationMapController?.dispose();
    super.dispose();
  }

  // ------------------- LOCATION AND PERSISTENCE -------------------

  Future<void> _loadSavedLocation() async {
    // ... (Implementation same as Borrow/Lend)
  }

  Future<List<String>> _uploadImagesToFirebase(String docId) async {
    final List<String> urls = [];
    for (var i = 0; i < _images.length; i++) {
      final XFile file = _images[i];
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + file.name;
      // 🎯 CHANGE: Storage path uses 'exchanges'
      final ref = _storage.ref().child(_collectionName).child(docId).child(fileName);

      final uploadTask = ref.putData(await file.readAsBytes());
      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _persistLocationString(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_exchange_location', value);
  }

  // --- Parse / Handle result returned from MapSelectionPage ---
  void _handleMapResult(String? result) {
    if (result == null) return;

    // ... (Parsing logic same as Borrow/Lend)
    LatLng? newLatLng;
    String? info;
    try {
      if (result.contains('||')) {
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
        final nums = result.split(',');
        final lat = double.tryParse(nums[0]);
        final lng = double.tryParse(nums[1]);
        if (lat != null && lng != null) {
          newLatLng = LatLng(lat, lng);
        } else {
          info = result;
        }
      } else {
        info = result;
      }
    } catch (_) {
      info = result;
    }

    setState(() {
      _selectedLatLng = newLatLng;
      _selectedLocationInfo = info ?? result;
      if (_selectedLatLng != null && _locationMapController != null) {
        _locationMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLatLng!, 15.0),
        );
      }
    });
  }

  // ------------------- IMAGE PICKER LOGIC -------------------

  void _showImagePickerSheet() {
    // ... (Implementation same as Borrow/Lend)
  }

  Future<void> _pickImage(ImageSource source) async {
    // ... (Implementation same as Borrow/Lend)
  }

  void _removeImage(int index) {
    setState(() { _images.removeAt(index); });
  }

  // ------------------- FORM SUBMISSION -------------------

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    // ... (User and Location Validation same as Borrow/Lend)

    setState(() => _isSubmitting = true);
    showDialog(context: context, barrierDismissible: false, builder: (_) => WillPopScope(onWillPop: () async => false, child: const Center(child: CircularProgressIndicator())));


    try {
      final user = FirebaseAuth.instance.currentUser!;
      String? userName = user.displayName;

      // ... (Get user data)

      final String docId = _firestore.collection(_collectionName).doc().id;
      final imageUrls = await _uploadImagesToFirebase(docId);

      // 🎯 Exchange Data Structure
      final Map<String, dynamic> exchangeData = {
        'id': docId,
        'category': _selectedCategory ?? 'Unspecified',
        'offeredItem': {
          'title': _offeredTitleController.text.trim(),
          'description': _offeredDescController.text.trim(),
          'imageUrls': imageUrls,
        },
        'wantedItem': {
          'title': _wantedTitleController.text.trim(),
          'description': _wantedDescController.text.trim(), // Optional field
        },
        'swapTerms': _termsController.text.trim(),
        'locationAddress': _selectedLocationInfo,
        'latitude': _selectedLatLng?.latitude,
        'longitude': _selectedLatLng?.longitude,
        'ownerId': user.uid,
        'ownerEmail': user.email,
        'ownerName': userName,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_collectionName).doc(docId).set(exchangeData);

      // ... (Persist location, clear form, success snackbar)
      final locString = _selectedLatLng != null
          ? '${_selectedLatLng!.latitude},${_selectedLatLng!.longitude}||${_selectedLocationInfo ?? ''}'
          : (_selectedLocationInfo ?? '');
      await _persistLocationString(locString);

      Navigator.of(context).pop();
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Exchange offer posted!'), backgroundColor: Colors.orange.shade700));

      _clearForm();

    } catch (e, st) {
      // ... (Error handling)
    }
  }

  void _clearForm() {
    setState(() {
      _images.clear();
      _selectedCategory = null;
      _offeredTitleController.clear();
      _offeredDescController.clear();
      _wantedTitleController.clear();
      _wantedDescController.clear();
      _termsController.clear();
    });
  }


  // ------------------- UI WIDGETS AND HELPERS (Orange Theme) -------------------

  InputDecoration _fancifulDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: _hintStyle,
      prefixIcon: Icon(icon, color: _accentColor),
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.orange.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 2.0),
      ),
    );
  }

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

  // --- Image Uploader UI (Orange Theme) ---
  Widget _buildImageUploader() {
    final Color _shadowColor = Colors.orange.shade50;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withOpacity(0.5),
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
            // Need adapted helper widgets
            return AddImageButton(onPressed: _showImagePickerSheet, primaryColor: _primaryColor, accentColor: Colors.orange.shade200);
          }
          return ImageTile(
            file: File(_images[index].path),
            onRemove: () => _removeImage(index),
            primaryColor: _primaryColor,
          );
        },
      ),
    );
  }

  // --- Helper for Location Selector Button / Map Preview (Orange Theme) ---
  Widget _buildLocationSelector(BuildContext context) {

    if (_selectedLatLng != null) {
      // ... (Implementation same as Borrow/Lend, but using orange colors)
      return Container(
        width: double.infinity,
        height: 180,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _locationConfirmedBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.shade200,
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
                  initialCameraPosition: CameraPosition(target: _selectedLatLng!, zoom: 15),
                  markers: {Marker(markerId: const MarkerId('exchange_location'), position: _selectedLatLng!)},
                  onMapCreated: (controller) => _locationMapController = controller,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
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
                    style: _inputStyle.copyWith(color: _primaryColor, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (context) => const MapSelectionPage()),
                    );
                    _handleMapResult(result);
                  },
                  icon: Icon(Icons.edit_location, color: _primaryColor),
                  label: Text("Change", style: TextStyle(color: _primaryColor, fontFamily: 'Quicksand')),
                ),
              ],
            ),
          ],
        ),
      );
    }

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
            color: Colors.orange.shade200,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.location_on, color: _primaryColor, size: 30),
            const SizedBox(height: 8),
            Text(
              _selectedLocationInfo ?? "Click to set the swap location",
              style: _inputStyle.copyWith(color: _primaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  // ------------------- MAIN BUILD -------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.bold)),
        backgroundColor: _headerColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Category Field (Dropdown) ---
                _buildSectionHeader("Category of Offered Item"),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  style: _inputStyle.copyWith(color: Colors.black),
                  decoration: _fancifulDecoration("Select category of item you have", Icons.category),
                  hint: Text("Select a Category", style: _hintStyle),
                  isExpanded: true,
                  items: _category.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() { _selectedCategory = newValue; });
                  },
                  validator: (val) => val == null || val.isEmpty ? "Please select a category" : null,
                ),
                const SizedBox(height: 24),

                // --- Offered Item Section (What I Have) ---
                Divider(color: _accentColor, thickness: 2),
                const SizedBox(height: 16),
                Text('1. The Item You Are OFFERING', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor, fontFamily: 'Quicksand')),
                const SizedBox(height: 16),

                // Title
                _buildSectionHeader("Offered Item Name"),
                TextFormField(
                  controller: _offeredTitleController,
                  style: _inputStyle,
                  decoration: _fancifulDecoration("e.g., Apple iPad Pro 2021", Icons.devices_other),
                  validator: (val) => val!.isEmpty ? "Please enter the item you are offering" : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _offeredDescController,
                  style: _inputStyle,
                  maxLines: 4,
                  decoration: _fancifulDecoration("Condition, features, and history of your item", Icons.description).copyWith(alignLabelWithHint: true),
                  validator: (val) => val!.isEmpty ? "Please describe the item you are offering" : null,
                ),
                const SizedBox(height: 24),

                // Photos
                _buildSectionHeader("Photos of Offered Item"),
                _buildImageUploader(),
                const SizedBox(height: 32),

                // --- Wanted Item Section (What I Want) ---
                Divider(color: _accentColor, thickness: 2),
                const SizedBox(height: 16),
                Text('2. The Item You Are SEEKING in Return', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor, fontFamily: 'Quicksand')),
                const SizedBox(height: 16),

                // Wanted Title
                _buildSectionHeader("Wanted Item Name"),
                TextFormField(
                  controller: _wantedTitleController,
                  style: _inputStyle,
                  decoration: _fancifulDecoration("e.g., DSLR Camera or High-End Headphones", Icons.search),
                  validator: (val) => val!.isEmpty ? "Please specify what you are looking for" : null,
                ),
                const SizedBox(height: 16),

                // Wanted Description (Optional)
                TextFormField(
                  controller: _wantedDescController,
                  style: _inputStyle,
                  maxLines: 4,
                  decoration: _fancifulDecoration("Desired specifications, model, or condition (Optional)", Icons.lightbulb_outline).copyWith(alignLabelWithHint: true),
                ),
                const SizedBox(height: 32),

                // --- Swap Terms and Location ---
                Divider(color: _accentColor, thickness: 2),
                const SizedBox(height: 16),

                // Terms
                _buildSectionHeader("Swap Terms / Notes"),
                TextFormField(
                  controller: _termsController,
                  style: _inputStyle,
                  maxLines: 3,
                  decoration: _fancifulDecoration("Specific terms (e.g., 'Will add \$50 cash difference')", Icons.paid).copyWith(alignLabelWithHint: true),
                  validator: (val) => val!.isEmpty ? "Please state terms or 'Negotiable'" : null,
                ),
                const SizedBox(height: 24),

                // Location
                _buildSectionHeader("Preferred Swap Location"),
                _buildLocationSelector(context),
                const SizedBox(height: 32),

                // --- Submit Button ---
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.compare_arrows, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Post Swap Offer', // 🎯 CHANGE
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Quicksand'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------- Image Uploader Helper Widgets (Reused) -------------------

// These helper widgets need to be defined outside the state class or adapted
// to be passed the correct primary/accent colors. Assuming they are defined
// globally or in a separate file (as shown in the previous complete example).
// For simplicity, I've left the placeholder in the code above and rely on
// the image helper widgets defined in the previous complete answer.