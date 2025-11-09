import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import '../../theme/app_colors.dart';
import '../../models/collection.dart';
import '../../services/supabase_collection_service.dart';
import '../../widgets/common/collection_card.dart';
import '../notifications/notifications_screen.dart';
import '../../widgets/web/web_page_wrapper.dart';
import 'collection_detail_screen.dart';
import '../../widgets/collections/web_collections_list_view.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  List<Collection> _collections = [];
  bool _isLoading = true;
  static const int _imagesPerPage = 20; // Giới hạn 20 hình ảnh mỗi lần

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    try {
      setState(() => _isLoading = true);
      final collections = await SupabaseCollectionService.getCollections();
      setState(() {
        _collections = collections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải bộ sưu tập: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      backgroundColor: AppColors.background,
      appBar: kIsWeb ? null : AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Bộ sưu tập',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            ),
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _collections.isEmpty
              ? const Center(
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCollections,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Giống layout Home: grid 2x2 banner-style; responsive nhẹ trên web
                          final crossAxisCount = 2;
                          final spacing = 12.0;
                          final itemWidth = (constraints.maxWidth - spacing) / crossAxisCount;
                          final itemHeight = (kIsWeb && constraints.maxWidth >= 900)
                              ? itemWidth * 0.42
                              : itemWidth * 0.55;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: _collections.map((c) {
                              final imageUrl = c.hinhAnh.isNotEmpty ? c.hinhAnh.first : '';
                              return SizedBox(
                                width: itemWidth,
                                height: itemHeight,
                                child: _CollectionBannerTile(
                                  title: c.tenBoSuuTap,
                                  imageUrl: imageUrl,
                                  onTap: () => _showCollectionDetail(c),
                                ),
                              );
                            }).toList(),
                          );
                        },
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

  Widget _buildWebCollectionList() {
    return WebCollectionsListView(
      collections: _collections,
      onCollectionTap: (collection) => _showCollectionDetail(collection),
    );
  }

  void _showCollectionDetail(Collection collection) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectionDetailScreen(collection: collection),
      ),
    );
  }
}

class _CollectionBannerTile extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const _CollectionBannerTile({
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.lightGray.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator(color: AppColors.accentRed)),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.lightGray.withOpacity(0.3),
                child: const Icon(Icons.image_not_supported, color: AppColors.textSecondary),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 12,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
