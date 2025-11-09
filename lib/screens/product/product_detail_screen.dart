import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../models/product.dart';
import '../../models/product_variant.dart';
import '../../models/size.dart';
import '../../models/color.dart';
import '../../models/review.dart';
import '../../services/supabase_product_service.dart';
import '../../services/supabase_variant_service.dart';
import '../../services/supabase_review_service.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/rating_stars.dart';
import '../../widgets/review/reviews_list_widget.dart';
import '../auth/login_screen.dart';
// import '../review/review_screen.dart';
import '../../utils/review_dialog_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
// import '../../models/store_location.dart';
// import '../../widgets/map/free_store_map.dart';
// import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../web/auth_combined_web_screen.dart';
import '../../widgets/web/web_page_wrapper.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? product;
  List<ProductVariant> variants = [];
  List<Size> sizes = [];
  List<ColorModel> colors = [];
  List<Review> reviews = [];
  Map<String, dynamic> reviewStats = {};
  bool isLoading = true;
  bool isFavorite = false;
  bool _isDescriptionExpanded = false;

  // Helper function to format VND currency
  String _formatVND(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  // Parse hex color từ maMauHex
  Color _parseColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return Colors.grey; // Màu mặc định nếu không có hex
    }
    
    // Loại bỏ # nếu có
    String hex = hexColor.replaceAll('#', '');
    
    // Nếu hex không đúng format, trả về màu mặc định
    if (hex.length != 6 && hex.length != 8) {
      return Colors.grey;
    }
    
    try {
      // Parse hex thành Color
      return Color(int.parse('FF$hex', radix: 16)); // FF = alpha channel
    } catch (e) {
      return Colors.grey;
    }
  }

  // Selected variants
  int? selectedSizeId;
  int? selectedColorId;
  int quantity = 1;
  late TextEditingController _quantityController;

  PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: quantity.toString());
    if (!kIsWeb) {
      _quantityController.addListener(() {
        final parsed = int.tryParse(_quantityController.text);
        if (parsed == null || parsed <= 0) {
          if (quantity != 1) {
            setState(() => quantity = 1);
          }
          _quantityController.value = const TextEditingValue(
            text: '1',
            selection: TextSelection.collapsed(offset: 1),
          );
        } else if (parsed != quantity) {
          setState(() => quantity = parsed);
        }
      });
    }
    _loadProductDetails();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProductDetails() async {
    try {
      setState(() => isLoading = true);

      final productData = await SupabaseProductService.getProductById(
        widget.productId,
      );

      if (productData != null) {
        setState(() {
          product = productData;
        });

        await _loadVariantsAndOptions();
        await _checkFavoriteStatus();
      }
    } catch (e) {
      print('Error loading product details: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadVariantsAndOptions() async {
    if (product == null) return;

    try {
      final futures = await Future.wait([
        SupabaseVariantService.getSizesForProduct(product!.maSanPham),
        // SupabaseVariantService.getSizes(),
        //SupabaseVariantService.getColors(),
        SupabaseVariantService.getColorsForProduct(product!.maSanPham),
        SupabaseVariantService.getProductVariants(product!.maSanPham),
        SupabaseReviewService.getProductReviews(product!.maSanPham),
        SupabaseReviewService.getProductReviewStats(product!.maSanPham),
      ]);

      setState(() {
        sizes = futures[0] as List<Size>;
        colors = futures[1] as List<ColorModel>;
        variants = futures[2] as List<ProductVariant>;
        reviews = futures[3] as List<Review>;
        reviewStats = futures[4] as Map<String, dynamic>;
      });
    } catch (e) {
      print('Error loading variants: $e');
    }
  }

  Future<void> _checkLoginAndAddToCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. Kiểm tra đăng nhập
    if (authProvider.user == null) {
      _showLoginDialog();
      return;
    }

    // 2. Kiểm tra đã chọn size và màu
    if (selectedSizeId == null || selectedColorId == null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.translate('please_select')} ${l10n.size} ${l10n.translate('and')} ${l10n.color}',
          ),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    // 3. Kiểm tra tồn kho - QUAN TRỌNG
    final selectedVariant = _getSelectedVariant();

    if (selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('no_products_found'),
          ),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    if (selectedVariant.tonKho <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('out_of_stock')),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    if (quantity > selectedVariant.tonKho) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.translate('in_stock')}: ${selectedVariant.tonKho}',
          ),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    // 4. Thêm vào giỏ hàng
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final success = await cartProvider.addToCart(
      product!,
      selectedSizeId!,
      selectedColorId!,
      quantity,
    );

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? l10n.translate('added_to_cart')
                : l10n.translate('failed_to_add_cart'),
          ),
          backgroundColor: success ? Colors.green : AppColors.accentRed,
        ),
      );
    }
  }

  ProductVariant? _getSelectedVariant() {
    if (selectedSizeId == null || selectedColorId == null) {
      return null;
    }

    try {
      return variants.firstWhere(
        (variant) =>
            variant.maSize == selectedSizeId &&
            variant.maMau == selectedColorId,
      );
    } catch (e) {
      return null;
    }
  }

  int _getAvailableStock() {
    final variant = _getSelectedVariant();
    return variant?.tonKho ?? 0;
  }

  void _showPreviousImage() {
    if (_pageController.hasClients && _currentImageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showNextImage() {
    if (_pageController.hasClients &&
        product != null &&
        _currentImageIndex < product!.hinhAnh.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildImageNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final button = Material(
      color: Colors.black.withOpacity(0.45),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );

    if (onPressed == null) {
      return Opacity(opacity: 0.3, child: IgnorePointer(child: button));
    }

    return button;
  }
  // buy-now flow no longer used on this screen

  Future<void> _toggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      _showLoginDialog();
      return;
    }
    try {
      final fav = Provider.of<FavoritesProvider>(context, listen: false);
      await fav.toggle(authProvider.user!.maNguoiDung, product!.maSanPham);
      setState(() {
        isFavorite = fav.isFavorite(product!.maSanPham);
      });
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? l10n.translate('add_to_favorites')
                : l10n.translate('remove_from_favorites'),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
      );
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null && product != null) {
      try {
        final fav = Provider.of<FavoritesProvider>(context, listen: false);
        await fav.ensureLoaded(authProvider.user!.maNguoiDung);
        setState(() {
          isFavorite = fav.isFavorite(product!.maSanPham);
        });
      } catch (e) {
        print('Error checking favorite status: $e');
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).login),
            content: Text(
              AppLocalizations.of(
                context,
              ).translate('please_login_for_favorites'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (kIsWeb) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AuthCombinedWebScreen(),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                },
                child: Text(AppLocalizations.of(context).login),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure localization import is available
    if (isLoading) {
      return WebPageWrapper(
        showTopBar: false,
        showWebHeader: true,
        showFooter: true,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar:
              kIsWeb
                  ? null
                  : AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.accentRed),
          ),
        ),
      );
    }

    if (product == null) {
      return WebPageWrapper(
        showTopBar: false,
        showWebHeader: true,
        showFooter: true,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar:
              kIsWeb
                  ? null
                  : AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
          body: Center(
            child: Text(
              AppLocalizations.of(context).translate('no_products_found'),
            ),
          ),
        ),
      );
    }

    return WebPageWrapper(
      showTopBar: false,
      showWebHeader: true,
      showFooter: true,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar:
            kIsWeb
                ? null
                : AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () {
                        final name = product!.tenSanPham;
                        final id = product!.maSanPham;
                        final url = 'https://zamy.shop/product/$id';
                        final text =
                            '${AppLocalizations.of(context).translate('product_detail')}: "$name" - $url';
                        Share.share(text, subject: name);
                      },
                      icon: const Icon(Icons.share, color: Colors.black),
                    ),
                    IconButton(
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? AppColors.accentRed : Colors.black,
                      ),
                    ),
                  ],
                ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildProductImages()),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildProductInfo(),
                                  const SizedBox(height: 8),
                                  _buildProductOptions(),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildProductImages(),
                        _buildProductInfo(),
                        Container(height: 8, color: const Color(0xFFF5F5F5)),
                        _buildProductOptions(),
                      ],
                      Container(height: 8, color: const Color(0xFFF5F5F5)),
                      _buildDescription(),
                      Container(height: 8, color: const Color(0xFFF5F5F5)),
                      // _buildStoreLocationSection(),
                      Container(height: 8, color: const Color(0xFFF5F5F5)),
                      _buildReviewsSection(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: null,
      ),
    );
  }

  Widget _buildProductImages() {
    return Container(
      height: 350,
      color: Colors.white,
      child:
          product!.hinhAnh.isNotEmpty
              ? Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: product!.hinhAnh.length,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: product!.hinhAnh[index],
                        fit: BoxFit.contain,
                        placeholder:
                            (context, url) => Container(
                              color: const Color(0xFFF5F5F5),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.accentRed,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: const Color(0xFFF5F5F5),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                      );
                    },
                  ),
                  if (product!.hinhAnh.length > 1) ...[
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 16,
                      child: Center(
                        child: _buildImageNavButton(
                          icon: Icons.chevron_left,
                          onPressed:
                              _currentImageIndex > 0 ? _showPreviousImage : null,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 16,
                      child: Center(
                        child: _buildImageNavButton(
                          icon: Icons.chevron_right,
                          onPressed:
                              _currentImageIndex < product!.hinhAnh.length - 1
                                  ? _showNextImage
                                  : null,
                        ),
                      ),
                    ),
                  ],
                  if (product!.hinhAnh.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          product!.hinhAnh.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color:
                                  _currentImageIndex == index
                                      ? AppColors.accentRed
                                      : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )
              : Container(
                color: const Color(0xFFF5F5F5),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name
          Text(
            product!.tenSanPham,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatVND(product!.giaBan)} ₫',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentRed,
                ),
              ),
              if (product!.mucGiaGoc > product!.giaBan) ...[
                const SizedBox(width: 8),
                Text(
                  '${_formatVND(product!.mucGiaGoc)} ₫',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '-${(((product!.mucGiaGoc - product!.giaBan) / product!.mucGiaGoc) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Rating
          Row(
            children: [
              RatingStars(
                rating: (reviewStats['averageRating'] ?? 0.0).toDouble(),
                itemSize: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${(reviewStats['averageRating'] ?? 0.0).toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Text(
                '(${reviewStats['totalReviews'] ?? 0} ${AppLocalizations.of(context).translate('reviews')})',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductOptions() {
    final availableStock = _getAvailableStock();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Size Selection
          if (sizes.isNotEmpty) ...[
            const Text(
              'Size',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  sizes.map((size) {
                    final isSelected = selectedSizeId == size.maSize;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSizeId = size.maSize;
                          // Reset quantity khi đổi size
                          quantity = 1;
                          if (kIsWeb) {
                            _quantityController.text = '1';
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.accentRed : Colors.white,
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.accentRed
                                    : Colors.grey.shade300,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          size.tenSize,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Color Selection
          if (colors.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context).color,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  colors.map((color) {
                    final isSelected = selectedColorId == color.maMau;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColorId = color.maMau;
                          // Reset quantity khi đổi màu
                          quantity = 1;
                          if (kIsWeb) {
                            _quantityController.text = '1';
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.accentRed
                                    : Colors.grey.shade300,
                            width: isSelected ? 2.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Hiển thị màu thật (Circle)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _parseColorFromHex(color.maMauHex),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tên màu
                            Text(
                              color.tenMau,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Stock Info - THÊM MỚI
          if (selectedSizeId != null && selectedColorId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    availableStock > 0
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    availableStock > 0 ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: availableStock > 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    availableStock > 0
                        ? '${AppLocalizations.of(context).translate('in_stock')}: $availableStock'
                        : AppLocalizations.of(
                          context,
                        ).translate('out_of_stock'),
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          availableStock > 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Quantity - CẬP NHẬT
          Row(
            children: [
              Text(
                AppLocalizations.of(context).quantity,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12), // Khoảng cách nhỏ giữa chữ "Số lượng" và input
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed:
                          quantity > 1
                              ? () {
                                setState(() {
                                  quantity--;
                                  _quantityController.value = TextEditingValue(
                                    text: quantity.toString(),
                                    selection: TextSelection.collapsed(
                                      offset: quantity.toString().length,
                                    ),
                                  );
                                });
                              }
                              : null,
                      icon: const Icon(Icons.remove, size: 16),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    // TextField nhập số lượng cho cả web & mobile
                    SizedBox(
                      width: 60,
                      height: 32,
                      child: TextField(
                        controller: _quantityController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        onChanged: kIsWeb
                            ? (value) {
                              final intValue = int.tryParse(value);
                              if (intValue != null && intValue > 0) {
                                final maxQuantity =
                                    availableStock > 0 ? availableStock : 999;
                                final newQuantity = intValue > maxQuantity
                                    ? maxQuantity
                                    : intValue;
                                if (newQuantity != quantity) {
                                  setState(() {
                                    quantity = newQuantity;
                                  });
                                  _quantityController.value = TextEditingValue(
                                    text: newQuantity.toString(),
                                    selection: TextSelection.collapsed(
                                      offset: newQuantity.toString().length,
                                    ),
                                  );
                                }
                              }
                            }
                            : null,
                        onSubmitted: kIsWeb
                            ? (value) {
                              final intValue = int.tryParse(value);
                              if (intValue != null && intValue > 0) {
                                final maxQuantity =
                                    availableStock > 0 ? availableStock : 999;
                                final newQuantity = intValue > maxQuantity
                                    ? maxQuantity
                                    : intValue;
                                setState(() {
                                  quantity = newQuantity;
                                });
                                _quantityController.value = TextEditingValue(
                                  text: newQuantity.toString(),
                                  selection: TextSelection.collapsed(
                                    offset: newQuantity.toString().length,
                                  ),
                                );
                              } else {
                                setState(() {
                                  quantity = 1;
                                });
                                _quantityController.value = const TextEditingValue(
                                  text: '1',
                                  selection: TextSelection.collapsed(offset: 1),
                                );
                              }
                            }
                            : null,
                      ),
                    ),
                    IconButton(
                      // Giới hạn quantity không vượt quá tồn kho
                      onPressed:
                          (availableStock > 0 && quantity < availableStock)
                              ? () {
                                setState(() {
                                  quantity++;
                                  _quantityController.value = TextEditingValue(
                                    text: quantity.toString(),
                                    selection: TextSelection.collapsed(
                                      offset: quantity.toString().length,
                                    ),
                                  );
                                });
                              }
                              : null,
                      icon: const Icon(Icons.add, size: 16),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Add to Cart Button - MOVED HERE
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkLoginAndAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEE4D2D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context).addToCart,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final description = product!.moTaSanPham ??
        AppLocalizations.of(context).translate('no_description');
    final maxLines = 3; // Số dòng hiển thị khi thu gọn
    final shouldShowExpandButton = description.length > 150; // Nếu dài hơn 150 ký tự

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('product_description'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
            maxLines: _isDescriptionExpanded ? null : maxLines,
            overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (shouldShowExpandButton) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Text(
                _isDescriptionExpanded
                    ? 'Thu gọn'
                    : AppLocalizations.of(context).translate('see_more'),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.accentRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /* Widget _buildStoreLocationSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppLocalizations.of(context).translate('store_location'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Show the first store as default (you can modify this logic)
          FreeStoreMap(
            store: StoreLocation.stores.first,
            height: 200,
            showDirectionsButton: true,
          ),
          const SizedBox(height: 12),
          // Store list
          ...StoreLocation.stores.map((store) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentRed,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        store.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppLocalizations.of(context).translate('opening_hours')}: ${store.hours}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.directions),
                  onPressed: () => _openGoogleMaps(store),
                  tooltip: AppLocalizations.of(context).translate('directions'),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(StoreLocation store) async {
    final lat = store.latitude;
    final lng = store.longitude;
    
    // Mở Google Maps web trực tiếp
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    final uri = Uri.parse(url);
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppLocalizations.of(context).translate('cannot_open_maps')),
          ),
        );
      }
    }
  }*/

  Widget _buildReviewsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: ReviewsListWidget(
        productId: product!.maSanPham,
        onReply: (review) => showReplyDialog(context, review),
      ),
    );
  }

  // _formatDate not used on this screen

  // ignore: unused_element
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkLoginAndAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEE4D2D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context).addToCart,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
