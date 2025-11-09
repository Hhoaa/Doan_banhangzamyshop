import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../models/collection.dart';
import '../../services/supabase_collection_service.dart';
import 'web_collection_gallery.dart';

class WebCollectionsListView extends StatefulWidget {
  final List<Collection> collections;
  final Function(Collection) onCollectionTap;

  const WebCollectionsListView({
    super.key,
    required this.collections,
    required this.onCollectionTap,
  });

  @override
  State<WebCollectionsListView> createState() => _WebCollectionsListViewState();
}

class _WebCollectionsListViewState extends State<WebCollectionsListView> {
  int _currentCollectionIndex = 0;
  int? _selectedImageIndex; // null = list view, not null = gallery view
  Map<int, List<String>> _collectionImages = {};
  Map<int, bool> _loadingImages = {};

  @override
  void initState() {
    super.initState();
    if (widget.collections.isNotEmpty) {
      _loadImagesForCollection(widget.collections[_currentCollectionIndex]);
    }
  }

  @override
  void didUpdateWidget(WebCollectionsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collections != widget.collections && widget.collections.isNotEmpty) {
      _loadImagesForCollection(widget.collections[_currentCollectionIndex]);
    }
  }

  Future<void> _loadImagesForCollection(Collection collection) async {
    if (_collectionImages.containsKey(collection.maBoSuuTap)) return;

    setState(() {
      _loadingImages[collection.maBoSuuTap] = true;
    });

    try {
      final images = await SupabaseCollectionService.getCollectionImages(
        collection.maBoSuuTap.toString(),
      );
      setState(() {
        _collectionImages[collection.maBoSuuTap] = images;
        _loadingImages[collection.maBoSuuTap] = false;
      });
    } catch (e) {
      setState(() {
        _loadingImages[collection.maBoSuuTap] = false;
      });
    }
  }

  void _previousCollection() {
    if (widget.collections.isEmpty) return;
    setState(() {
      _currentCollectionIndex = (_currentCollectionIndex - 1 + widget.collections.length) % widget.collections.length;
      _selectedImageIndex = null; // Reset gallery view
    });
    _loadImagesForCollection(widget.collections[_currentCollectionIndex]);
  }

  void _nextCollection() {
    if (widget.collections.isEmpty) return;
    setState(() {
      _currentCollectionIndex = (_currentCollectionIndex + 1) % widget.collections.length;
      _selectedImageIndex = null; // Reset gallery view
    });
    _loadImagesForCollection(widget.collections[_currentCollectionIndex]);
  }

  void _onImageTap(int imageIndex) {
    setState(() {
      _selectedImageIndex = imageIndex;
    });
  }

  void _closeGallery() {
    setState(() {
      _selectedImageIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.collections.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_outlined, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Chưa có bộ sưu tập nào',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final currentCollection = widget.collections[_currentCollectionIndex];
    final images = _collectionImages[currentCollection.maBoSuuTap] ?? [];
    final isLoading = _loadingImages[currentCollection.maBoSuuTap] ?? false;

    // If gallery view is active (image clicked)
    if (_selectedImageIndex != null && images.isNotEmpty) {
      return _buildGalleryView(currentCollection, images, _selectedImageIndex!);
    }

    // List view with collection info and image grid
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 40,
            right: 40,
            top: 0,
            bottom: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Collection header with navigation
              Row(
                children: [
                  if (widget.collections.length > 1) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                      onPressed: _previousCollection,
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentCollection.tenBoSuuTap,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (currentCollection.moTa != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            currentCollection.moTa!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              height: 1.8,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.collections.length > 1) ...[
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: AppColors.textPrimary),
                      onPressed: _nextCollection,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 48),
              // Image grid (decorative)
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (images.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Column(
                      children: [
                        Icon(Icons.image_not_supported, size: 64, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có hình ảnh nào',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildImageGrid(images),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<String> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 3;
        if (width >= 1200) {
          crossAxisCount = 4;
        } else if (width >= 900) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        // Giới hạn chỉ hiển thị 2 hàng
        final maxItems = crossAxisCount * 2;
        final limitedImages = images.take(maxItems).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: limitedImages.length,
          itemBuilder: (context, index) {
            // Index in limitedImages corresponds to index in original images (since we use take())
            final originalIndex = index;
            return GestureDetector(
              onTap: () => _onImageTap(originalIndex),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: limitedImages[index],
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
            );
          },
        );
      },
    );
  }

  Widget _buildGalleryView(Collection collection, List<String> images, int selectedIndex) {
    return WebCollectionGallery(
      collection: collection,
      initialImageIndex: selectedIndex,
      onClose: _closeGallery,
    );
  }
}
