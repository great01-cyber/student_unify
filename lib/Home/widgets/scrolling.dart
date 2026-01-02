import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../Models/DonateModel.dart';
import 'chatpage.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ------------------- COLOR CONSTANTS -------------------
const Color primaryPink = Color(0xFFFF6786); // ✨ Beautiful coral pink
const Color lightPink = Color(0xFFFFE5EC); // ✨ Soft pink background
const Color accentPink = Color(0xFFFF8FA3); // ✨ Light coral accent
const Color darkText = Color(0xFF2D3748);
const Color lightText = Color(0xFF718096);
const Color claimedGreen = Color(0xFF10B981); // ✅ Claimed color
const Color claimedGreenLight = Color(0xFFD1FAE5); // ✅ Light green

// ------------------- ENUM AND HELPER WIDGETS -------------------

// 1. Define Listing Type Enum
enum ListingType { donate, Request}

// 2. Fallback Image Widget (Helper)
Widget _imageFallback({bool isClaimed = false}) {
  return Container(
    height: 150,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isClaimed
            ? [claimedGreenLight.withOpacity(0.5), claimedGreenLight.withOpacity(0.2)]
            : [lightPink.withOpacity(0.8), lightPink.withOpacity(0.3)],
      ),
    ),
    child: Center(
      child: Icon(
        isClaimed ? Icons.check_circle_rounded : Icons.inventory_2_outlined,
        color: isClaimed
            ? claimedGreen.withOpacity(0.5)
            : primaryPink.withOpacity(0.5),
        size: 40,
      ),
    ),
  );
}

// 3. Modified Item Card Widget
Widget _buildItemCard(
    BuildContext context,
    dynamic item,
    ListingType type,
    ) {
  // ✅ Check if item is claimed
  final bool isClaimed = (item.donorConfirmed ?? false) && (item.receiverConfirmed ?? false);

  final imageUrl = (item.imageUrls.isNotEmpty && item.imageUrls.first.isNotEmpty)
      ? item.imageUrls.first
      : null;

  // Extract price safely
  double? price;
  try {
    price = item.price as double?;
  } catch (e) {
    price = null;
  }

  // Determine action text and color based on listing type
  final String actionText;
  final Color actionColor;

  if (isClaimed) {
    actionText = 'CLAIMED';
    actionColor = claimedGreen;
  } else {
    switch (type) {
      case ListingType.Request:
        actionText = 'Request an Item';
        actionColor = Colors.green.shade700;
        break;
      case ListingType.donate:
        actionText = 'FREE';
        actionColor = Colors.teal.shade700;
        break;
    }
  }

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItemDetailPage(item: item as Donation),
        ),
      );
    },
    child: Container(
      width: 160,
      height: 303,
      margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        // ✅ Green border if claimed
        border: isClaimed ? Border.all(color: claimedGreen, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isClaimed
                ? claimedGreen.withOpacity(0.15)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ✅ Semi-transparent overlay if claimed
          if (isClaimed)
            Container(
              decoration: BoxDecoration(
                color: claimedGreenLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
              ),
            ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(imageUrl, isClaimed: isClaimed),
              const SizedBox(height: 6),
              _buildDetailsSection(item, actionText, actionColor, isClaimed: isClaimed),
            ],
          ),
        ],
      ),
    ),
  );
}

// Image section with loading and error handling
Widget _buildImageSection(String? imageUrl, {bool isClaimed = false}) {
  return Stack(
    children: [
      ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        child: imageUrl != null
            ? Image.network(
          imageUrl,
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
          // ✅ Add gray filter if claimed
          color: isClaimed ? Colors.white.withOpacity(0.6) : null,
          colorBlendMode: isClaimed ? BlendMode.lighten : null,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 100,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) =>
              _imageFallback(isClaimed: isClaimed),
        )
            : _imageFallback(isClaimed: isClaimed),
      ),

      // ✅ CLAIMED BADGE overlay
      if (isClaimed)
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [claimedGreen, claimedGreen.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: claimedGreen.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  'CLAIMED',
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
    ],
  );
}

// Details section with item info and donator
Widget _buildDetailsSection(
    dynamic item,
    String actionText,
    Color actionColor, {
      bool isClaimed = false,
    }) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildItemInfo(item, isClaimed: isClaimed),
        const SizedBox(height: 4),
        _buildLocationInfo(item, isClaimed: isClaimed),
        const SizedBox(height: 4),
        _buildActionLabel(actionText, actionColor),
        const SizedBox(height: 6),
        _buildDonatorInfo(item.donorId),
      ],
    ),
  );
}

