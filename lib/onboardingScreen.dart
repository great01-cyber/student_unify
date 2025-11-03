import 'package:flutter/material.dart';

import 'AuthPage.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardPageData {
  final String title;
  final String subtitle;
  final String? imageAsset;

  // IMAGE CUSTOMISATION
  final double? imageWidth; // null = responsive default
  final double? imageHeight; // null = responsive default
  final BoxFit? fit;
  final Alignment? alignment;
  final Color? bgColor;
  final double? borderRadius;

  const _OnboardPageData({
    required this.title,
    required this.subtitle,
    this.imageAsset,
    this.imageWidth,
    this.imageHeight,
    this.fit,
    this.alignment,
    this.bgColor,
    this.borderRadius,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardPageData> _pages = const [
    _OnboardPageData(
      title: 'Welcome to Student Unify',
      subtitle: 'This is the private hub for verified students. Buy, sell, and share securely with a trusted community from universities across the country.',
      imageAsset: "assets/images/university.png",
      imageWidth: 500,
      imageHeight: 500,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      bgColor: Color(0xFFF5F5F5),
      borderRadius: 16,
    ),
    _OnboardPageData(
      title: 'Share Smarter Not Harder',
      subtitle: 'Save & Earn: Buy, sell, and swap textbooks, furniture, and dorm essentials.',
      imageAsset: "assets/images/sharing.png",
      // Example: make this image wider and crop slightly
      imageWidth: 350,
      imageHeight: 350,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      bgColor: Colors.transparent,
      borderRadius: 12,
    ),
    _OnboardPageData(
      title: 'Get Verified to Join',
      subtitle: 'It all starts with your university email. Verifying your status is fast, secure, and unlocks the entire network.',
      imageAsset: "assets/images/verified.png",
      imageWidth: 500,
      imageHeight: 500,
      fit: BoxFit.contain,
      alignment: Alignment.topCenter,
      bgColor: Color(0xFFF5F5F5),
      borderRadius: 20,
    ),
  ];

  void _goToNext() {
    if (_currentPage < _pages.length - 1) {
      _controller.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skip() {
    // Navigate immediately when skipping
    _finishOnboarding();
  }

  void _finishOnboarding() {
    // 2. NAVIGATE TO THE AUTH PAGE
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>  AuthPage(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_pages.length, (index) {
        final bool isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 18 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1E88E5) : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }

  // Tap to preview full screen with pinch/zoom
  void _openPreview(String asset) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(8),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 4,
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Render image container with customisations applied
  Widget _buildImageFor(_OnboardPageData page) {
    final mq = MediaQuery.of(context);
    final defaultWidth = mq.size.width * 0.55;  // responsive fallback
    final defaultHeight = mq.size.width * 0.55; // square fallback

    final width = page.imageWidth ?? defaultWidth;
    final height = page.imageHeight ?? defaultHeight;
    final fit = page.fit ?? BoxFit.contain;
    final alignment = page.alignment ?? Alignment.center;
    final bgColor = page.bgColor ?? Colors.transparent;
    final borderRadius = BorderRadius.circular(page.borderRadius ?? 16);

    if (page.imageAsset == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius,
        ),
        child: const Icon(Icons.school, size: 90, color: Color(0xFF9E9E9E)),
      );
    }

    return GestureDetector(
      onTap: () => _openPreview(page.imageAsset!),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius,
        ),
        clipBehavior: Clip.hardEdge,
        child: Image.asset(
          page.imageAsset!,
          fit: fit,
          alignment: alignment,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Image not found', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top action row (Skip)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: TextButton(
                  onPressed: _skip,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Color(0xFF1E88E5),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // IMAGE (customisable)
                        _buildImageFor(page),
                        const SizedBox(height: 28),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            fontFamily: 'Quicksand',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Quicksand',
                            fontSize: 16,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots + Next/Done button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDots(),
                  ElevatedButton(
                    onPressed: _goToNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Done' : 'Next',
                      style: const TextStyle(
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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
}