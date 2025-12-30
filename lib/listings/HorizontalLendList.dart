import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../Home/widgets/chatpage.dart';
import '../Models/DonateModel.dart';
import '../Models/LendPage.dart';

// Color palette - consistent with the app
const Color primaryPink = Color(0xFFFF6786);
const Color lightPink = Color(0xFFFFE5EC);
const Color accentPink = Color(0xFFFF9BAD);
const Color darkText = Color(0xFF2D3748);
const Color lightText = Color(0xFF718096);

// ==================== LEND REQUEST CARD ====================
class LendRequestCard extends StatelessWidget {
  final LendModel lendRequest;
  final VoidCallback onTap;

  const LendRequestCard({
    super.key,
    required this.lendRequest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = (lendRequest.imageUrls.isNotEmpty &&
        lendRequest.imageUrls.first.isNotEmpty)
        ? lendRequest.imageUrls.first
        : null;

    // ✅ CHECK IF CURRENT USER IS THE OWNER
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwnRequest = currentUserId == lendRequest.donorId;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 285,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primaryPink.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: imageUrl != null
                      ? Image.network(
                    imageUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImageFallback(),
                  )
                      : _buildImageFallback(),
                ),
                // Request badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryPink, accentPink],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryPink.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.handshake_rounded,
                            color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'NEED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Mont',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ✅ "YOUR POST" BADGE FOR OWN REQUESTS
                if (isOwnRequest)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'YOUR POST',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mont',
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: lightPink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getCategoryShortName(lendRequest.category),
                        style: TextStyle(
                          fontSize: 9,
                          color: primaryPink,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mont',
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      lendRequest.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                        fontFamily: 'Mont',
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      lendRequest.description,
                      style: TextStyle(
                        fontSize: 10,
                        color: lightText,
                        height: 1.2,
                        fontFamily: 'Mont',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Location
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: primaryPink,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              lendRequest.locationAddress ?? 'Not specified',
                              style: TextStyle(
                                fontSize: 9,
                                color: lightText,
                                fontFamily: 'Mont',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ ACTION BUTTON - DISABLED FOR OWN POSTS
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: isOwnRequest ? null : onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOwnRequest ? Colors.grey.shade300 : primaryPink,
                          foregroundColor: isOwnRequest ? Colors.grey.shade600 : Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: isOwnRequest ? 0 : 2,
                          shadowColor: primaryPink.withOpacity(0.3),
                        ),
                        child: Text(
                          isOwnRequest ? 'Your Request' : 'I Can Help',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Mont',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lightPink.withOpacity(0.5), lightPink.withOpacity(0.2)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.handshake_rounded,
          size: 50,
          color: primaryPink.withOpacity(0.5),
        ),
      ),
    );
  }

  String _getCategoryShortName(String category) {
    final Map<String, String> shortNames = {
      'Academic and Study Materials': 'Academic',
      'Sport and Leisure Wears': 'Sports',
      'Tech and Electronics': 'Tech',
      'Clothing and Wears': 'Clothing',
      'Dorm and Essential things': 'Dorm',
      'Others': 'Other',
    };
    return shortNames[category] ?? category;
  }
}

// ==================== HORIZONTAL LEND REQUESTS LIST ====================
class HorizontalLendRequestsList extends StatelessWidget {
  final String title;
  final String? filterCategory;