// Item title and category
Widget _buildItemInfo(dynamic item, {bool isClaimed = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        item.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isClaimed ? darkText.withOpacity(0.7) : darkText,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 2),
      Text(
        item.category,
        style: TextStyle(
          fontSize: 12,
          color: isClaimed ? lightText.withOpacity(0.7) : Colors.grey[600],
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

// Location info with icon
Widget _buildLocationInfo(dynamic item, {bool isClaimed = false}) {
  return Row(
    children: [
      Icon(
        Icons.location_on,
        size: 14,
        color: isClaimed ? claimedGreen : primaryPink,
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          item.locationAddress ?? 'Unknown',
          style: TextStyle(
            fontSize: 11,
            color: isClaimed ? lightText.withOpacity(0.7) : Colors.blueGrey,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

// Action label (price/status)
Widget _buildActionLabel(String actionText, Color actionColor) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: actionColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      actionText,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: actionColor,
      ),
    ),
  );
}

// Donator information with avatar
Widget _buildDonatorInfo(String donorId) {
  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    future: FirebaseFirestore.instance.collection('users').doc(donorId).get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox(
          height: 20,
          child: LinearProgressIndicator(minHeight: 2),
        );
      }

      if (snapshot.hasError ||
          !snapshot.hasData ||
          snapshot.data!.data() == null) {
        return const SizedBox();
      }

      final userData = snapshot.data!.data()!;
      final donatorName = userData['displayName'] ?? 'Unknown';
      final donatorUniversity = userData['university'] ?? 'Unknown';
      final photoUrl = userData['photoUrl'] ?? '';

      return Row(
        children: [
          _buildDonatorAvatar(photoUrl),
          const SizedBox(width: 6),
          Expanded(
            child: _buildDonatorDetails(donatorName, donatorUniversity),
          ),
        ],
      );
    },
  );
}

// Donator avatar
Widget _buildDonatorAvatar(String photoUrl) {
  return CircleAvatar(
    radius: 10,
    backgroundColor: Colors.grey[300],
    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
    child: photoUrl.isEmpty
        ? const Icon(Icons.person, size: 5, color: Colors.white)
        : null,
  );
}

// Donator name and university
Widget _buildDonatorDetails(String name, String university) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        name,
        style: const TextStyle(
          fontSize: 6,
          fontWeight: FontWeight.w100,
          color: Colors.black,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        university,
        style: const TextStyle(
          fontSize: 6,
          color: Colors.blueGrey,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

// ------------------- HorizontalItemList -------------------
class HorizontalItemList extends StatelessWidget {
  final String categoryTitle;
  const HorizontalItemList({super.key, required this.categoryTitle});

  static final CollectionReference<Map<String, dynamic>> _donationCollection =
  FirebaseFirestore.instance.collection('donations');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'Mont',
                  color: primaryPink,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VerticalListPage(categoryTitle: categoryTitle),
                    ),
                  );
                },
                child: Row(
                  children: const [
                    Text(
                      "All",
                      style: TextStyle(
                        color: primaryPink,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'Mont',
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_right,
                        color: primaryPink, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Horizontal list from Firestore
        SizedBox(
          height: 240,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _donationCollection
                .where('category', isEqualTo: categoryTitle)
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error loading items: ${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                    child: Text('No items in this category yet.'));
              }

              final items = docs.map((doc) {
                final data = Map<String, dynamic>.from(doc.data());
                data['id'] = data['id'] ?? doc.id;
                return Donation.fromJson(data);
              }).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildItemCard(context, items[index], ListingType.donate),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ------------------- ItemDetailPage with Image Carousel -------------------
class ItemDetailPage extends StatefulWidget {
  final Donation item;

  const ItemDetailPage({super.key, required this.item});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ✅ Check if item is claimed
  bool get isClaimed {
    return (widget.item.donorConfirmed ?? false) && (widget.item.receiverConfirmed ?? false);
  }

  Future<void> _openExternalMaps(double lat, double lng,
      {String? label}) async {
    final encodedLabel = Uri.encodeComponent(label ?? 'Pickup location');

    // iOS -> Apple Maps, Android -> Google Maps
    final Uri uri = Platform.isIOS
        ? Uri.parse('http://maps.apple.com/?q=$encodedLabel&ll=$lat,$lng')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback (rare)
      final fallback = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  void _nextImage() {
    if (_currentImageIndex < widget.item.imageUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> validImageUrls = widget.item.imageUrls
        .where((url) => url.isNotEmpty)
        .toList();
    final bool hasImages = validImageUrls.isNotEmpty;
    final bool hasMultipleImages = validImageUrls.length > 1;
    final bool hasLocation = widget.item.latitude != null && widget.item.longitude != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title),
        backgroundColor: isClaimed ? claimedGreen : primaryPink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎨 Image Carousel Section
            Stack(
              children: [
                // PageView for images
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: hasImages
                      ? PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: validImageUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        validImageUrls[index],
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                        color: isClaimed ? Colors.white.withOpacity(0.4) : null,
                        colorBlendMode: isClaimed ? BlendMode.lighten : null,
                        errorBuilder: (_, __, ___) => Container(
                          height: 300,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.photo_library, size: 50),
                          ),
                        ),
                      );
                    },
                  )
                      : Container(
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isClaimed
                            ? [claimedGreenLight.withOpacity(0.5), claimedGreenLight.withOpacity(0.2)]
                            : [lightPink.withOpacity(0.8), lightPink.withOpacity(0.3)],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isClaimed ? Icons.check_circle_rounded : Icons.photo_library,
                        size: 80,
                        color: isClaimed
                            ? claimedGreen.withOpacity(0.5)
                            : primaryPink.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),

                // ✅ Claimed badge overlay on image
                if (isClaimed)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [claimedGreen, claimedGreen.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: claimedGreen.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'CLAIMED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Mont',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 🎯 Previous Button (only if there are multiple images and not on first image)
                if (hasMultipleImages && _currentImageIndex > 0)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryPink.withOpacity(0.9), primaryPink.withOpacity(0.7)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryPink.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: _previousImage,
                        ),
                      ),
                    ),
                  ),

                // 🎯 Next Button (only if there are multiple images and not on last image)
                if (hasMultipleImages && _currentImageIndex < validImageUrls.length - 1)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryPink.withOpacity(0.9), primaryPink.withOpacity(0.7)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryPink.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                          onPressed: _nextImage,
                        ),
                      ),
                    ),
                  ),

                // 🎯 Image Counter (e.g., "1/5")
                if (hasMultipleImages)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryPink.withOpacity(0.95), accentPink.withOpacity(0.95)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryPink.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${validImageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Mont',
                        ),
                      ),
                    ),
                  ),

                // 🎯 Dot Indicators (alternative visual for pagination)
                if (hasMultipleImages)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        validImageUrls.length,
                            (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _currentImageIndex ? 10 : 6,
                          height: index == _currentImageIndex ? 10 : 6,
                          decoration: BoxDecoration(
                            gradient: index == _currentImageIndex
                                ? LinearGradient(
                              colors: [primaryPink, accentPink],
                            )
                                : null,
                            color: index != _currentImageIndex
                                ? Colors.white.withOpacity(0.5)
                                : null,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: index == _currentImageIndex
                                    ? primaryPink.withOpacity(0.4)
                                    : Colors.black.withOpacity(0.2),
                                blurRadius: index == _currentImageIndex ? 6 : 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ✅ CLAIMED BANNER (if claimed)
            if (isClaimed) _buildClaimedBanner(),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isClaimed
                                ? darkText.withOpacity(0.7)
                                : darkText,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isClaimed
                              ? claimedGreenLight
                              : Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isClaimed ? claimedGreen : Colors.teal,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          isClaimed
                              ? 'CLAIMED'
                              : (widget.item.price != null && widget.item.price! > 0
                              ? '£${widget.item.price!.toStringAsFixed(2)}'
                              : 'FREE'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isClaimed ? claimedGreen : Colors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isClaimed ? claimedGreenLight : lightPink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.item.category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isClaimed ? claimedGreen : primaryPink,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    widget.item.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: isClaimed ? darkText.withOpacity(0.7) : darkText,
                    ),
                  ),

                  if (widget.item.instructions != null &&
                      widget.item.instructions!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      "Pickup Instructions",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.item.instructions!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isClaimed
                                ? [claimedGreen, claimedGreen.withOpacity(0.8)]
                                : [primaryPink, accentPink],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Location for Pickup",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ✅ REAL MINI MAP
                  if (hasLocation)
                    GestureDetector(
                      onTap: () => _openExternalMaps(
                        widget.item.latitude!,
                        widget.item.longitude!,
                        label: widget.item.locationAddress,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isClaimed
                                  ? claimedGreen
                                  : primaryPink.withOpacity(0.5),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(widget.item.latitude!, widget.item.longitude!),
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('pickup'),
                                  position: LatLng(
                                      widget.item.latitude!, widget.item.longitude!),
                                  infoWindow: InfoWindow(
                                    title: 'Pickup location',
                                    snippet: widget.item.locationAddress ?? '',
                                  ),
                                ),
                              },
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              myLocationEnabled: false,
                              liteModeEnabled: true,
                              onTap: (_) => _openExternalMaps(
                                widget.item.latitude!,
                                widget.item.longitude!,
                                label: widget.item.locationAddress,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isClaimed
                            ? claimedGreenLight.withOpacity(0.3)
                            : Colors.blueGrey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isClaimed ? claimedGreen : Colors.blueGrey,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Location not provided',
                          style: TextStyle(
                            color: isClaimed ? claimedGreen : Colors.blueGrey,
                          ),
                        ),
                      ),
                    ),

                  // Address text under map
                  if (widget.item.locationAddress != null &&
                      widget.item.locationAddress!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: isClaimed ? claimedGreen : primaryPink,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.item.locationAddress!,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Message button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isClaimed
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              receiverId: widget.item.donorId,
                              receiverName: widget.item.donorName,
                              receiverPhoto: widget.item.donorPhoto,
                              donation: widget.item,
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        isClaimed ? Icons.check_circle_rounded : Icons.send,
                      ),
                      label: Text(
                        isClaimed
                            ? "This Item Has Been Claimed"
                            : "Message Donor",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isClaimed
                            ? Colors.grey.shade300
                            : primaryPink,
                        foregroundColor:
                        isClaimed ? Colors.grey.shade600 : Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: isClaimed ? 0 : 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Claimed banner
  Widget _buildClaimedBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [claimedGreenLight, claimedGreenLight.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: claimedGreen, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: claimedGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Donation Claimed! 🎉',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: claimedGreen,
                    fontFamily: 'Mont',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This donation has been successfully transferred and is no longer available.',
                  style: TextStyle(
                    fontSize: 12,
                    color: claimedGreen.withOpacity(0.8),
                    fontFamily: 'Mont',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------- VerticalListPage -------------------
class VerticalListPage extends StatelessWidget {
  final String categoryTitle;
  const VerticalListPage({super.key, required this.categoryTitle});

  static final CollectionReference<Map<String, dynamic>> _donationCollection =
  FirebaseFirestore.instance.collection('donations');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryTitle),
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _donationCollection
            .where('category', isEqualTo: categoryTitle)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No items'));
          }

          final items = docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = data['id'] ?? doc.id;
            return Donation.fromJson(data);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _verticalListItem(context, items[index]),
          );
        },
      ),
    );
  }

  Widget _verticalListItem(BuildContext context, Donation item) {
    // ✅ Check if claimed
    final bool isClaimed =
        (item.donorConfirmed ?? false) && (item.receiverConfirmed ?? false);

    final imageUrl = (item.imageUrls.isNotEmpty &&
        item.imageUrls.first.isNotEmpty)
        ? item.imageUrls.first
        : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => ItemDetailPage(item: item)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isClaimed ? Border.all(color: claimedGreen, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: isClaimed
                  ? claimedGreen.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            // Image with claimed overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null
                      ? Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    color: isClaimed
                        ? Colors.white.withOpacity(0.6)
                        : null,
                    colorBlendMode:
                    isClaimed ? BlendMode.lighten : null,
                  )
                      : Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isClaimed
                            ? [
                          claimedGreenLight.withOpacity(0.3),
                          claimedGreenLight.withOpacity(0.1)
                        ]
                            : [
                          lightPink.withOpacity(0.6),
                          lightPink.withOpacity(0.2)
                        ],
                      ),
                    ),
                    child: Icon(
                      isClaimed
                          ? Icons.check_circle_rounded
                          : Icons.photo_library,
                      size: 30,
                      color: isClaimed
                          ? claimedGreen.withOpacity(0.5)
                          : primaryPink.withOpacity(0.5),
                    ),
                  ),
                ),

                // ✅ Claimed badge on vertical list item
                if (isClaimed)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: claimedGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 8,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'CLAIMED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isClaimed
                          ? primaryPink.withOpacity(0.7)
                          : primaryPink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: isClaimed
                          ? Colors.grey[600]?.withOpacity(0.7)
                          : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: isClaimed ? claimedGreen : Colors.blueGrey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.locationAddress ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isClaimed
                                ? Colors.blueGrey.withOpacity(0.7)
                                : Colors.blueGrey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Price/Status badge
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isClaimed
                      ? claimedGreenLight
                      : Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isClaimed ? claimedGreen : Colors.redAccent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  isClaimed
                      ? 'CLAIMED'
                      : (item.price != null && item.price! > 0
                      ? '£${item.price!.toStringAsFixed(2)}'
                      : 'FREE'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isClaimed ? claimedGreen : Colors.redAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}