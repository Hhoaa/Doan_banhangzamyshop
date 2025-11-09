import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product/home_product_card.dart';
import '../../models/product.dart';
import '../../models/banner_model.dart';
import '../../models/collection.dart';
import '../../services/supabase_product_service.dart';
import '../../services/supabase_review_service.dart';
import '../../services/supabase_banner_service.dart';
import '../../services/supabase_collection_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/ai_chat/bubble_visibility.dart';
import 'package:provider/provider.dart';
import '../product/product_detail_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../product/products_screen.dart';
import '../../widgets/product/product_options_bottom_sheet.dart';
import '../../widgets/language_selector.dart';
import '../notifications/notifications_screen.dart';
import '../collections/collections_screen.dart';
import '../collections/collection_detail_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/web/web_page_wrapper.dart';
import '../../services/supabase_discount_service.dart';
import '../../utils/currency_formatter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> featuredProducts = [];
  Map<int, Map<String, num>> productRatings = {}; // productId -> {avg,count}
  List<BannerModel> banners = [];
  List<Collection> collections = [];
  Set<int> favoriteProductIds = {};
  bool isLoading = true;
  int? _notifUserIdLoaded;
  List<Map<String, dynamic>> _availableDiscounts = [];
  bool _loadingDiscounts = false;

  @override
  void initState() {
    super.initState();
    // Ensure chat bubble is visible on Home
    BubbleVisibility.show();
    _loadData();
    // Ensure notifications are loaded after first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _maybeLoadNotifications(auth);
      auth.addListener(() {
        _maybeLoadNotifications(auth);
      });
    });
  }

  void _maybeLoadNotifications(AuthProvider auth) {
    if (auth.user == null) return;
    final userId = auth.user!.maNguoiDung;
    if (_notifUserIdLoaded == userId) return;
    _notifUserIdLoaded = userId;
    Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).loadNotifications(userId);
  }

  Future<void> _loadData() async {
    try {
      print('🔄 Starting to load data...');
      if (mounted) {
        setState(() {
          _loadingDiscounts = true;
        });
      }
      // Load products nổi bật, banners và collections song song
      final futures = await Future.wait([
        SupabaseProductService.getFeaturedProducts(limit: 20),
        SupabaseBannerService.getBanners(),
        SupabaseCollectionService.getCollections(),
      ]);

      final products = futures[0] as List<Product>;
      final banners = futures[1] as List<BannerModel>;
      final collections = futures[2] as List<Collection>;

      print('📦 Products loaded: ${products.length}');
      if (products.isNotEmpty) {
        print('Sample product: ${products.first.tenSanPham}');
        print('Product images: ${products.first.hinhAnh}');
      }

      print('🖼️ Banners loaded: ${banners.length}');
      if (banners.isNotEmpty) {
        print('Sample banner: ${banners.first.maBanner}');
        print('Banner image: ${banners.first.hinhAnh}');
      }

      print('📚 Collections loaded: ${collections.length}');
      if (collections.isNotEmpty) {
        print('Sample collection: ${collections.first.tenBoSuuTap}');
      }

      // Load favorite products via provider for global sync
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        await Provider.of<FavoritesProvider>(
          context,
          listen: false,
        ).ensureLoaded(authProvider.user!.maNguoiDung);
      }

      List<Map<String, dynamic>> discounts = [];
      try {
        discounts =
            authProvider.user != null
                ? await SupabaseDiscountService.getAvailableDiscountsForUser(
                  authProvider.user!.maNguoiDung,
                )
                : await SupabaseDiscountService.getAvailableDiscounts();
      } catch (e) {
        print('⚠️ Error loading discounts: $e');
      }

      // fetch rating stats per product in parallel
      final ratingsEntries = await Future.wait(
        products.map((p) async {
          final stats = await SupabaseReviewService.getProductReviewStats(
            p.maSanPham,
          );
          return MapEntry(p.maSanPham, {
            'avg': (stats['averageRating'] ?? 0.0) as num,
            'count': (stats['totalReviews'] ?? 0) as num,
          });
        }),
      );
      productRatings = {for (final e in ratingsEntries) e.key: e.value};

      setState(() {
        featuredProducts = products;
        this.banners = banners;
        this.collections = collections;
        _availableDiscounts = discounts;
        _loadingDiscounts = false;
        if (authProvider.user != null) {
          favoriteProductIds =
              Provider.of<FavoritesProvider>(
                context,
                listen: false,
              ).favoriteIds;
        } else {
          favoriteProductIds = {};
        }
        isLoading = false;
      });

      print('✅ Data loaded successfully!');
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        isLoading = false;
        _loadingDiscounts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          kIsWeb
              ? null
              : AppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: const Text(
                  'ZAMY',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    letterSpacing: 2,
                  ),
                ),
                centerTitle: true,
                actions: [
                  const LanguageSelector(showIcon: true, showText: false),
                  const SizedBox(width: 4),
                  Consumer2<AuthProvider, NotificationProvider>(
                    builder: (context, auth, notif, _) {
                      final unread = notif.unreadCount;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed:
                                () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const NotificationsScreen(),
                                  ),
                                ),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.accentRed,
                                size: 20,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    unread > 0 ? Colors.red : AppColors.border,
                                shape: BoxShape.rectangle,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                style: TextStyle(
                                  color:
                                      unread > 0
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
      body: Stack(
        children: [
          isLoading
              ? _buildLoadingState()
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Banner carousel
                          _buildBannerCarousel(),
                          const SizedBox(height: 16),
                          _buildDiscountStrip(),
                          const SizedBox(height: 32),
                          // Featured products
                          _buildFeaturedProducts(),
                          const SizedBox(height: 32),
                          // Collections
                          _buildCollections(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          // AI Chat Button - chỉ hiển thị ở home
          Positioned(
            right: 16,
            bottom: 16, // Sát dưới một chút
            child: FloatingActionButton(
              heroTag: 'ai_chat_home',
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AIChatScreen()),
                );
              },
              child: const Icon(Icons.smart_toy, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Banner loading
          Container(
            height: 220,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.lightGray.withOpacity(0.3),
                  AppColors.lightGray.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accentRed),
            ),
          ),
          const SizedBox(height: 32),
          // Products loading
          _buildProductsLoading(),
          const SizedBox(height: 32),
          // Collections loading
          _buildCollectionsLoading(),
        ],
      ),
    );
  }

  Widget _buildProductsLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(
              context,
            ).translate('featured_products').toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder:
                (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentRed,
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionsLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(context).translate('collections').toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 2,
            itemBuilder:
                (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentRed,
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCarousel() {
    if (banners.isEmpty) {
      return Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentRed.withOpacity(0.1),
              AppColors.accentRed.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accentRed.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_outlined,
                size: 50,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).translate('no_banners'),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight =
        screenWidth >= 1200
            ? 320.0
            : screenWidth >= 900
            ? 280.0
            : 220.0;
    return CarouselSlider(
      options: CarouselOptions(
        height: bannerHeight,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        viewportFraction: 1.0,
        enableInfiniteScroll: true,
        enlargeCenterPage: false,
      ),
      items: banners.map((banner) => _buildBannerItem(banner.hinhAnh)).toList(),
    );
  }

  Widget _buildDiscountStrip() {
    if (_loadingDiscounts) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder:
                (context, index) => Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentRed,
                    ),
                  ),
                ),
          ),
        ),
      );
    }

    if (_availableDiscounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('discount').toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  _availableDiscounts
                      .map((discount) => _buildDiscountCard(discount))
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCard(Map<String, dynamic> discount) {
    final code = (discount['code'] ?? '').toString();
    final title = (discount['noi_dung'] ?? '').toString();
    final description = (discount['mo_ta'] ?? '').toString();
    final minOrder = (discount['don_gia_toi_thieu'] as num?)?.toDouble() ?? 0;
    final endDateStr = discount['ngay_ket_thuc']?.toString();
    DateTime? endDate;
    if (endDateStr != null && endDateStr.isNotEmpty) {
      endDate = DateTime.tryParse(endDateStr);
    }

    final discountLabel = _formatDiscountValue(discount);
    final borderColor = AppColors.accentRed.withOpacity(0.3);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.accentRed.withOpacity(0.85),
            AppColors.accentRed.withOpacity(0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentRed.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            discountLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (minOrder > 0) ...[
            const SizedBox(height: 6),
            Text(
              (AppLocalizations.of(context).locale.languageCode == 'vi'
                      ? 'Đơn tối thiểu '
                      : 'Min order ') +
                  CurrencyFormatter.formatVND(minOrder),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
          if (endDate != null) ...[
            const SizedBox(height: 6),
            Text(
              'HSD: ${DateFormat('dd/MM/yyyy').format(endDate)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentRed,
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => _copyDiscountCode(code),
              child: Text(
                AppLocalizations.of(context).translate('apply'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDiscountValue(Map<String, dynamic> discount) {
    final type = discount['loai_giam_gia']?.toString();
    final value = (discount['muc_giam_gia'] as num?)?.toDouble() ?? 0;
    if (type == 'percentage') {
      final formatted =
          value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
      return '-$formatted%';
    }
    return '-${CurrencyFormatter.formatVND(value)}';
  }

  Future<void> _copyDiscountCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    final locale = AppLocalizations.of(context).locale.languageCode;
    final message =
        locale == 'vi' ? 'Đã sao chép mã $code' : 'Copied code $code';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildBannerItem(String imageUrl) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain, // hiển thị full, không crop
          width: double.infinity,
          alignment: Alignment.center,
          placeholder:
              (context, url) => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentRed,
                  strokeWidth: 2,
                ),
              ),
          errorWidget:
              (context, url, error) => const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: AppColors.textSecondary,
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    if (featuredProducts.isEmpty) {
      return _buildEmptyProducts();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                ).translate('featured_products').toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  onPressed:
                      () => Navigator.of(context).push(
                        kIsWeb
                            ? WebPageWrapper.wrapRoute(
                              child: const ProductsScreen(),
                              showTopBar: false,
                            )
                            : MaterialPageRoute(
                              builder: (context) => const ProductsScreen(),
                            ),
                      ),
                  child: Text(
                    AppLocalizations.of(context).translate('view_all'),
                    style: const TextStyle(
                      color: AppColors.accentRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Hiển thị sản phẩm nổi bật với grid 4-5 sản phẩm trên 1 hàng
        LayoutBuilder(
          builder: (context, constraints) {
            // Tính số cột dựa trên chiều rộng màn hình
            final screenWidth = constraints.maxWidth;
            int crossAxisCount;
            if (screenWidth >= 1200) {
              crossAxisCount = 5; // Desktop lớn: 5 sản phẩm/hàng
            } else if (screenWidth >= 900) {
              crossAxisCount = 4; // Desktop: 4 sản phẩm/hàng
            } else if (screenWidth >= 600) {
              crossAxisCount = 3; // Tablet: 3 sản phẩm/hàng
            } else {
              crossAxisCount = 2; // Mobile: 2 sản phẩm/hàng
            }

            final spacing = 12.0;
            final childAspectRatio = kIsWeb ? 0.72 : 0.55;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                ),
                itemCount: featuredProducts.length,
                itemBuilder: (context, index) {
                  final product = featuredProducts[index];
                  return Consumer<FavoritesProvider>(
                    builder: (context, favoritesProvider, _) {
                      return HomeProductCard(
                        product: product,
                        rating:
                            (productRatings[product.maSanPham]?['avg'] ?? 0.0)
                                .toDouble(),
                        reviewCount:
                            (productRatings[product.maSanPham]?['count'] ?? 0)
                                .toInt(),
                        onTap:
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => ProductDetailScreen(
                                      productId: product.maSanPham,
                                    ),
                              ),
                            ),
                        onFavorite: () => _toggleFavorite(product.maSanPham),
                        isFavorite: favoritesProvider.isFavorite(
                          product.maSanPham,
                        ),
                        onAddToCart: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder:
                                (context) =>
                                    ProductOptionsBottomSheet(product: product),
                          );
                        },
                        onBuyNow: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder:
                                (context) => ProductOptionsBottomSheet(
                                  product: product,
                                  isBuyNow: true,
                                ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(
              context,
            ).translate('featured_products').toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.lightGray.withOpacity(0.3),
                AppColors.lightGray.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 60,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).translate('no_products'),
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).translate('coming_soon'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollections() {
    if (collections.isEmpty) {
      return _buildEmptyCollections();
    }

    final items = collections.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                ).translate('collections').toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CollectionsScreen(),
                        ),
                      ),
                  child: Text(
                    AppLocalizations.of(context).translate('see_more'),
                    style: const TextStyle(
                      color: AppColors.accentRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2x2 banner grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final crossAxisCount = 2;
              final spacing = 12.0;
              final itemWidth =
                  (constraints.maxWidth - spacing) / crossAxisCount;
              final itemHeight =
                  isWide ? itemWidth * 0.42 : itemWidth * 0.55; // banner ratio

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(items.length, (index) {
                  final c = items[index];
                  final imageUrl = c.hinhAnh.isNotEmpty ? c.hinhAnh.first : '';
                  return SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: _CollectionBanner(
                      title: c.tenBoSuuTap,
                      imageUrl: imageUrl,
                      onTap:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      CollectionDetailScreen(collection: c),
                            ),
                          ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCollections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(context).translate('collections').toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentRed.withOpacity(0.1),
                AppColors.accentRed.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentRed.withOpacity(0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.collections_outlined,
                  size: 60,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).translate('no_collections'),
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(
                    context,
                  ).translate('collections_coming_soon'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFavorite(int productId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).translate('please_login_for_favorites'),
            ),
          ),
        );
        return;
      }
      final fav = Provider.of<FavoritesProvider>(context, listen: false);
      await fav.toggle(authProvider.user!.maNguoiDung, productId);
      setState(() {
        favoriteProductIds = fav.favoriteIds;
      });
      final nowFavorite = favoriteProductIds.contains(productId);
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nowFavorite
                ? l10n.translate('added_to_favorites_success')
                : l10n.translate('removed_from_favorites_success'),
          ),
          backgroundColor: nowFavorite ? Colors.green : AppColors.accentRed,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
      );
    }
  }
}

class _CollectionBanner extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const _CollectionBanner({
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
              placeholder:
                  (context, url) => Container(
                    color: AppColors.lightGray.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentRed,
                      ),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    color: AppColors.lightGray.withOpacity(0.3),
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppColors.textSecondary,
                    ),
                  ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.45), Colors.transparent],
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
