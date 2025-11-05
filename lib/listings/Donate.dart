import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/MapSelectionPage.dart';

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
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _instructionsController = TextEditingController();

  // --- State for Date/Time & Location ---
  DateTime? _availableFrom;
  DateTime? _availableUntil;
  String? _selectedLocationInfo; // This will hold the result from the map page

  @override
  void dispose() {
    // Clean up controllers
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  // --- Text Style Helpers ---
  // Using Quicksand font as requested
  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Colors.deepPurple,
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
      prefixIcon: Icon(icon, color: Colors.purple.shade300),
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.purple.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2.0),
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
        backgroundColor: Colors.blueGrey,
      ),
      backgroundColor: Colors.grey[50],
      // Use SingleChildScrollView to prevent overflow
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          // Form widget for validation
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Fields stretch
              children: [
                // --- Title Field ---
                _buildSectionHeader("Item Details"),
                TextFormField(
                  controller: _titleController,
                  style: _inputStyle,
                  decoration: _fancifulDecoration("Title", Icons.title),
                  validator: (val) => val!.isEmpty ? "Please enter a title" : null,
                ),
                const SizedBox(height: 16),

                // --- Description Field ---
                TextFormField(
                  controller: _descController,
                  style: _inputStyle,
                  maxLines: 4,
                  decoration: _fancifulDecoration("Description", Icons.description)
                      .copyWith(alignLabelWithHint: true), // For multi-line
                  validator: (val) => val!.isEmpty ? "Please enter a description" : null,
                ),
                const SizedBox(height: 16),

                // --- Estimated Price Field ---
                TextFormField(
                  controller: _priceController,
                  style: _inputStyle,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: _fancifulDecoration("Estimated Price (£)", Icons.attach_money),
                  validator: (val) => val!.isEmpty ? "Please enter a price" : null,
                ),
                const SizedBox(height: 24),

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
                    backgroundColor: Colors.deepPurple,
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
      // Aligning to the right as requested
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

  // --- Helper for Location Selector Button ---
  Widget _buildLocationSelector(BuildContext context) {
    return InkWell(
      onTap: () async {
        // --- THIS IS WHERE WE NAVIGATE TO THE MAP ---
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (context) => const MapSelectionPage()),
        );

        // --- HERE WE RECEIVE THE RESULT ---
        if (result != null) {
          setState(() {
            _selectedLocationInfo = result;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black12,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.location_on, color: Colors.deepPurple, size: 30),
            const SizedBox(height: 8),
            Text(
              // Show the selected location or a prompt
              _selectedLocationInfo ?? "Click to set pickup location",
              style: _inputStyle.copyWith(color: Colors.deepPurple),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Function to handle Date & Time picking ---
  Future<void> _selectDateTime(BuildContext context, {required bool isFromDate}) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null) return; // User cancelled

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return; // User cancelled

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
    // Validate all fields
    if (_formKey.currentState!.validate()) {
      // Check if at least one image is added
      if (_images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one image.', style: TextStyle(fontFamily: 'Quicksand')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if location is set
      if (_selectedLocationInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please confirm your location.', style: TextStyle(fontFamily: 'Quicksand')),
            backgroundColor: Colors.red,
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
      print("Location: $_selectedLocationInfo");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation submitted! (Check console)', style: TextStyle(fontFamily: 'Quicksand')),
          backgroundColor: Colors.green,
        ),
      );

      // You could pop the page or clear the form here
      // Navigator.pop(context);
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
        border: Border.all(color: Colors.purple.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade50.withOpacity(0.5),
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
          crossAxisCount: 3, // Changed to 3 to fit more
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

// --- Image Uploader Helper Widgets (No Changes) ---
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
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.purple.shade200,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add_a_photo_outlined,
            color: Colors.purple.shade400,
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
                  color: Colors.deepPurple.shade300,
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