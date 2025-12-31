import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// map selection page (should be returning either "lat,lng||address" or fallback address string)/ 🎯 Change: Assuming you have a LendModel
import '../Models/LendPage.dart';
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

// 🎯 Ensure this path matches where you saved your Lend model

class LendPage extends StatefulWidget {
  final String title;

  const LendPage({
    super.key,
    required this.title,
  });

  @override
  State<LendPage> createState() => _LendState();
}

class _LendState extends State<LendPage> {
  // --- Form and Image State ---
  final _formKey = GlobalKey<FormState>();
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  // --- Controllers and Category State ---
  final List<String> _category = const [
    'Academic and Study Materials',
    'Sport and Leisure Wears',
    'Tech and Electronics',
    'Clothing and Wears',
    'Dorm and Essential things',
    'Others',
  ];
  String? _selectedCategory;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();


  // Dates for Lending Period
  DateTime? _availableFrom;
  DateTime? _availableUntil;

  // location
  String? _selectedLocationInfo;
  LatLng? _selectedLatLng;
  GoogleMapController? _locationMapController;

  // 🎯 New: Liability Checkbox State
  bool _isLiabilityAccepted = false;

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

    _locationMapController?.dispose();

    super.dispose();
  }

  // --- Load saved location from shared_preferences (Unchanged) ---
  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('saved_pickup_location_lend'); // 🎯 Change: Use a unique key
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
      // 🎯 Change: Store under a 'lends' folder
      final ref = _storage.ref().child('lends').child(docId).child(fileName);

      final uploadTask = ref.putData(await file.readAsBytes());
      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _persistLocationString(String value) async {
    final prefs = await SharedPreferences.getInstance();
    // 🎯 Change: Use a unique key
    await prefs.setString('saved_pickup_location_lend', value);
  }

  // --- Form Submission Logic (Primary Action) ---
  // Add this method after your _submitForm() method
  Future<void> _triggerNotifications(String docId, Map<String, dynamic> itemData, String notificationType) async {
    try {
      await _firestore.collection('notification_requests').add({
        'donorId': FirebaseAuth.instance.currentUser!.uid,
        'donationId': docId,
        'donationData': itemData,
        'notificationType': notificationType, // ✅ 'donation' or 'lend'
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Notification request created for $notificationType');
    } catch (e) {
      debugPrint('❌ Failed to trigger notifications: $e');
    }
  }

// Then update your _submitForm() method - add this at the end, before clearing the form:
  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must be signed in to post an item for lending.'),
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
      // 1. Get lender info
      String? lenderName = user.displayName;
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          lenderName = userDoc.data()?['displayName'] as String? ?? user.displayName;
        }
      } catch (e) {
        debugPrint('Error fetching lender name: $e');
      }

      // 2. Prepare Firestore document ID
      final String docId = _firestore.collection('lends').doc().id;

      // 3. Upload images
      final imageUrls = await _uploadImagesToFirebase(docId);

      // 4. Create Lend Model Instance
      final newLend = LendModel(
        id: docId,
        category: _selectedCategory ?? 'Unspecified',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        imageUrls: imageUrls,
        availableFrom: _availableFrom,
        availableUntil: _availableUntil,
        locationAddress: _selectedLocationInfo,
        latitude: _selectedLatLng?.latitude,
        longitude: _selectedLatLng?.longitude,
        donorId: user.uid,
        donorName: lenderName ?? 'Unknown',
        donorPhoto: user.photoURL ?? '',
      );

      // 5. Convert model to Firestore-ready map
      final Map<String, dynamic> lendData = newLend.toJson();

      // 6. Add donor metadata
      lendData['lenderId'] = user.uid;
      lendData['lenderEmail'] = user.email;
      lendData['lenderName'] = lenderName;

      // 7. Save to Firestore
      await _firestore.collection('lends').doc(docId).set(lendData);

      // 8. Persist location locally
      final locString = _selectedLatLng != null
          ? '${_selectedLatLng!.latitude},${_selectedLatLng!.longitude}||${_selectedLocationInfo ?? ''}'
          : (_selectedLocationInfo ?? '');
      await _persistLocationString(locString);

      // 9. 🎯 Trigger notifications for lend requests
      // Both students and non-students will receive notifications for lends
      final notificationService = NotificationService();
      await notificationService.triggerNearbyNotification(
        donationId: docId,
        donationData: lendData,
        notificationType: 'lend', // ✅ Specify this is a lend request
      );

      if (mounted) {
        Navigator.of(context).pop(); // close progress
      }

      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Item posted for lending! Nearby users are being notified.',
              style: TextStyle(fontFamily: 'Quicksand'),
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Clear form
      setState(() {
        _images.clear();
        _selectedCategory = null;
        _titleController.clear();
        _descController.clear();
        _isLiabilityAccepted = false;
      });
    } catch (e, st) {
      if (mounted) {
        Navigator.of(context).pop(); // close progress
      }

      setState(() => _isSubmitting = false);

      debugPrint('Upload/save error: $e\n$st');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post item: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // --- Color and Style Constants (Unchanged, using Teal scheme) ---
  static final Color _primaryColor = Colors.teal.shade700;
  static final Color _accentColor = Colors.teal.shade300;
  static final Color _headerColor = Colors.teal.shade800;
  static final Color _locationBgColor = Colors.amber.shade50;
  static final Color _locationConfirmedBgColor = Colors.teal.shade50;

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Mont',
    fontWeight: FontWeight.w200,
    fontSize: 13,
    color: Colors.teal,
  );
  static const TextStyle _inputStyle = TextStyle(
    fontFamily: 'Mont',
    fontWeight: FontWeight.w200,
    fontSize: 12,
  );
  static const TextStyle _hintStyle = TextStyle(
    fontFamily: 'Mont',
    fontWeight: FontWeight.w200,
    color: Colors.grey,
  );

  // --- Fanciful Input Decoration (Unchanged) ---
  InputDecoration _fancifulDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: _hintStyle,
      prefixIcon: Icon(icon, color: _accentColor),
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontFamily: 'Mont', fontWeight: FontWeight.bold),
        ),
        backgroundColor: _headerColor,
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
                _buildSectionHeader("Item Name / Title"),
                TextFormField(
                  controller: _titleController,
                  style: _inputStyle,
                  decoration: _fancifulDecoration("Enter the specific item name", Icons.title),
                  validator: (val) => val!.isEmpty ? "Please enter a detailed item name" : null,
                ),
                const SizedBox(height: 16),

                // --- Description Field ---
                _buildSectionHeader("Description"),
                TextFormField(
                  controller: _descController,
                  style: _inputStyle,
                  maxLines: 4,
                  decoration: _fancifulDecoration("Description of the item", Icons.description)
                      .copyWith(alignLabelWithHint: true),
                  validator: (val) => val!.isEmpty ? "Please enter a description" : null,
                ),
                const SizedBox(height: 24),

                const SizedBox(height: 24),

                // --- Image Uploader (Existing Code) ---
                _buildSectionHeader("Add Photos (up to 5)"),
                _buildImageUploader(),
                const SizedBox(height: 24),

                // --- Time Fields (Lending Period) ---
                _buildSectionHeader("When I need it by"),
                Row(
                  children: [
                    Expanded(child: _buildDateTimePicker(
                      label: "Available From",
                      date: _availableFrom,
                      onTap: () => _selectDateTime(context, isFromDate: true),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDateTimePicker(
                      label: "Available Until",
                      date: _availableUntil,
                      onTap: () => _selectDateTime(context, isFromDate: false),
                    )),
                  ],
                ),

                const SizedBox(height: 24),

                // --- Location Section (Unchanged logic) ---
                _buildSectionHeader("Confirm Your Location"),
                _buildLocationSelector(context),
                const SizedBox(height: 24),

                // --- Liability Checkbox ---
                const SizedBox(height: 32),

                // --- Lend Now Button ---
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
                    _isSubmitting ? 'Posting...' : 'Lend Now',
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

  // --- Helper for Section Headers (Unchanged) ---
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

  // --- Helper for Date/Time Picker Fields (Unchanged) ---
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

  // --- Helper for Location Selector Button / Map Preview (Unchanged) ---
  Widget _buildLocationSelector(BuildContext context) {
    // [Implementation identical to Donate page]
    if (_selectedLatLng != null) {
      return Container(
        width: double.infinity,
        height: 180,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _locationConfirmedBgColor,
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
                      markerId: const MarkerId('lend_location'),
                      position: _selectedLatLng!,
                    )
                  },
                  onMapCreated: (controller) {
                    _locationMapController = controller;
                  },
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
                    style: _inputStyle.copyWith(color: Colors.teal.shade700, fontWeight: FontWeight.bold),
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
                  icon: const Icon(Icons.edit_location, color: Colors.teal),
                  label: const Text("Change", style: TextStyle(color: Colors.teal, fontFamily: 'Quicksand')),
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

  // --- Parse / Handle result returned from MapSelectionPage (Unchanged) ---
  void _handleMapResult(String? result) {
    if (result == null) return;

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

  // --- Function to handle Date & Time picking (Unchanged) ---
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

  // --- Image Picker Logic (Functions - Unchanged) ---
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

  // --- Image Uploader UI (Widget - Unchanged) ---
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
        //fit: StackBoxFit.expand,
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

// 🎯 Placeholder for LendModel (You need to adjust this path and content)
// Assuming it's similar to DonateModel but without 'price' and 'kg' focus.
