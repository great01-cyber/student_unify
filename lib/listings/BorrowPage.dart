import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/MapSelectionPage.dart';
// 🎯 YOU MUST CREATE BorrowRequestModel.dart
// import '../Models/BorrowRequestModel.dart';


class BorrowRequestPage extends StatefulWidget {
  final String title;

  const BorrowRequestPage({
    super.key,
    required this.title,
  });

  @override
  State<BorrowRequestPage> createState() => _BorrowRequestPageState();
}

class _BorrowRequestPageState extends State<BorrowRequestPage> {
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
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _instructionsController = TextEditingController();

  DateTime? _neededBy;
  DateTime? _returnDate;

  // location
  String? _selectedLocationInfo;
  LatLng? _selectedLatLng;
  GoogleMapController? _locationMapController;

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collectionName = 'borrow_requests';

  bool _isSubmitting = false;

  // --- Color and Style Constants (Blue Scheme) ---
  static final Color _primaryColor = Colors.blue.shade700;
  static final Color _accentColor = Colors.blue.shade300;
  static final Color _headerColor = Colors.blue.shade800;
  static final Color _locationBgColor = Colors.blue.shade50;
  static final Color _locationConfirmedBgColor = Colors.blue.shade50;

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Colors.blue,
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
    _titleController.dispose();
    _descController.dispose();
    _instructionsController.dispose();
    _locationMapController?.dispose();
    super.dispose();
  }

  // ------------------- LOCATION AND PERSISTENCE -------------------

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

      if (_selectedLatLng != null && _locationMapController != null) {
        _locationMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLatLng!, 15.0),
        );
      }
    } catch (e) {
      debugPrint('Failed to load saved location: $e');
    }
  }

  Future<List<String>> _uploadImagesToFirebase(String docId) async {
    final List<String> urls = [];
    for (var i = 0; i < _images.length; i++) {
      final XFile file = _images[i];
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + file.name;
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
    await prefs.setString('saved_pickup_location', value);
  }

  // --- Parse / Handle result returned from MapSelectionPage ---
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

  // ------------------- DATE PICKER LOGIC -------------------

  Future<void> _selectDateOnly(BuildContext context, {required bool isNeededBy}) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: isNeededBy ? 0 : 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        if (isNeededBy) {
          _neededBy = date;
        } else {
          _returnDate = date;
        }
      });
    }
  }

  // ------------------- IMAGE PICKER LOGIC -------------------

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

  // ------------------- FORM SUBMISSION -------------------

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('You must be signed in to post a borrow request.'), backgroundColor: Colors.red.shade700),
      );
      return;
    }

    if (_selectedLocationInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please confirm your location.', style: TextStyle(fontFamily: 'Quicksand')), backgroundColor: Colors.red.shade700),
      );
      return;
    }

    if (_neededBy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please set the date you need the item by.'), backgroundColor: Colors.red.shade700),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    showDialog(context: context, barrierDismissible: false, builder: (_) => WillPopScope(onWillPop: () async => false, child: const Center(child: CircularProgressIndicator())));

    try {
      String? borrowerName = user.displayName;
      // Get user data
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          borrowerName = userDoc.data()?['displayName'] as String? ?? user.displayName;
        }
      } catch (e) {}

      final String docId = _firestore.collection(_collectionName).doc().id;
      final imageUrls = await _uploadImagesToFirebase(docId);

      // 🎯 NOTE: Since the actual BorrowRequestModel is not provided,
      // we create a map directly for submission. If the model exists,
      // replace this with newRequest.toJson()
      final Map<String, dynamic> requestData = {
        'id': docId,
        'category': _selectedCategory ?? 'Unspecified',
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'imageUrls': imageUrls,
        'neededBy': _neededBy?.toIso8601String(),
        'expectedReturnDate': _returnDate?.toIso8601String(),
        'borrowerNeeds': _instructionsController.text.trim(),
        'locationAddress': _selectedLocationInfo,
        'latitude': _selectedLatLng?.latitude,
        'longitude': _selectedLatLng?.longitude,
        'borrowerId': user.uid,
        'borrowerEmail': user.email,
        'borrowerName': borrowerName,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_collectionName).doc(docId).set(requestData);

      final locString = _selectedLatLng != null
          ? '${_selectedLatLng!.latitude},${_selectedLatLng!.longitude}||${_selectedLocationInfo ?? ''}'
          : (_selectedLocationInfo ?? '');
      await _persistLocationString(locString);

      Navigator.of(context).pop();
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Borrow request posted!'), backgroundColor: Colors.blue.shade700));

      setState(() {
        _images.clear();
        _selectedCategory = null;
        _titleController.clear();
        _descController.clear();
        _instructionsController.clear();
        _neededBy = null;
        _returnDate = null;
      });
    } catch (e, st) {
      Navigator.of(context).pop();
      setState(() => _isSubmitting = false);
      debugPrint('Upload/save error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post request: $e'), backgroundColor: Colors.red.shade700));
    }
  }


  // ------------------- UI WIDGETS AND HELPERS -------------------

  InputDecoration _fancifulDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: _hintStyle,
      prefixIcon: Icon(icon, color: _accentColor),
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade200, width: 1.5),
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

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    String text;
    // For date-only fields like NeededBy/ReturnDate, use date format
    text = date == null ? "Not Set" : DateFormat('MMM d, yyyy').format(date);

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

  Widget _buildImageUploader() {
    final Color _shadowColor = Colors.blue.shade50;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade200, width: 2),
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
            return AddImageButton(onPressed: _showImagePickerSheet, primaryColor: _primaryColor, accentColor: Colors.blue.shade200);
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

  Widget _buildLocationSelector(BuildContext context) {

    if (_selectedLatLng != null) {
      return Container(
        width: double.infinity,
        height: 180,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _locationConfirmedBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.shade200,
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
                  markers: {Marker(markerId: const MarkerId('borrow_location'), position: _selectedLatLng!)},
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
            color: Colors.blue.shade200,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.location_on, color: _primaryColor, size: 30),
            const SizedBox(height: 8),
            Text(
              _selectedLocationInfo ?? "Click to set your pickup location",
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
                _buildSectionHeader("Item Category"),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  style: _inputStyle.copyWith(color: Colors.black),
                  decoration: _fancifulDecoration("Select a category", Icons.category),
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
                const SizedBox(height: 16),

                // --- Title Field (Item Requested) ---
                _buildSectionHeader("Item Name"),
                TextFormField(
                  controller: _titleController,
                  style: _inputStyle,
                  decoration: _fancifulDecoration("Enter the specific item you need", Icons.title),
                  validator: (val) => val!.isEmpty ? "Please enter a detailed item name" : null,
                ),
                const SizedBox(height: 16),

                // --- Description Field ---
                TextFormField(
                  controller: _descController,
                  style: _inputStyle,
                  maxLines: 4,
                  decoration: _fancifulDecoration("Description of need/item details", Icons.description).copyWith(alignLabelWithHint: true),
                  validator: (val) => val!.isEmpty ? "Please enter a description" : null,
                ),
                const SizedBox(height: 24),

                // --- Date Needed By ---
                _buildSectionHeader("Item Needed By"),
                _buildDateTimePicker(
                  label: "Needed By Date",
                  date: _neededBy,
                  onTap: () => _selectDateOnly(context, isNeededBy: true),
                ),
                const SizedBox(height: 16),

                // --- Expected Return Date ---
                _buildSectionHeader("Expected Return Date"),
                _buildDateTimePicker(
                  label: "Expected Return Date",
                  date: _returnDate,
                  onTap: () => _selectDateOnly(context, isNeededBy: false),
                ),
                const SizedBox(height: 24),

                // --- Image Uploader (Optional for reference) ---
                _buildSectionHeader("Reference Photos (Optional)"),
                _buildImageUploader(),
                const SizedBox(height: 24),

                // --- Borrower Needs / Instructions ---
                _buildSectionHeader("Borrower Needs"),
                TextFormField(
                  controller: _instructionsController,
                  style: _inputStyle,
                  maxLines: 3,
                  decoration: _fancifulDecoration("Specific requirements or context", Icons.pages).copyWith(alignLabelWithHint: true),
                ),
                const SizedBox(height: 24),

                // --- Location Section (Where the borrower can meet/be found) ---
                _buildSectionHeader("Your Location (for pickup/drop-off)"),
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
                      : const Icon(Icons.send, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Post Borrow Request',
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

// ------------------- Image Uploader Helper Widgets (Blue Theme) -------------------

class AddImageButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color primaryColor;
  final Color accentColor;
  const AddImageButton({super.key, required this.onPressed, required this.primaryColor, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accentColor,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add_a_photo_outlined,
            color: primaryColor,
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
  final Color primaryColor;
  const ImageTile({super.key, required this.file, required this.onRemove, required this.primaryColor});

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
                  color: primaryColor,
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