import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Import your AppUser model
// import 'path_to_your_model/app_user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = false;

  // Controllers
  late TextEditingController _displayNameController;
  late TextEditingController _personalEmailController;
  late TextEditingController _universityController;
  late TextEditingController _graduationYearController;

  // User data
  Map<String, dynamic>? _userData;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _personalEmailController = TextEditingController();
    _universityController = TextEditingController();
    _graduationYearController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _personalEmailController.dispose();
    _universityController.dispose();
    _graduationYearController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data();
          _displayNameController.text = _userData?['displayName'] ?? '';
          _personalEmailController.text = _userData?['personalEmail'] ?? '';
          _universityController.text = _userData?['university'] ?? '';
          _graduationYearController.text =
              _userData?['graduationYear']?.toString() ?? '';
          _selectedRole = _userData?['role'] ?? 'nonStudent';
        });
      }
    } catch (e) {
      _showSnackBar('Error loading profile: $e', isError: true);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final updates = {
        'displayName': _displayNameController.text.trim(),
        'personalEmail': _personalEmailController.text.trim(),
        'university': _universityController.text.trim(),
        'graduationYear': int.tryParse(_graduationYearController.text.trim()),
        'role': _selectedRole,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates);

      await _loadUserData();

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      _showSnackBar('Profile updated successfully!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error updating profile: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Here you would upload to Firebase Storage and update photoUrl
      _showSnackBar('Image upload feature coming soon!');
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return 'Student';
      case 'pendingstudent':
        return 'Pending Student';
      case 'nonstudent':
        return 'Non-Student';
      default:
        return role;
    }
  }

  Color _getRoleColor(String? roleEffective) {
    switch (roleEffective?.toLowerCase()) {
      case 'student':
        return Colors.green;
      case 'pendingstudent':
        return Colors.orange;
      case 'nonstudent':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: Text('Please log in to view your profile')),
      );
    }

    if (_userData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(user),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileHeader(user),
                  SizedBox(height: 24),
                  _buildStatsCards(),
                  SizedBox(height: 24),
                  _buildProfileForm(),
                  SizedBox(height: 24),
                  _buildAccountSection(user),
                  SizedBox(height: 24),
                  _buildActionButtons(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(User user) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF1E3A8A),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            fontFamily: 'Mont',
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
          ),
        ),
      ),
      actions: [
        if (!_isEditing)
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => setState(() => _isEditing = true),
          ),
      ],
    );
  }

  Widget _buildProfileHeader(User user) {
    final photoUrl = _userData?['photoUrl'] as String?;
    final displayName = _userData?['displayName'] as String? ?? 'User';
    final email = _userData?['email'] as String? ?? user.email ?? '';
    final roleEffective = _userData?['roleEffective'] as String?;
    final emailVerified = _userData?['emailVerified'] as bool? ?? false;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF1E3A8A).withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(displayName),
                    ),
                  )
                      : _buildDefaultAvatar(displayName),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              fontFamily: 'Mont',
            ),
          ),
          SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusBadge(
                _getRoleDisplayName(roleEffective ?? 'nonStudent'),
                _getRoleColor(roleEffective),
              ),
              SizedBox(width: 8),
              if (emailVerified)
                _buildStatusBadge('Verified', Colors.green)
              else
                _buildStatusBadge('Unverified', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final createdAt = _userData?['createdAt'] as Timestamp?;
    final memberSince = createdAt != null
        ? _formatDate(createdAt.toDate())
        : 'Unknown';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.calendar_today,
            'Member Since',
            memberSince,
            Color(0xFF1E3A8A),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.school,
            'University',
            _userData?['university'] ?? 'Not set',
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                fontFamily: 'Mont',
              ),
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _displayNameController,
              label: 'Display Name',
              icon: Icons.person,
              enabled: _isEditing,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _personalEmailController,
              label: 'Personal Email',
              icon: Icons.email,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _universityController,
              label: 'University',
              icon: Icons.school,
              enabled: _isEditing,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _graduationYearController,
              label: 'Graduation Year',
              icon: Icons.calendar_month,
              enabled: _isEditing,
              keyboardType: TextInputType.number,
            ),
            if (_isEditing) ...[
              SizedBox(height: 16),
              Text(
                'Account Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              _buildRoleSelector(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF1E3A8A)),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      validator: (value) {
        if (label == 'Display Name' && (value == null || value.isEmpty)) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Color(0xFF1E3A8A)),
          items: [
            DropdownMenuItem(value: 'student', child: Text('Student')),
            DropdownMenuItem(value: 'nonStudent', child: Text('Non-Student')),
          ],
          onChanged: (value) {
            setState(() => _selectedRole = value);
          },
        ),
      ),
    );
  }

  Widget _buildAccountSection(User user) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              fontFamily: 'Mont',
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow(Icons.badge, 'User ID', user.uid),
          Divider(height: 24),
          _buildInfoRow(
            Icons.email,
            'Login Email',
            _userData?['email'] ?? user.email ?? 'Not available',
          ),
          Divider(height: 24),
          _buildInfoRow(
            Icons.verified_user,
            'Email Status',
            (_userData?['emailVerified'] ?? false) ? 'Verified' : 'Not Verified',
            valueColor: (_userData?['emailVerified'] ?? false)
                ? Colors.green
                : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Color(0xFF1E3A8A)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Color(0xFF1F2937),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                setState(() => _isEditing = false);
                _loadUserData();
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mont',
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                'Save Changes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mont',
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Navigate to login screen
            },
            icon: Icon(Icons.logout),
            label: Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}