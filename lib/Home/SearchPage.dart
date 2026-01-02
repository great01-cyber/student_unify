import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../Models/DonateModel.dart';
import '../../Models/LendPage.dart';
import '../listings/HorizontalLendList.dart';
import 'Drawer Section/My Listings/Listings.dart';
// Import the lend request widgets file

// Color palette - consistent with the app
const Color primaryPink = Color(0xFFFF6786);
const Color lightPink = Color(0xFFFFE5EC);
const Color accentPink = Color(0xFFFF9BAD);
const Color darkText = Color(0xFF2D3748);
const Color lightText = Color(0xFF718096);
const Color claimedGreen = Color(0xFF10B981);
const Color claimedGreenLight = Color(0xFFD1FAE5);

enum SearchMode { donations, lendRequests }

class SearchDonationPage extends StatefulWidget {
  const SearchDonationPage({super.key});

  @override
  State<SearchDonationPage> createState() => _SearchDonationPageState();
}

class _SearchDonationPageState extends State<SearchDonationPage> with SingleTickerProviderStateMixin {
  String searchQuery = "";
  String? selectedCategory;
  bool showFilters = false;
  SearchMode searchMode = SearchMode.donations; // ✅ NEW: Toggle between modes

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> categories = const [
    'All Categories',
    'Academic and Study Materials',
    'Sport and Leisure Wears',
    'Tech and Electronics',
    'Clothing and wears',
    'Dorm and Essential things',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Search Items",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
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
            icon: Icon(
              showFilters ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                showFilters = !showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box and Filters Section
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryPink.withOpacity(0.1), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // ✅ NEW: Mode Toggle (Donations / Lend Requests)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: lightPink.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildModeButton(
                            'Donations',
                            Icons.volunteer_activism_rounded,
                            SearchMode.donations,
                          ),
                        ),
                        Expanded(
                          child: _buildModeButton(
                            'Lend Requests',
                            Icons.handshake_rounded,
                            SearchMode.lendRequests,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Box
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryPink.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: searchMode == SearchMode.donations
                            ? "Search for donations..."
                            : "Search for borrow requests...",
                        hintStyle: TextStyle(color: lightText),
                        prefixIcon: Icon(Icons.search_rounded, color: primaryPink, size: 24),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: lightText),
                          onPressed: () {
                            setState(() {
                              searchQuery = "";
                            });
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: lightPink.withOpacity(0.2),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                ),

                // Filter Section
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: showFilters ? 70 : 0,
                  child: showFilters
                      ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: categories.map((category) {
                        final isSelected = selectedCategory == category ||
                            (category == 'All Categories' && selectedCategory == null);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : darkText,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (category == 'All Categories') {
                                  selectedCategory = null;
                                } else {
                                  selectedCategory = selected ? category : null;
                                }
                              });
                            },
                            selectedColor: primaryPink,
                            backgroundColor: lightPink.withOpacity(0.3),
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? primaryPink : lightPink,
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Results Section
          Expanded(
            child: searchMode == SearchMode.donations
                ? _buildDonationsResults()
                : _buildLendRequestsResults(),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Mode toggle button
  Widget _buildModeButton(String label, IconData icon, SearchMode mode) {
    final isSelected = searchMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          searchMode = mode;
          searchQuery = ""; // Reset search when switching modes
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [primaryPink, accentPink])
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : lightText,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Donations results (existing code)
  Widget _buildDonationsResults() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("donations")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("No donations available yet");
        }

        final docs = snapshot.data!.docs;

