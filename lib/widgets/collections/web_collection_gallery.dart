import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../models/collection.dart';
import '../../services/supabase_collection_service.dart';

class WebCollectionGallery extends StatefulWidget {
  final Collection collection;
  final int? initialImageIndex;
  final VoidCallback? onClose;

  const WebCollectionGallery({
    super.key,
    required this.collection,
    this.initialImageIndex,
    this.onClose,
  });

  @override
  State<WebCollectionGallery> createState() => _WebCollectionGalleryState();
}

class _WebCollectionGalleryState extends State<WebCollectionGallery> {
  List<String> _images = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      setState(() => _isLoading = true);
      final images = await SupabaseCollectionService.getCollectionImages(
        widget.collection.maBoSuuTap.toString(),
      );
      setState(() {
        _images = images;
        if (widget.initialImageIndex != null && 
            widget.initialImageIndex! >= 0 && 
            widget.initialImageIndex! < images.length) {
          _currentIndex = widget.initialImageIndex!;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải hình ảnh: $e')),
        );
      }
    }
  }

  void _previousImage() {
    if (_images.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _images.length) % _images.length;
    });
  }

  void _nextImage() {
    if (_images.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _images.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có hình ảnh nào',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1800),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background faded images layer - only fill content area, not header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left faded image
                if (_images.length > 1)
                  Expanded(
                    child: _buildFadedImage(
                      _images[(_currentIndex - 1 + _images.length) % _images.length],
                      Alignment.centerLeft,
                    ),
                  ),
                // Spacer for main image
                const SizedBox(width: 700),
                // Right faded image
                if (_images.length > 1)
                  Expanded(
                    child: _buildFadedImage(
                      _images[(_currentIndex + 1) % _images.length],
                      Alignment.centerRight,
                    ),
                  ),
              ],
            ),
            // Main content layer
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left navigation arrow
                      if (_images.length > 1)
                        _buildNavigationArrow(
                          icon: Icons.arrow_back_ios,
                          onTap: _previousImage,
                        ),
                      const SizedBox(width: 30),
                      // Main image
                      _buildMainImage(),
                      const SizedBox(width: 30),
                      // Right navigation arrow
                      if (_images.length > 1)
                        _buildNavigationArrow(
                          icon: Icons.arrow_forward_ios,
                          onTap: _nextImage,
                        ),
                    ],
                  ),
                  // Close button
                  if (widget.onClose != null)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        onPressed: widget.onClose,
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

  Widget _buildFadedImage(String imageUrl, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(
          left: alignment == Alignment.centerLeft ? 40 : 0,
          right: alignment == Alignment.centerRight ? 40 : 0,
        ),
        child: Container(
          width: 320,
          height: 480,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: 0.2,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.border,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.border,
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainImage() {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 700,
        maxHeight: 900,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: _images[_currentIndex],
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 700,
            height: 900,
            color: AppColors.border,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 700,
            height: 900,
            color: AppColors.border,
            child: const Icon(
              Icons.image_not_supported,
              size: 64,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(18),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

