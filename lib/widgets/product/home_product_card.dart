import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../l10n/app_localizations.dart';

class HomeProductCard extends StatelessWidget {
  final Product product;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;
  final bool isFavorite;
  final double rating;
  final int reviewCount;

  const HomeProductCard({
    super.key,
    required this.product,
    this.imageUrl,
    this.onTap,
    this.onFavorite,
    this.onAddToCart,
    this.onBuyNow,
    this.isFavorite = false,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final displayImage =
        imageUrl ?? (product.hinhAnh.isNotEmpty ? product.hinhAnh.first : '');
    final bool showActions = onAddToCart != null || onBuyNow != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image section
            AspectRatio(
              aspectRatio: kIsWeb ? 1.15 : 3 / 4,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child:
                        displayImage.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: displayImage,
                              width: double.infinity,
                              height: double.infinity,
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
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: AppColors.textSecondary,
                                      size: 40,
                                    ),
                                  ),
                            )
                            : Container(
                              color: AppColors.lightGray.withOpacity(0.3),
                              child: const Icon(
                                Icons.image,
                                color: AppColors.textSecondary,
                                size: 40,
                              ),
                            ),
                  ),

                  // Favorite button
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
                            size: 16,
                          ),
                        ),
                      ),
                    ),

                  // Discount badge
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
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content section
            Padding(
              padding: EdgeInsets.fromLTRB(8, kIsWeb ? 6 : 4, 8, kIsWeb ? 6 : 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product name
                  Text(
                    product.tenSanPham,
                    style: TextStyle(
                      fontSize: kIsWeb ? 12 : 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: kIsWeb ? 1.15 : 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (rating > 0 || !kIsWeb) SizedBox(height: kIsWeb ? 3 : 1),

                  // Rating
                  if (rating > 0)
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: kIsWeb ? 11 : 8),
                        SizedBox(width: kIsWeb ? 2 : 1),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: kIsWeb ? 10 : 7,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: kIsWeb ? 2 : 1),
                        Text(
                          '($reviewCount)',
                          style: TextStyle(
                            fontSize: kIsWeb ? 9 : 6,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: kIsWeb ? 6 : 2),

                  // Price
                  Text(
                    CurrencyFormatter.formatVND(product.giaBan),
                    style: TextStyle(
                      fontSize: kIsWeb ? 13 : 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentRed,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Original price
                  if (product.mucGiaGoc > product.giaBan)
                    Padding(
                      padding: EdgeInsets.only(top: kIsWeb ? 1 : 0),
                      child: Text(
                        CurrencyFormatter.formatVND(product.mucGiaGoc),
                        style: TextStyle(
                          fontSize: kIsWeb ? 9 : 6,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  if (showActions) ...[
                    SizedBox(height: kIsWeb ? 6 : 2),
                    // Action buttons
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Nếu card quá nhỏ, hiển thị dạng cột
                        if (constraints.maxWidth < 150) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (onAddToCart != null)
                                SizedBox(
                                  width: double.infinity,
                                  height: kIsWeb ? 28 : 22,
                                  child: ElevatedButton(
                                    onPressed: onAddToCart,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentRed,
                                      padding: EdgeInsets.symmetric(
                                        vertical: kIsWeb ? 4 : 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        AppLocalizations.of(context).addToCart,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: kIsWeb ? 10 : 8,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (onAddToCart != null && onBuyNow != null)
                                SizedBox(height: kIsWeb ? 4 : 2),
                              if (onBuyNow != null)
                                SizedBox(
                                  width: double.infinity,
                                  height: kIsWeb ? 28 : 22,
                                  child: OutlinedButton(
                                    onPressed: onBuyNow,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.accentRed,
                                      side: const BorderSide(
                                        color: AppColors.accentRed,
                                        width: 1,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: kIsWeb ? 4 : 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        AppLocalizations.of(context).buyNow,
                                        style: TextStyle(
                                          fontSize: kIsWeb ? 10 : 8,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }

                        // Hiển thị dạng hàng ngang
                        return Row(
                          children: [
                            if (onAddToCart != null)
                              Expanded(
                                child: SizedBox(
                                  height: kIsWeb ? 28 : 22,
                                  child: ElevatedButton(
                                    onPressed: onAddToCart,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentRed,
                                      padding: EdgeInsets.symmetric(
                                        vertical: kIsWeb ? 4 : 1,
                                        horizontal: 4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        AppLocalizations.of(context).addToCart,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: kIsWeb ? 10 : 8,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (onAddToCart != null && onBuyNow != null)
                              SizedBox(width: kIsWeb ? 4 : 2),
                            if (onBuyNow != null)
                              Expanded(
                                child: SizedBox(
                                  height: kIsWeb ? 28 : 22,
                                  child: OutlinedButton(
                                    onPressed: onBuyNow,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.accentRed,
                                      side: const BorderSide(
                                        color: AppColors.accentRed,
                                        width: 1,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: kIsWeb ? 4 : 1,
                                        horizontal: 4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        AppLocalizations.of(context).buyNow,
                                        style: TextStyle(
                                          fontSize: kIsWeb ? 10 : 8,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
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