        // Filter the results
        final filteredDocs = docs.where((doc) {
          final data = doc.data();
          final title = (data["title"] ?? "").toString().toLowerCase();
          final description = (data["description"] ?? "").toString().toLowerCase();
          final category = (data["category"] ?? "").toString();

          // Search filter
          bool matchesSearch = searchQuery.isEmpty ||
              title.contains(searchQuery) ||
              description.contains(searchQuery);

          // Category filter
          bool matchesCategory = selectedCategory == null ||
              category == selectedCategory;

          return matchesSearch && matchesCategory;
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState(
            searchQuery.isNotEmpty
                ? "No items found for '$searchQuery'"
                : "No items in this category",
          );
        }

        // Convert to Donation models
        final items = filteredDocs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data["id"] = doc.id;
          return Donation.fromJson(data);
        }).toList();

        // Results header
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryPink, accentPink],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${items.length} ${items.length == 1 ? 'Donation' : 'Donations'} Found",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _buildDonationCard(context, items[index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ NEW: Lend requests results
  Widget _buildLendRequestsResults() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("lends")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("No borrow requests available yet");
        }

        final docs = snapshot.data!.docs;

        // Filter the results
        final filteredDocs = docs.where((doc) {
          final data = doc.data();
          final title = (data["title"] ?? "").toString().toLowerCase();
          final description = (data["description"] ?? "").toString().toLowerCase();
          final category = (data["category"] ?? "").toString();

          // Search filter
          bool matchesSearch = searchQuery.isEmpty ||
              title.contains(searchQuery) ||
              description.contains(searchQuery);

          // Category filter
          bool matchesCategory = selectedCategory == null ||
              category == selectedCategory;

          return matchesSearch && matchesCategory;
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState(
            searchQuery.isNotEmpty
                ? "No requests found for '$searchQuery'"
                : "No requests in this category",
          );
        }

        // Convert to LendModel
        final items = filteredDocs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data["id"] = doc.id;
          return LendModel.fromJson(data);
        }).toList();

        // Results header
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryPink, accentPink],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.handshake_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${items.length} ${items.length == 1 ? 'Request' : 'Requests'} Found",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _buildLendRequestCard(context, items[index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: lightPink.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 64,
              color: primaryPink.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your search or filters",
            style: TextStyle(
              fontSize: 14,
              color: lightText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ Donation card
  Widget _buildDonationCard(BuildContext context, Donation item) {
    final imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : null;

    // Check if claimed
    final bool isClaimed = (item.donorConfirmed ?? false) && (item.receiverConfirmed ?? false);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>ItemDetailPage(item: item),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isClaimed
                ? claimedGreen.withOpacity(0.5)
                : lightPink.withOpacity(0.5),
            width: isClaimed ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isClaimed
                  ? claimedGreen.withOpacity(0.08)
                  : primaryPink.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: imageUrl != null
                      ? Image.network(
                    imageUrl,
                    width: 100,
                    height: 120,
                    fit: BoxFit.cover,
                    color: isClaimed ? Colors.white.withOpacity(0.6) : null,
                    colorBlendMode: isClaimed ? BlendMode.lighten : null,
                    errorBuilder: (_, __, ___) => _buildImagePlaceholder(isClaimed),
                  )
                      : _buildImagePlaceholder(isClaimed),
                ),
                // Claimed badge
                if (isClaimed)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: claimedGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 10),
                          SizedBox(width: 2),
                          Text(
                            'CLAIMED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isClaimed ? darkText.withOpacity(0.7) : darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isClaimed ? claimedGreenLight : lightPink,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isClaimed ? claimedGreen : primaryPink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      item.description ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isClaimed ? lightText.withOpacity(0.7) : lightText,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Location and Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Location
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: isClaimed ? claimedGreen : primaryPink,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.locationAddress ?? "Unknown",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isClaimed ? lightText.withOpacity(0.7) : lightText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: isClaimed
                                ? LinearGradient(colors: [claimedGreen, claimedGreen.withOpacity(0.8)])
                                : const LinearGradient(colors: [primaryPink, accentPink]),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: isClaimed
                                    ? claimedGreen.withOpacity(0.3)
                                    : primaryPink.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            isClaimed
                                ? "CLAIMED"
                                : (item.price == null || item.price == 0
                                ? "FREE"
                                : "£${item.price!.toStringAsFixed(2)}"),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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

  // ✅ NEW: Lend request card
  Widget _buildLendRequestCard(BuildContext context, LendModel item) {
    final imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : null;

    // Check if claimed
    final bool isClaimed = item.donorConfirmed && item.receiverConfirmed;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LendRequestDetailPage(lendRequest: item),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isClaimed
                ? claimedGreen.withOpacity(0.5)
                : lightPink.withOpacity(0.5),
            width: isClaimed ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isClaimed
                  ? claimedGreen.withOpacity(0.08)
                  : primaryPink.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: imageUrl != null
                      ? Image.network(
                    imageUrl,
                    width: 100,
                    height: 120,
                    fit: BoxFit.cover,
                    color: isClaimed ? Colors.white.withOpacity(0.6) : null,
                    colorBlendMode: isClaimed ? BlendMode.lighten : null,
                    errorBuilder: (_, __, ___) => _buildLendImagePlaceholder(isClaimed),
                  )
                      : _buildLendImagePlaceholder(isClaimed),
                ),
                // Badge overlay
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: isClaimed
                          ? LinearGradient(colors: [claimedGreen, claimedGreen.withOpacity(0.8)])
                          : const LinearGradient(colors: [primaryPink, accentPink]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isClaimed ? Icons.check_circle_rounded : Icons.handshake_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          isClaimed ? 'CLAIMED' : 'NEED',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isClaimed ? darkText.withOpacity(0.7) : darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isClaimed ? claimedGreenLight : lightPink,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isClaimed ? claimedGreen : primaryPink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isClaimed ? lightText.withOpacity(0.7) : lightText,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: isClaimed ? claimedGreen : primaryPink,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.locationAddress ?? "Not specified",
                            style: TextStyle(
                              fontSize: 11,
                              color: isClaimed ? lightText.withOpacity(0.7) : lightText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  Widget _buildImagePlaceholder(bool isClaimed) {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isClaimed
              ? [claimedGreenLight.withOpacity(0.3), claimedGreenLight.withOpacity(0.1)]
              : [lightPink.withOpacity(0.3), lightPink.withOpacity(0.1)],
        ),
      ),
      child: Center(
        child: Icon(
          isClaimed ? Icons.check_circle_rounded : Icons.photo_library_rounded,
          size: 40,
          color: isClaimed
              ? claimedGreen.withOpacity(0.5)
              : primaryPink.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildLendImagePlaceholder(bool isClaimed) {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isClaimed
              ? [claimedGreenLight.withOpacity(0.3), claimedGreenLight.withOpacity(0.1)]
              : [lightPink.withOpacity(0.3), lightPink.withOpacity(0.1)],
        ),
      ),
      child: Center(
        child: Icon(
          isClaimed ? Icons.check_circle_rounded : Icons.handshake_rounded,
          size: 40,
          color: isClaimed
              ? claimedGreen.withOpacity(0.5)
              : primaryPink.withOpacity(0.5),
        ),
      ),
    );
  }
}