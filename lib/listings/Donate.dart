// donate.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// map selection page (should be returning either "lat,lng||address" or fallback address string)
import '../services/MapSelectionPage.dart';

// Required for embedded map preview
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Persistence
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // --- Controllers for Text Fields ---
  final List<String> _category= const [
    "Free Academic and study materials",
    "Sport and Leisure",
    "Clothing and Accessories",
    "Dorm and Living essentials",
    "Free Tech and Electronics",
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
      // ----------------- Firebase upload + save (auth enforced) -----------------
      Future<List<String>> _uploadImagesToFirebase(String docId) async {
        final List<String> urls = [];
        for (var i = 0; i < _images.length; i++) {
          final XFile file = _images[i];
          final String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + file.name;
          final ref = _storage.ref().child('donations').child(docId).child(fileName);
          final uploadTask = ref.putFile(File(file.path));
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

      Future<void> _submitForm() async {
        if (_isSubmitting) return;
        if (!_formKey.currentState!.validate()) return;

        // require authenticated user (no extra login UI here)
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('You must be signed in to post a donation.'), backgroundColor: Colors.red.shade700),
          );
          return;
        }

        if (_images.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Please add at least one image.', style: TextStyle(fontFamily: 'Quicksand')), backgroundColor: Colors.red.shade700),
          );
          return;
        }

        if (_selectedLocationInfo == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Please confirm your location.', style: TextStyle(fontFamily: 'Quicksand')), backgroundColor: Colors.red.shade700),
          );
          return;
        }

        setState(() => _isSubmitting = true);

        // show progress
        showDialog(context: context, barrierDismissible: false, builder: (_) => WillPopScope(onWillPop: () async => false, child: const Center(child: CircularProgressIndicator())));

        try {
          // try to read extra donor info from your users collection (if present)
          String? donorName;
          try {
            final userDoc = await _firestore.collection('users').doc(user.uid).get();
            if (userDoc.exists) {
              final data = userDoc.data();
              donorName = (data != null && data['displayName'] != null) ? data['displayName'] as String : user.displayName;
            } else {
              donorName = user.displayName;
            }
          } catch (e) {
            donorName = user.displayName;
          }

          // prepare doc id
          final String docId = _firestore.collection('donations').doc().id;

          // upload images
          final imageUrls = await _uploadImagesToFirebase(docId);

          // build donation data with donor info (from auth + users collection)
          final Map<String, dynamic> donationData = {
            'category': _selectedCategory ?? 'Unspecified',
            'title': _titleController.text.trim(),
            'description': _descController.text.trim(),
            'price': double.tryParse(_priceController.text),
            'kg': double.tryParse(_kgController.text),
            'imageUrls': imageUrls,
            'availableFrom': _availableFrom?.toIso8601String(),
            'availableUntil': _availableUntil?.toIso8601String(),
            'instructions': _instructionsController.text.trim(),
            'locationAddress': _selectedLocationInfo,
            'latitude': _selectedLatLng?.latitude,
            'longitude': _selectedLatLng?.longitude,
            'createdAt': DateTime.now().toIso8601String(),
            // donor info:
            'donorId': user.uid,
            'donorEmail': user.email,
            'donorName': donorName,
            'id': docId,
          };

          // save to firestore under docId
          await _firestore.collection('donations').doc(docId).set(donationData);

          // persist location locally
          final locString = _selectedLatLng != null
              ? '${_selectedLatLng!.latitude},${_selectedLatLng!.longitude}||${_selectedLocationInfo ?? ''}'
              : (_selectedLocationInfo ?? '');
          await _persistLocationString(locString);

          // done
          Navigator.of(context).pop(); // close progress
          setState(() => _isSubmitting = false);

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Donation submitted!'), backgroundColor: Colors.green.shade700));

          // clear form (keeps location persisted)
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
          Navigator.of(context).pop(); // close progress
          setState(() => _isSubmitting = false);
          debugPrint('Upload/save error: $e\n$st');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit donation: $e'), backgroundColor: Colors.red.shade700));
        }
      }
    } catch (e) {
      debugPrint('Failed to load saved location: $e');
    }
  }

  // --- Text Style Helpers ---
  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Colors.teal,
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

  // --- Fanciful Input Decoration ---
  InputDecoration _fancifulDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: _hintStyle,
      prefixIcon: Icon(icon, color: Colors.teal.shade300),
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.teal, width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
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
                // --- Title Field ---
                _buildSectionHeader("Item Details"),
                TextFormField(
                  controller: _titleController,
                  style: _inputStyle,
                  decoration: _fancifulDecoration("Please enter the name of the item you are given out.", Icons.title),
                  validator: (val) => val!.isEmpty ? "Please enter a title" : null,
                ),
                const SizedBox(height: 16),

                // --- Category Field ---
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
                  decoration: _fancifulDecoration("Estimated Price (£)", Icons.attach_money),
                  validator: (val) => val!.isEmpty ? "Please enter a price" : null,
                ),
                Text("This is how much you will be saving the environment.", style: TextStyle(fontSize: 8, fontFamily: 'Quicksand',fontWeight: FontWeight.w100, color: Colors.black),),
                const SizedBox(height: 24),

                // --- Description Field ---
                TextFormField(
                  controller: _kgController,
                  style: _inputStyle,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fancifulDecoration("Estimated Kg", Icons.description)
                      .copyWith(alignLabelWithHint: true),
                  //validator: (val) => val!.isEmpty ? "Please enter a description" : null,
                ),
                Text("This is how much you will be saving the environment.", style: TextStyle(fontSize: 8, fontFamily: 'Quicksand',fontWeight: FontWeight.w100 ),),
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
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text(
                    'Donate Now',
                    style: TextStyle(
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
          border: Border.all(color: Colors.black12, width: 1.5),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.teal.shade200,
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
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedLocationInfo ?? '',
                    style: _inputStyle.copyWith(color: Colors.teal.shade700),
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
                  icon: const Icon(Icons.edit_location, color: Colors.teal),
                  label: const Text("Change", style: TextStyle(color: Colors.teal)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default (no coordinates): show tappable card (same look as before)
    return InkWell(
      onTap: () async {
        // Navigate to the map page. Prefer MapSelectionPage to return:
        // - "lat,lng||address" (recommended), OR
        // - "lat,lng" OR
        // - "address string"
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
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.teal.shade200,
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

  // --- Form Submission Logic ---
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please add at least one image.', style: TextStyle(fontFamily: 'Quicksand')),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      if (_selectedLocationInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please confirm your location.', style: TextStyle(fontFamily: 'Quicksand')),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      // If all checks pass:
      print("--- DONATION FORM DATA ---");
      print("Title: ${_titleController.text}");
      print("Description: ${_descController.text}");
      print("Price: ${_priceController.text}");
      print("Images: ${_images.length} images");
      print("Available From: $_availableFrom");
      print("Available Until: $_availableUntil");
      print("Instructions: ${_instructionsController.text}");
      print("Location: $_selectedLocationInfo (coords: $_selectedLatLng)");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Donation submitted! (Check console)', style: TextStyle(fontFamily: 'Quicksand')),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
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
        border: Border.all(color: Colors.teal.shade200, width: 2),
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

// --- Image Uploader Helper Widgets ---
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
            color: Colors.teal.shade200,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add_a_photo_outlined,
            color: Colors.teal.shade400,
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
                  color: Colors.teal.shade400,
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
