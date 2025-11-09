import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../theme/app_colors.dart';
import '../../models/product.dart';
import '../../models/product_variant.dart';
import '../../models/size.dart';
import '../../models/color.dart';
import '../../services/supabase_variant_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/web/auth_combined_web_screen.dart';
import '../../screens/checkout/checkout_screen.dart';
import '../../l10n/app_localizations.dart';

class ProductOptionsBottomSheet extends StatefulWidget {
  final Product product;
  final VoidCallback? onAddedToCart;
  final bool isBuyNow; // Mode mua ngay
  final VoidCallback? onBuyNow; // Callback khi mua ngay

  const ProductOptionsBottomSheet({
    super.key,
    required this.product,
    this.onAddedToCart,
    this.isBuyNow = false,
    this.onBuyNow,
  });

  @override
  State<ProductOptionsBottomSheet> createState() =>
      _ProductOptionsBottomSheetState();
}

class _ProductOptionsBottomSheetState extends State<ProductOptionsBottomSheet> {
  List<Size> sizes = [];
  List<ColorModel> colors = [];
  List<ProductVariant> variants = [];
  bool isLoading = true;

  // Selected variants
  int? selectedSizeId;
  int? selectedColorId;
  int quantity = 1;
  late TextEditingController _quantityController;
  bool _isUpdatingQuantityText = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: quantity.toString());
    _quantityController.addListener(_handleQuantityTextChange);
    _loadVariantsAndOptions();
  }

  @override
  void dispose() {
    _quantityController.removeListener(_handleQuantityTextChange);
    _quantityController.dispose();
    super.dispose();
  }

  void _handleQuantityTextChange() {
    if (_isUpdatingQuantityText) return;
    // Cho phép text rỗng khi đang xóa
    if (_quantityController.text.isEmpty) {
      return;
    }
    final parsed = int.tryParse(_quantityController.text);
    final maxQuantity = _getAvailableStock() > 0 ? _getAvailableStock() : 999;

    int newQuantity;
    if (parsed == null || parsed <= 0) {
      // Không tự động set về 1 khi đang nhập, chỉ validate khi submit
      return;
    } else if (parsed > maxQuantity) {
      newQuantity = maxQuantity;
    } else {
      newQuantity = parsed;
    }

    if (newQuantity != quantity) {
      setState(() {
        quantity = newQuantity;
      });
    }

    // Chỉ update controller nếu vượt quá max
    if (parsed > maxQuantity) {
      _updateQuantityController(newQuantity);
    }
  }

  void _updateQuantityController(int value) {
    _isUpdatingQuantityText = true;
    final text = value.toString();
    _quantityController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _isUpdatingQuantityText = false;
  }

  void _setQuantity(int value) {
    final maxQuantity = _getAvailableStock() > 0 ? _getAvailableStock() : 999;
    final clamped = value.clamp(1, maxQuantity);
    if (clamped != quantity) {
      setState(() {
        quantity = clamped;
      });
    }
    _updateQuantityController(clamped);
  }

  Future<void> _loadVariantsAndOptions() async {
    try {
      final futures = await Future.wait([
        //SupabaseVariantService.getSizes(),
        SupabaseVariantService.getSizesForProduct(widget.product.maSanPham),
        //  SupabaseVariantService.getColors(),
        SupabaseVariantService.getColorsForProduct(widget.product.maSanPham),
        SupabaseVariantService.getProductVariants(widget.product.maSanPham),
      ]);

      setState(() {
        sizes = futures[0] as List<Size>;
        colors = futures[1] as List<ColorModel>;
        variants = futures[2] as List<ProductVariant>;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading variants: $e');
      setState(() => isLoading = false);
    }
  }

  // Lấy variant đã chọn
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

  // Lấy số lượng tồn kho
  int _getAvailableStock() {
    final variant = _getSelectedVariant();
    return variant?.tonKho ?? 0;
  }

  Future<void> _addToCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. Kiểm tra đăng nhập
    if (authProvider.user == null) {
      _showLoginDialog();
      return;
    }

    // 2. Kiểm tra đã chọn size và màu
    final l10n = AppLocalizations.of(context);
    if (selectedSizeId == null || selectedColorId == null) {
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

    // 3. Kiểm tra tồn kho
    final selectedVariant = _getSelectedVariant();

    if (selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy sản phẩm với size và màu đã chọn'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    if (selectedVariant.tonKho <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sản phẩm này hiện đã hết hàng'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    int existingQuantityInCart = 0;
    try {
      final existingDetail = cartProvider.cartDetails.firstWhere(
        (detail) =>
            detail.productVariant?.product?.maSanPham ==
                widget.product.maSanPham &&
            detail.productVariant?.maSize == selectedSizeId &&
            detail.productVariant?.maMau == selectedColorId,
      );
      existingQuantityInCart = existingDetail.soLuong;
    } catch (_) {}

    final int totalRequested = existingQuantityInCart + quantity;
    if (totalRequested > selectedVariant.tonKho) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Số lượng sản phẩm này trong giỏ hàng đã vượt quá số lượng tồn kho',
          ),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    // 4. Thêm vào giỏ hàng (kèm xác thực tồn kho lần nữa cho Buy Now)

    // Pre-check nhanh cho Buy Now theo dữ liệu đang hiển thị
    if (widget.isBuyNow) {
      final available = _getAvailableStock();
      if (available <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sản phẩm này hiện đã hết hàng'),
            backgroundColor: AppColors.accentRed,
          ),
        );
        return;
      }
      if (quantity > available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chỉ còn $available sản phẩm trong kho'),
            backgroundColor: AppColors.accentRed,
          ),
        );
        return;
      }
    }

    // Nếu là Buy Now, xác thực tồn kho lại từ server để tránh dữ liệu cũ
    if (widget.isBuyNow) {
      try {
        final latestVariants = await SupabaseVariantService.getProductVariants(
          widget.product.maSanPham,
        );
        final latestSelected = latestVariants.firstWhere(
          (v) => v.maSize == selectedSizeId && v.maMau == selectedColorId,
        );
        if (latestSelected.tonKho <= 0) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sản phẩm này hiện đã hết hàng'),
              backgroundColor: AppColors.accentRed,
            ),
          );
          return;
        }
        if (quantity > latestSelected.tonKho) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Chỉ còn ${latestSelected.tonKho} sản phẩm trong kho',
              ),
              backgroundColor: AppColors.accentRed,
            ),
          );
          return;
        }
      } catch (_) {
        // Nếu có lỗi khi xác thực, vẫn tiếp tục nhưng đã có check phía trên UI
      }
    }

    final success = await cartProvider.addToCart(
      widget.product,
      selectedSizeId!,
      selectedColorId!,
      quantity,
    );

    if (!mounted) return;

    final errorMessage = cartProvider.lastErrorMessage;

    if (!success) {
      Navigator.of(context).pop(); // Close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage != null
                ? _humanizeError(errorMessage)
                : 'Lỗi khi thêm vào giỏ hàng',
          ),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    // Nếu là mode mua ngay, điều hướng đến checkout
    if (widget.isBuyNow) {
      try {
        // Đợi một chút để đảm bảo database đã cập nhật
        await Future.delayed(const Duration(milliseconds: 200));

        // Load lại cart để lấy dữ liệu mới nhất
        await cartProvider.loadCart();
        final cartDetails = cartProvider.cartDetails;

        if (cartDetails.isEmpty) {
          if (mounted) {
            Navigator.of(context).pop(); // Close bottom sheet
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Không tìm thấy sản phẩm trong giỏ hàng. Vui lòng thử lại.',
                ),
                backgroundColor: AppColors.accentRed,
              ),
            );
          }
          return;
        }

        // Tìm cart detail vừa thêm - tìm theo variant ID
        CartDetail? newCartDetail;

        // Ưu tiên: Tìm theo variant ID (chính xác nhất)
        try {
          newCartDetail = cartDetails.firstWhere(
            (detail) => detail.maBienTheSanPham == selectedVariant.maBienThe,
          );
          print(
            '✅ Found cart detail by variant ID: ${newCartDetail.maChiTietGioHang}',
          );
        } catch (e) {
          print('⚠️ Not found by variant ID, trying by product/size/color...');
          // Nếu không tìm thấy, thử tìm theo product ID, size và color
          try {
            newCartDetail = cartDetails.firstWhere(
              (detail) =>
                  detail.productVariant?.product?.maSanPham ==
                      widget.product.maSanPham &&
                  detail.productVariant?.maSize == selectedSizeId &&
                  detail.productVariant?.maMau == selectedColorId,
            );
            print(
              '✅ Found cart detail by product/size/color: ${newCartDetail.maChiTietGioHang}',
            );
          } catch (e2) {
            print('⚠️ Not found by product/size/color, using fallback...');
            // Fallback: Sắp xếp theo ID và lấy item có ID lớn nhất (mới nhất)
            if (cartDetails.isNotEmpty) {
              final sortedDetails = List<CartDetail>.from(cartDetails);
              sortedDetails.sort(
                (a, b) => b.maChiTietGioHang.compareTo(a.maChiTietGioHang),
              );
              newCartDetail = sortedDetails.first;
              print(
                '✅ Using fallback - newest cart detail: ${newCartDetail.maChiTietGioHang}',
              );
            }
          }
        }

        // Điều hướng đến checkout với cart detail ID đã chọn
        if (newCartDetail != null && mounted) {
          print(
            '✅ Navigating to checkout with cart detail ID: ${newCartDetail.maChiTietGioHang}',
          );

          // Lưu cart detail ID và parent navigator trước khi đóng bottom sheet
          final cartDetailId = newCartDetail.maChiTietGioHang;
          final parentNavigator = Navigator.of(context, rootNavigator: false);

          // Đóng bottom sheet
          Navigator.of(context).pop();

          // Sử dụng WidgetsBinding để đảm bảo navigation được thực hiện sau khi bottom sheet đóng
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              parentNavigator.push(
                MaterialPageRoute(
                  builder:
                      (context) =>
                          CheckoutScreen(selectedCartDetailIds: {cartDetailId}),
                ),
              );
              print('✅ Successfully navigated to checkout');
              widget.onBuyNow?.call();
            } catch (e) {
              print('❌ ERROR: Navigator push failed: $e');
            }
          });
        } else {
          print('❌ ERROR: newCartDetail is null or widget not mounted!');
          if (mounted) {
            Navigator.of(context).pop(); // Close bottom sheet
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Không tìm thấy sản phẩm trong giỏ hàng. Vui lòng thử lại.',
                ),
                backgroundColor: AppColors.accentRed,
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        print('❌ ERROR navigating to checkout: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          Navigator.of(context).pop(); // Close bottom sheet on error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi điều hướng đến thanh toán: $e'),
              backgroundColor: AppColors.accentRed,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } else {
      // Mode thêm vào giỏ hàng bình thường
      final l10n = AppLocalizations.of(context);
      Navigator.of(context).pop(); // Close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('added_to_cart')),
          backgroundColor: Colors.green,
        ),
      );
      widget.onAddedToCart?.call();
    }
  }

  String _humanizeError(String raw) {
    // Strip generic Exception prefix if present
    final cleaned = raw.replaceFirst(RegExp(r'^Exception: '), '');
    // Known messages from service
    if (cleaned.contains('tối đa theo tồn kho') ||
        cleaned.contains('vượt quá tồn kho')) {
      return 'Số lượng sản phẩm này trong giỏ hàng đã vượt quá số lượng tồn kho';
    }
    return 'Lỗi khi thêm vào giỏ hàng: $cleaned';
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

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Đăng nhập'),
            content: const Text('Bạn cần đăng nhập để thực hiện chức năng này'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(); // close bottom sheet
                  // Navigate to login screen (web vs mobile)
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
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableStock = _getAvailableStock();

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.tenSanPham,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₫${widget.product.giaBan.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppColors.accentRed),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Size Selection
                      if (sizes.isNotEmpty) ...[
                        Text(
                          AppLocalizations.of(context).size,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              sizes.map((size) {
                                final isSelected =
                                    selectedSizeId == size.maSize;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedSizeId = size.maSize;
                                    });
                                    _setQuantity(1);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? AppColors.accentRed
                                              : Colors.white,
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? AppColors.accentRed
                                                : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      size.tenSize,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Color Selection
                      if (colors.isNotEmpty) ...[
                        Text(
                          AppLocalizations.of(context).color,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              colors.map((color) {
                                final isSelected =
                                    selectedColorId == color.maMau;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedColorId = color.maMau;
                                    });
                                    _setQuantity(1);
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
                                        width: isSelected ? 2.5 : 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Hiển thị màu thật (Circle)
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: _parseColorFromHex(
                                              color.maMauHex,
                                            ),
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
                                            color: AppColors.textPrimary,
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
                        const SizedBox(height: 24),
                      ],

                      // Stock Info - THÊM MỚI
                      if (selectedSizeId != null &&
                          selectedColorId != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                availableStock > 0
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  availableStock > 0
                                      ? Colors.green.shade200
                                      : Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                availableStock > 0
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 18,
                                color:
                                    availableStock > 0
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                availableStock > 0
                                    ? 'Còn hàng: $availableStock sản phẩm'
                                    : 'Hết hàng',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      availableStock > 0
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Quantity - CẬP NHẬT
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context).quantity,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed:
                                      quantity > 1
                                          ? () => _setQuantity(quantity - 1)
                                          : null,
                                  icon: const Icon(Icons.remove, size: 18),
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                ),
                                // TextField cho web, Text cho mobile
                                SizedBox(
                                  width: 80,
                                  height: 40,
                                  child: TextField(
                                    controller: _quantityController,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      _MaxValueFormatter(
                                        max:
                                            availableStock > 0
                                                ? availableStock
                                                : 999,
                                      ),
                                    ],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                    ),
                                    onTap: () {
                                      // Select all text when tapped for easy replacement
                                      _quantityController.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: _quantityController.text.length,
                                      );
                                    },
                                    onSubmitted: (value) {
                                      final parsed = int.tryParse(value);
                                      if (parsed == null || parsed <= 0) {
                                        _setQuantity(1);
                                      } else {
                                        _setQuantity(parsed);
                                      }
                                    },
                                    onEditingComplete: () {
                                      final parsed = int.tryParse(_quantityController.text);
                                      if (parsed == null || parsed <= 0) {
                                        _setQuantity(1);
                                      } else {
                                        _setQuantity(parsed);
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  // Giới hạn quantity không vượt quá tồn kho
                                  onPressed:
                                      (availableStock > 0 &&
                                              quantity < availableStock)
                                          ? () => _setQuantity(quantity + 1)
                                          : null,
                                  icon: const Icon(Icons.add, size: 18),
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const Divider(height: 1),

            // Add to Cart Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (isLoading || availableStock <= 0) ? null : _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRed,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLoading
                        ? AppLocalizations.of(context).loading
                        : (selectedSizeId != null &&
                            selectedColorId != null &&
                            availableStock <= 0)
                        ? AppLocalizations.of(context).translate('out_of_stock')
                        : widget.isBuyNow
                        ? AppLocalizations.of(context).buyNow
                        : AppLocalizations.of(context).addToCart,
                    style: TextStyle(
                      color:
                          (isLoading || availableStock <= 0)
                              ? Colors.grey.shade600
                              : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaxValueFormatter extends TextInputFormatter {
  final int max;
  const _MaxValueFormatter({required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Cho phép text rỗng để có thể xóa
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Chỉ cho phép số
    if (!RegExp(r'^\d+$').hasMatch(newValue.text)) {
      return oldValue;
    }
    
    final parsed = int.tryParse(newValue.text);
    if (parsed == null) {
      return oldValue;
    }
    
    // Chỉ giới hạn max, không tự động set min khi đang nhập
    if (parsed > max) {
      final text = max.toString();
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    
    // Cho phép mọi giá trị hợp lệ (kể cả < 1) khi đang nhập
    return newValue;
  }
}