  const HorizontalLendRequestsList({
    super.key,
    this.title = 'Requested by Students',
    this.filterCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryPink, accentPink],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.handshake_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                      fontFamily: 'Mont',
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VerticalLendRequestsPage(
                        categoryTitle: filterCategory,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: primaryPink,
                ),
                label: Text(
                  'View All',
                  style: TextStyle(
                    color: primaryPink,
                    fontFamily: 'Mont',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal list
        SizedBox(
          height: 305,
          child: StreamBuilder<QuerySnapshot>(
            stream: _getLendRequestsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: lightText, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Error loading requests',
                        style: TextStyle(
                          color: lightText,
                          fontFamily: 'Mont',
                        ),
                      ),
                    ],
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return _buildEmptyState();
              }

              final requests = docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return LendModel.fromJson(data);
              }).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  return LendRequestCard(
                    lendRequest: requests[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LendRequestDetailPage(
                            lendRequest: requests[index],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _getLendRequestsStream() {
    Query query = FirebaseFirestore.instance
        .collection('lends')
        .orderBy('createdAt', descending: true)
        .limit(10);

    if (filterCategory != null) {
      query = query.where('category', isEqualTo: filterCategory);
    }

    return query.snapshots();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handshake_outlined,
            size: 60,
            color: lightText.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No borrow requests yet',
            style: TextStyle(
              fontSize: 15,
              color: lightText,
              fontFamily: 'Mont',
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== LEND REQUEST DETAIL PAGE ====================
class LendRequestDetailPage extends StatefulWidget {
  final LendModel lendRequest;

  const LendRequestDetailPage({
    super.key,
    required this.lendRequest,
  });

  @override
  State<LendRequestDetailPage> createState() => _LendRequestDetailPageState();
}

class _LendRequestDetailPageState extends State<LendRequestDetailPage> {
  int _currentImageIndex = 0;
  late List<String> _images;

  @override
  void initState() {
    super.initState();
    _images = widget.lendRequest.imageUrls.where((url) => url.isNotEmpty).toList();
    if (_images.isEmpty) {
      _images = [''];
    }
  }

  void _nextImage() {
    if (_currentImageIndex < _images.length - 1) {
      setState(() {
        _currentImageIndex++;
      });
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CHECK IF CURRENT USER IS THE OWNER
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwnRequest = currentUserId == widget.lendRequest.donorId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Request Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Mont',
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPink, accentPink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel with navigation
            _buildImageCarousel(),

            // ✅ SHOW "YOUR REQUEST" BANNER FOR OWN POSTS
            if (isOwnRequest)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'This is Your Request',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              fontFamily: 'Mont',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'You cannot message yourself about this item.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontFamily: 'Mont',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: lightPink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category_rounded,
                            size: 16, color: primaryPink),
                        const SizedBox(width: 6),
                        Text(
                          widget.lendRequest.category,
                          style: TextStyle(
                            color: primaryPink,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            fontFamily: 'Mont',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.lendRequest.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                      fontFamily: 'Mont',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  _buildSectionHeader('What They Need', Icons.description_rounded),
                  const SizedBox(height: 12),
                  Text(
                    widget.lendRequest.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: darkText,
                      fontFamily: 'Mont',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Time needed
                  if (widget.lendRequest.availableFrom != null ||
                      widget.lendRequest.availableUntil != null) ...[
                    _buildSectionHeader('When Needed', Icons.calendar_month_rounded),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: lightPink.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: lightPink, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          if (widget.lendRequest.availableFrom != null)
                            _buildTimeRow(
                              'From',
                              widget.lendRequest.availableFrom!,
                              Icons.start_rounded,
                            ),
                          if (widget.lendRequest.availableFrom != null &&
                              widget.lendRequest.availableUntil != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Divider(
                                color: primaryPink.withOpacity(0.3),
                                height: 1,
                              ),
                            ),
                          if (widget.lendRequest.availableUntil != null)
                            _buildTimeRow(
                              'Until',
                              widget.lendRequest.availableUntil!,
                              Icons.event_rounded,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Location
                  _buildSectionHeader('Preferred Pickup', Icons.location_on_rounded),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightPink.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: lightPink, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryPink, accentPink],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.lendRequest.locationAddress ?? 'Not specified',
                            style: const TextStyle(
                              fontSize: 14,
                              color: darkText,
                              fontFamily: 'Mont',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ✅ ACTION BUTTON - DISABLED FOR OWN POSTS
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isOwnRequest ? null : () => _showContactDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOwnRequest ? Colors.grey.shade300 : primaryPink,
                        foregroundColor: isOwnRequest ? Colors.grey.shade600 : Colors.white,
                        elevation: isOwnRequest ? 0 : 4,
                        shadowColor: primaryPink.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isOwnRequest ? Icons.block : Icons.handshake_rounded,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isOwnRequest ? 'Your Own Request' : 'I Can Lend This Item',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Mont',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryPink, accentPink],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: darkText,
            fontFamily: 'Mont',
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow(String label, DateTime date, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryPink, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: lightText,
                fontFamily: 'Mont',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(date),
              style: const TextStyle(
                fontSize: 14,
                color: darkText,
                fontFamily: 'Mont',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      children: [
        // Main Image
        _images[_currentImageIndex].isNotEmpty
            ? Image.network(
          _images[_currentImageIndex],
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
        )
            : _buildPlaceholderImage(),

        // Previous Button
        if (_images.length > 1 && _currentImageIndex > 0)
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: _previousImage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back_ios_rounded,
                      color: primaryPink, size: 20),
                ),
              ),
            ),
          ),

        // Next Button
        if (_images.length > 1 && _currentImageIndex < _images.length - 1)
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: _nextImage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      color: primaryPink, size: 20),
                ),
              ),
            ),
          ),

        // Image Counter
        if (_images.length > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1} / ${_images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Mont',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightPink.withOpacity(0.5), lightPink.withOpacity(0.2)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.handshake_rounded,
          size: 80,
          color: primaryPink.withOpacity(0.5),
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightPink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.message_rounded, color: primaryPink, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Contact Requester',
              style: TextStyle(
                fontFamily: 'Mont',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Would you like to message the student about lending this item?',
          style: TextStyle(
            fontFamily: 'Mont',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: lightText,
                fontFamily: 'Mont',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    receiverId: widget.lendRequest.donorId,
                    receiverName: widget.lendRequest.donorName,
                    receiverPhoto: widget.lendRequest.donorPhoto,
                    lendModel: widget.lendRequest,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Send Message',
              style: TextStyle(
                fontFamily: 'Mont',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== VERTICAL LIST PAGE ====================
class VerticalLendRequestsPage extends StatelessWidget {
  final String? categoryTitle;

  const VerticalLendRequestsPage({
    super.key,
    this.categoryTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          categoryTitle ?? 'All Borrow Requests',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Mont',
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPink, accentPink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getLendRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: lightText),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: lightText, fontFamily: 'Mont'),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.handshake_outlined,
                    size: 80,
                    color: lightText.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No borrow requests found',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Mont',
                      color: darkText,
                    ),
                  ),
                ],
              ),
            );
          }

          final requests = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return LendModel.fromJson(data);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildVerticalCard(context, requests[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildVerticalCard(BuildContext context, LendModel request) {
    // ✅ CHECK IF CURRENT USER IS THE OWNER
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwnRequest = currentUserId == request.donorId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwnRequest ? Colors.orange.withOpacity(0.5) : lightPink.withOpacity(0.5),
          width: isOwnRequest ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LendRequestDetailPage(lendRequest: request),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: request.imageUrls.isNotEmpty
                        ? Image.network(
                      request.imageUrls.first,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            lightPink.withOpacity(0.3),
                            lightPink.withOpacity(0.1)
                          ],
                        ),
                      ),
                      child: Icon(Icons.handshake_rounded,
                          size: 35, color: primaryPink.withOpacity(0.5)),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                            fontFamily: 'Mont',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: lightPink,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            request.category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: primaryPink,
                              fontFamily: 'Mont',
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        Text(
                          request.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: lightText,
                            fontFamily: 'Mont',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: primaryPink,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                request.locationAddress ?? 'Not specified',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Mont',
                                  color: lightText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ✅ "YOUR POST" BADGE
            if (isOwnRequest)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'YOUR POST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mont',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getLendRequestsStream() {
    Query query = FirebaseFirestore.instance
        .collection('lends')
        .orderBy('createdAt', descending: true);

    if (categoryTitle != null) {
      query = query.where('category', isEqualTo: categoryTitle);
    }

    return query.snapshots();
  }
}