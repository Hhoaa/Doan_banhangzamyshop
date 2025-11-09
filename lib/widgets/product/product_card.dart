import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../common/rating_stars.dart';
import '../../l10n/app_localizations.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow; // Callback cho nút mua ngay
  final bool isFavorite;
  final double? width;
  final double? minHeight;
  final double rating;
  final int reviewCount;

  const ProductCard({
    super.key,
    required this.product,
    this.imageUrl,
    this.onTap,
    this.onFavorite,
    this.onAddToCart,
    this.onBuyNow,
    this.isFavorite = false,
    this.width,
    this.minHeight,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool showActions = onAddToCart != null || onBuyNow != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: kIsWeb ? 1.15 : 3 / 4,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl:
                            imageUrl ??
                            (product.hinhAnh.isNotEmpty
                                ? product.hinhAnh.first
                                : ''),
                        fit: BoxFit.contain,
                        placeholder:
                            (context, url) => Container(
                              color: AppColors.lightGray.withOpacity(0.3),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.accentRed,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: AppColors.lightGray.withOpacity(0.3),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported,
                                      color: AppColors.textSecondary,
                                      size: 40,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Không có hình ảnh',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                  if (onFavorite != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color:
                                isFavorite
                                    ? AppColors.accentRed
                                    : AppColors.textSecondary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  if (product.mucGiaGoc > product.giaBan)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${((product.mucGiaGoc - product.giaBan) / product.mucGiaGoc * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                kIsWeb ? 6 : 8,
                kIsWeb ? 6 : 3,
                kIsWeb ? 6 : 8,
                showActions ? 0 : (kIsWeb ? 6 : 3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.tenSanPham,
                    style: TextStyle(
                      fontSize: kIsWeb ? 12 : 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: kIsWeb ? 1.1 : 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: kIsWeb ? 2 : 1),
                  Row(
                    children: [
                      RatingStars(
                        rating: rating.clamp(0.0, 5.0),
                        itemSize: kIsWeb ? 9 : 7,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '($reviewCount)',
                        style: TextStyle(
                          fontSize: kIsWeb ? 8 : 6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: kIsWeb ? 3 : 1),
                  Text(
                    CurrencyFormatter.formatVND(product.giaBan),
                    style: TextStyle(
                      fontSize: kIsWeb ? 13 : 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentRed,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.mucGiaGoc > product.giaBan) ...[
                    Padding(
                      padding: EdgeInsets.only(top: kIsWeb ? 1 : 0),
                      child: Text(
                        CurrencyFormatter.formatVND(product.mucGiaGoc),
                        style: TextStyle(
                          fontSize: kIsWeb ? 9 : 6,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (showActions) ...[
                    SizedBox(height: kIsWeb ? 5 : 1),
                    Padding(
                      padding: EdgeInsets.only(bottom: kIsWeb ? 6 : 3),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final narrow = constraints.maxWidth < 180;
                          final buttonPadding = EdgeInsets.symmetric(
                            vertical: kIsWeb ? 4 : 2,
                          );
                          final textStyle = TextStyle(
                            fontSize: kIsWeb ? 11 : 9,
                            fontWeight: FontWeight.w600,
                          );
                          final addToCartChild = FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppLocalizations.of(context).addToCart,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: kIsWeb ? 11 : 9,
                              ),
                            ),
                          );
                          final buyNowChild = FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppLocalizations.of(context).buyNow,
                              style: textStyle,
                            ),
                          );
                          if (narrow) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (onAddToCart != null)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: onAddToCart,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accentRed,
                                        padding: buttonPadding,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: addToCartChild,
                                    ),
                                  ),
                                if (onAddToCart != null && onBuyNow != null)
                                  SizedBox(height: kIsWeb ? 4 : 2),
                                if (onBuyNow != null)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: onBuyNow,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.accentRed,
                                        side: const BorderSide(
                                          color: AppColors.accentRed,
                                        ),
                                        padding: buttonPadding,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      child: buyNowChild,
                                    ),
                                  ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              if (onAddToCart != null)
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: onAddToCart,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentRed,
                                      padding: buttonPadding,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: addToCartChild,
                                  ),
                                ),
                              if (onAddToCart != null && onBuyNow != null)
                                const SizedBox(width: 6),
                              if (onBuyNow != null)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: onBuyNow,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.accentRed,
                                      side: const BorderSide(
                                        color: AppColors.accentRed,
                                      ),
                                      padding: buttonPadding,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: buyNowChild,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
