import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/MapSelectionPage.dart';
// import '../Models/SaleModel.dart'; // 🎯 You must create this model

class SellPage extends StatefulWidget {
  final String title;

  const SellPage({
    super.key,
    required this.title,
  });

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
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
  final _priceController = TextEditingController(); // 🎯 NEW: Price field
  final _shipmentController = TextEditingController(); // 🎯 NEW: Shipping/Pickup details

  final List<String> _paymentMethods = const ['Cash', 'PayPal', 'Venmo', 'Card/Online Transfer'];
  String? _selectedPaymentMethod; // 🎯 NEW: Payment method

  // location
  String? _selectedLocationInfo;
  LatLng? _selectedLatLng;
  GoogleMapController? _locationMapController;

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collectionName = 'sales'; // 🎯 NEW COLLECTION

  bool _isSubmitting = false;

  // --- Color and Style Constants (Red/Maroon Scheme) ---
  static final Color _primaryColor = Colors.red.shade700; // 🎯 CHANGE
  static final Color _accentColor = Colors.red.shade400;  // 🎯 CHANGE
  static final Color _headerColor = Colors.red.shade800;  // 🎯 CHANGE
  static final Color _locationBgColor = Colors.red.shade50; // 🎯 CHANGE
  static final Color _locationConfirmedBgColor = Colors.red.shade50; // 🎯 CHANGE

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Colors.red, // 🎯 CHANGE
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
    _priceController.dispose();
    _shipmentController.dispose();
    _locationMapController?.dispose();
    super.dispose();
  }

  // ------------------- LOCATION AND PERSISTENCE -------------------

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('saved_sale_location');
      if (saved == null) return;
      // ... (Rest of parsing logic for newLatLng and info, same as before)
    } catch (e) {
      debugPrint('Failed to load saved location: $e');
    }
  }

  Future<List<String>> _uploadImagesToFirebase(String docId) async {
    final List<String> urls = [];
    for (var i = 0; i < _images.length; i++) {
      final XFile file = _images[i];
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + file.name;
      // 🎯 CHANGE: Storage path uses 'sales'
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
    await prefs.setString('saved_sale_location', value);
  }

  // --- Parse / Handle result returned from MapSelectionPage ---
  void _handleMapResult(String? result) {
    if (result == null) return;
    // ... (Parsing logic same as Borrow/Lend/Exchange)
  }

  // ------------------- IMAGE PICKER LOGIC -------------------

  void _showImagePickerSheet() {
    // ... (Implementation same as before)
  }

  Future<void> _pickImage(ImageSource source) async {
    // ... (Implementation same as before)
  }

  void _removeImage(int index) {
    setState(() { _images.removeAt(index); });
  }

  // ------------------- FORM SUBMISSION -------------------

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    // --- Specific Validation for Sale ---
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please select an accepted payment method.'), backgroundColor: Colors.red.shade700),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    showDialog(context: context, barrierDismissible: false, builder: (_) => WillPopScope(onWillPop: () async => false, child: const Center(child: CircularProgressIndicator())));

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String? sellerName = user.displayName;
      // ... (Get user data)

      final String docId = _firestore.collection(_collectionName).doc().id;
      final imageUrls = await _uploadImagesToFirebase(docId);

      // Attempt to parse price to a double for better searching/sorting
      final double? priceValue = double.tryParse(_priceController.text.trim());
      if (priceValue == null) {
        throw Exception("Invalid price format.");
      }

      // 🎯 Sale Data Structure
      final Map<String, dynamic> saleData = {
        'id': docId,
        'category': _selectedCategory ?? 'Unspecified',
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'price': priceValue, // Stored as number for queryability
        'paymentMethod': _selectedPaymentMethod,
        'shipmentDetails': _shipmentController.text.trim(),
        'imageUrls': imageUrls,
        'locationAddress': _selectedLocationInfo,
        'latitude': _selectedLatLng?.latitude,
        'longitude': _selectedLatLng?.longitude,
        'sellerId': user.uid,
        'sellerEmail': user.email,
        'sellerName': sellerName,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_collectionName).doc(docId).set(saleData);

      // ... (Persist location, clear form, success snackbar)
      final locString = _selectedLatLng != null
          ? '${_selectedLatLng!.latitude},${_selectedLatLng!.longitude}||${_selectedLocationInfo ?? ''}'
          : (_selectedLocationInfo ?? '');
      await _persistLocationString(locString);

      Navigator.of(context).pop();
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Item posted for sale!'), backgroundColor: _primaryColor));

      _clearForm();

    } catch (e, st) {
      Navigator.of(context).pop();
      setState(() => _isSubmitting = false);
      debugPrint('Upload/save error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post item: ${e.toString()}'), backgroundColor: Colors.red.shade700));
    }
  }

  void _clearForm() {
    setState(() {
      _images.clear();
      _selectedCategory = null;
      _selectedPaymentMethod = null;
      _titleController.clear();
      _descController.clear();
      _priceController.clear();
      _shipmentController.clear();
    });
  }


  // ------------------- UI WIDGETS AND HELPERS (Red Theme) -------------------

  InputDecoration _fancifulDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: _hintStyle,
      prefixIcon: Icon(icon, color: _accentColor),
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade200, width: 1.5),
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

  // --- Image Uploader UI (Red Theme) ---
  Widget _buildImageUploader() {
    final Color _shadowColor = Colors.red.shade50;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade200, width: 2),
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
            return AddImageButton(onPressed: _showImagePickerSheet, primaryColor: _primaryColor, accentColor: Colors.red.shade200);
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

  // --- Helper for Location Selector Button / Map Preview (Red Theme) ---
  Widget _buildLocationSelector(BuildContext context) {

    if (_selectedLatLng != null) {
      // ... (Implementation same as before, but using red colors)
      return Container(
        width: double.infinity,
        height: 180,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _locationConfirmedBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.shade200,
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
                  markers: {Marker(markerId: const MarkerId('sale_location'), position: _selectedLatLng!)},
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
            color: Colors.red.shade200,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.location_on, color: _primaryColor, size: 30),
            const SizedBox(height: 8),
            Text(
              _selectedLocationInfo ?? "Click to set the pickup/shipping location",
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

                // --- Title Field (Item Name) ---
                _buildSectionHeader("Item Name"),
                TextFormField(
                  controller: _titleController,
                  style: _inputStyle,
                  decoration: _fancifulDecoration("Enter the specific item you are selling", Icons.title),
                  validator: (val) => val!.isEmpty ? "Please enter an item name" : null,
                ),
                const SizedBox(height: 16),

                // --- Description Field ---
                TextFormField(
                  controller: _descController,
                  style: _inputStyle,
                  maxLines: 4,
                  decoration: _fancifulDecoration("Condition, age, model number, etc.", Icons.description).copyWith(alignLabelWithHint: true),
                  validator: (val) => val!.isEmpty ? "Please describe the item" : null,
                ),
                const SizedBox(height: 24),

                // --- Price Field 🎯 NEW ---
                _buildSectionHeader("Asking Price (\$ USD)"),
                TextFormField(
                  controller: _priceController,
                  style: _inputStyle,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fancifulDecoration("Enter price (e.g., 49.99)", Icons.attach_money).copyWith(
                    prefixText: '\$ ',
                    prefixStyle: _inputStyle.copyWith(fontWeight: FontWeight.bold, color: _primaryColor),
                  ),
                  validator: (val) {
                    if (val!.isEmpty) return "Price is required";
                    if (double.tryParse(val) == null) return "Enter a valid number";
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // --- Payment Method Field 🎯 NEW ---
                _buildSectionHeader("Accepted Payment Method"),
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  style: _inputStyle.copyWith(color: Colors.black),
                  decoration: _fancifulDecoration("How you want to be paid", Icons.payment),
                  hint: Text("Select Payment Method", style: _hintStyle),
                  isExpanded: true,
                  items: _paymentMethods.map((String method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() { _selectedPaymentMethod = newValue; });
                  },
                  validator: (val) => val == null || val.isEmpty ? "Please select a payment method" : null,
                ),
                const SizedBox(height: 24),

                // --- Shipping/Pickup Details 🎯 NEW ---
                _buildSectionHeader("Shipping & Pickup Details"),
                TextFormField(
                  controller: _shipmentController,
                  style: _inputStyle,
                  maxLines: 3,
                  decoration: _fancifulDecoration("Local pickup only, or shipping cost/method", Icons.local_shipping).copyWith(alignLabelWithHint: true),
                  validator: (val) => val!.isEmpty ? "Please state pickup/shipping terms" : null,
                ),
                const SizedBox(height: 24),

                // --- Photos ---
                _buildSectionHeader("Photos of Item for Sale"),
                _buildImageUploader(),
                const SizedBox(height: 24),

                // --- Location ---
                _buildSectionHeader("Pickup Location"),
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
                      : const Icon(Icons.sell, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Post Item for Sale',
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

// ------------------- Image Uploader Helper Widgets (Red Theme) -------------------

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
          color: Colors.red.shade50,
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