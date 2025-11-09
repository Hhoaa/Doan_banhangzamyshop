import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/app_colors.dart';
import '../../models/collection.dart';
import '../../services/supabase_collection_service.dart';
import '../../widgets/web/web_page_wrapper.dart';

class CollectionDetailScreen extends StatefulWidget {
  final Collection collection;
  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  late Future<List<String>> _imagesFuture;
  final ScrollController _scrollController = ScrollController();
  List<String> _allImages = [];
  int _visibleCount = 0;
  static const int _pageSize = 20;
  bool _isAppending = false;

  @override
  void initState() {
    super.initState();
    _imagesFuture = SupabaseCollectionService
        .getCollectionImages(widget.collection.maBoSuuTap.toString());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isAppending) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _appendMore();
    }
  }

  void _appendMore() {
    if (_visibleCount >= _allImages.length) return;
    setState(() => _isAppending = true);
    final next = (_visibleCount + _pageSize).clamp(0, _allImages.length);
    setState(() {
      _visibleCount = next;
      _isAppending = false;
    });
  }

  void _openImageViewer(int initialIndex) {
    if (_allImages.isEmpty || initialIndex >= _allImages.length) return;
    final controller = PageController(initialPage: initialIndex);
    int currentIndex = initialIndex;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: controller,
                      itemCount: _allImages.length,
                      onPageChanged: (index) {
                        setStateDialog(() => currentIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final imageUrl = _allImages[index];
                        return InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Center(
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(color: Colors.white70),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.image_not_supported,
                                color: Colors.white54,
                                size: 48,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    if (_allImages.length > 1) ...[
                      Positioned(
                        left: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 40),
                            onPressed: currentIndex > 0
                                ? () {
                                    if (!controller.hasClients) return;
                                    controller.previousPage(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 40),
                            onPressed: currentIndex < _allImages.length - 1
                                ? () {
                                    if (!controller.hasClients) return;
                                    controller.nextPage(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            '${currentIndex + 1}/${_allImages.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => controller.dispose());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      backgroundColor: AppColors.background,
      appBar: kIsWeb
          ? null
          : AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Text(
                widget.collection.tenBoSuuTap,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: !kIsWeb
                ? SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.collection.tenBoSuuTap,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (widget.collection.moTa != null &&
                            widget.collection.moTa!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.collection.moTa!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FutureBuilder<List<String>>(
                          future: _imagesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            _allImages = snapshot.data ?? const [];
                            if (_allImages.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Chưa có hình ảnh nào',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              );
                            }
                            if (_visibleCount == 0) {
                              // init first page
                              _visibleCount = _allImages.length < _pageSize ? _allImages.length : _pageSize;
                            }

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                int columns = 2;

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  cacheExtent: 800,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    childAspectRatio: 1,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: _visibleCount + (_visibleCount < _allImages.length ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= _visibleCount) {
                                      // loader item
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (_scrollController.hasClients) {
                                          _appendMore();
                                        }
                                      });
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    final imageUrl = _allImages[index];
                                    return GestureDetector(
                                      onTap: () => _openImageViewer(index),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          // Downscale to reduce memory usage
                                          memCacheWidth: 600,
                                          memCacheHeight: 600,
                                          maxWidthDiskCache: 800,
                                          maxHeightDiskCache: 800,
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
                                              color: AppColors.textSecondary,
                                              size: 36,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.collection.tenBoSuuTap,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (widget.collection.moTa != null &&
                          widget.collection.moTa!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.collection.moTa!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Expanded(
                        child: FutureBuilder<List<String>>(
                          future: _imagesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            _allImages = snapshot.data ?? const [];
                            if (_allImages.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Chưa có hình ảnh nào',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              );
                            }
                            if (_visibleCount == 0) {
                              // init first page
                              _visibleCount = _allImages.length < _pageSize ? _allImages.length : _pageSize;
                            }

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                int columns = 2;
                                if (kIsWeb) {
                                  if (width >= 1600) columns = 6;
                                  else if (width >= 1300) columns = 5;
                                  else if (width >= 1000) columns = 4;
                                  else if (width >= 700) columns = 3;
                                  else columns = 2;
                                }

                                return GridView.builder(
                                  controller: _scrollController,
                                  cacheExtent: 800,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    childAspectRatio: 1,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: _visibleCount + (_visibleCount < _allImages.length ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= _visibleCount) {
                                      // loader item
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    final imageUrl = _allImages[index];
                                    return GestureDetector(
                                      onTap: () => _openImageViewer(index),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          // Downscale to reduce memory usage
                                          memCacheWidth: 600,
                                          memCacheHeight: 600,
                                          maxWidthDiskCache: 800,
                                          maxHeightDiskCache: 800,
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
                                              color: AppColors.textSecondary,
                                              size: 36,
                                            ),
                                          ),
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
                  ),
          ),
        ),
      ),
    );

    if (kIsWeb) {
      return WebPageWrapper(
        showWebHeader: true,
        showTopBar: false,
        showFooter: true,
        child: content,
      );
    }
    return content;
  }
}


