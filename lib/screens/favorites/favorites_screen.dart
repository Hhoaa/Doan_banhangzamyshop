import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../models/product.dart';
import '../../services/supabase_favorite_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../screens/product/product_detail_screen.dart';
import '../../widgets/product/product_options_bottom_sheet.dart';
import 'package:provider/provider.dart';
import '../../navigation/home_tabs.dart';
import '../../navigation/navigator_key.dart';
import '../main/main_screen.dart';
import '../main/main_web_screen.dart';
import '../../providers/web_ui_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/web/web_page_wrapper.dart';
import '../../l10n/app_localizations.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Product> favoriteProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteProducts();
  }

  Future<void> _loadFavoriteProducts() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final products = await SupabaseFavoriteService.getFavoriteProducts(authProvider.user!.maNguoiDung);
        setState(() {
          favoriteProducts = products;
          isLoading = false;
        });
        if (mounted) {
          context.read<FavoritesProvider>().syncFavorites(
                authProvider.user!.maNguoiDung,
                products.map((p) => p.maSanPham),
              );
        }
      } else {
        setState(() {
          favoriteProducts = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).error}: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _removeFromFavorites(Product product) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final favoritesProvider = context.read<FavoritesProvider>();
        final removed = await favoritesProvider.remove(
          authProvider.user!.maNguoiDung,
          product.maSanPham,
        );

        if (removed) {
          setState(() {
            favoriteProducts.removeWhere((p) => p.maSanPham == product.maSanPham);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).translate('removed_from_favorites_success')),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).translate('remove_from_favorites')), // fallback message
                backgroundColor: AppColors.accentRed,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).error}: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(productId: product.maSanPham),
      ),
    );
  }

  void _showProductOptionsBottomSheet(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductOptionsBottomSheet(
        product: product,
        onAddedToCart: () {
          // Có thể reload favorites hoặc làm gì đó sau khi thêm vào giỏ
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm vào giỏ hàng'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: AppLocalizations.of(context).favorites,
        actions: [
          if (favoriteProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${favoriteProducts.length} ' + AppLocalizations.of(context).translate('products'),
                    style: const TextStyle(
                      color: AppColors.accentRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentRed))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: favoriteProducts.isEmpty
                    ? _buildEmptyFavorites()
                    : _buildFavoritesList(),
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

  Widget _buildEmptyFavorites() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accentRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 80,
              color: AppColors.accentRed,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).translate('no_favorites'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              AppLocalizations.of(context).translate('no_favorites_subtitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              debugPrint('[FavoritesScreen] Continue shopping tapped');
              if (kIsWeb) {
                // Chuyển về web main và mở tab Sản phẩm
                try {
                  // ignore: use_build_context_synchronously
                  context.read<WebUiProvider>().goToTab(1);
                } catch (_) {}
                AppNavigator.navigator?.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainWebScreen()),
                  (route) => false,
                );
              } else {
                HomeTabs.setPendingIndex(1);
                AppNavigator.navigator?.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text(AppLocalizations.of(context).translate('continue_shopping')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favoriteProducts.length,
      itemBuilder: (context, index) {
        return _buildFavoriteItem(favoriteProducts[index]);
      },
    );
  }

  Widget _buildFavoriteItem(Product product) {
    final card = _buildFavoriteCard(product, showRemoveButton: kIsWeb);

    if (kIsWeb) {
      return card;
    }

    return Dismissible(
      key: Key(product.maSanPham.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _removeFromFavorites(product);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.accentRed,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).delete,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      child: card,
    );
  }

  Widget _buildFavoriteCard(Product product, {required bool showRemoveButton}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToProductDetail(product),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'product_${product.maSanPham}',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: product.hinhAnh.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.hinhAnh.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.accentRed,
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.image_not_supported,
                                color: AppColors.textSecondary,
                                size: 40,
                              ),
                            )
                          : const Icon(
                              Icons.image_outlined,
                              color: AppColors.textSecondary,
                              size: 40,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.tenSanPham,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.formatVND(product.giaBan),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentRed,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (product.mucGiaGoc > product.giaBan)
                            Text(
                              CurrencyFormatter.formatVND(product.mucGiaGoc),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (showRemoveButton)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showProductOptionsBottomSheet(product),
                                icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                                label: Text(AppLocalizations.of(context).addToCart),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.accentRed,
                                  side: const BorderSide(color: AppColors.accentRed),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _removeFromFavorites(product),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: Text(AppLocalizations.of(context).translate('remove_from_favorites')),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showProductOptionsBottomSheet(product),
                            icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                            label: Text(AppLocalizations.of(context).addToCart),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accentRed,
                              side: const BorderSide(color: AppColors.accentRed),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}