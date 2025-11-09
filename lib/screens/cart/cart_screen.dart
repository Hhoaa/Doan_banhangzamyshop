import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../models/cart.dart';
import '../../services/supabase_cart_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../utils/currency_formatter.dart';
import '../checkout/checkout_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/ai_chat/bubble_visibility.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Set<int> selectedItems = {};
  double totalAmount = 0.0;
  bool isLoading = true;
  // Ẩn item ngay lập tức sau khi vuốt xoá để tránh lỗi Dismissible
  final Set<int> _hiddenItemIds = {};
  final Map<int, TextEditingController> _quantityControllers = {};

  @override
  void initState() {
    super.initState();
    // Hide AI chat bubble on cart screen to avoid overlapping the buy button
    BubbleVisibility.hide();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    try {
      final user = await SupabaseAuthService.getCurrentUser();
      if (user == null) {
        print('User is null, setting empty cart');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.loadCart();
      // ensure provider loaded

      setState(() {
        isLoading = false;
      });

      // Tính tổng tiền sau khi load
      _calculateTotal();
    } catch (e) {
      print('Error loading cart: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
        );
      }
    }
  }

  void _calculateTotal() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartItems = cartProvider.cart?.cartDetails ?? [];
    double total = 0.0;
    for (var item in cartItems) {
      if (selectedItems.contains(item.maChiTietGioHang)) {
        total += item.giaTienTaiThoiDiemThem * item.soLuong;
        print(
          '[DEBUG] Added to total: ${item.giaTienTaiThoiDiemThem * item.soLuong}',
        );
      }
    }
    print('[DEBUG] Final total: $total');
    setState(() {
      totalAmount = total;
    });
  }

  TextEditingController _controllerForItem(CartDetail item) {
    final existing = _quantityControllers[item.maChiTietGioHang];
    final latestText = item.soLuong.toString();
    if (existing != null) {
      if (existing.text != latestText) {
        existing.value = TextEditingValue(
          text: latestText,
          selection: TextSelection.collapsed(offset: latestText.length),
        );
      }
      return existing;
    }

    final controller = TextEditingController(text: latestText);
    _quantityControllers[item.maChiTietGioHang] = controller;
    return controller;
  }

  void _disposeQuantityController(int detailId) {
    final controller = _quantityControllers.remove(detailId);
    controller?.dispose();
  }

  CartDetail? _getCartDetail(int detailId) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    try {
      return cartProvider.cartDetails.firstWhere(
        (detail) => detail.maChiTietGioHang == detailId,
      );
    } catch (_) {
      return null;
    }
  }

  void _resetQuantityField(int detailId, int quantity) {
    final controller = _quantityControllers[detailId];
    if (controller == null) return;
    final resetText = quantity.toString();
    controller.value = TextEditingValue(
      text: resetText,
      selection: TextSelection.collapsed(offset: resetText.length),
    );
  }

  Future<void> _handleQuantityInput(CartDetail item, String value) async {
    if (!kIsWeb) return;

    final trimmed = value.trim();
    final l10n = AppLocalizations.of(context);
    if (trimmed.isEmpty) {
      _resetQuantityField(item.maChiTietGioHang, item.soLuong);
      return;
    }

    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      final localeCode = l10n.locale.languageCode;
      final message = localeCode == 'vi'
          ? 'Số lượng phải lớn hơn 0'
          : 'Quantity must be greater than 0';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
      _resetQuantityField(item.maChiTietGioHang, item.soLuong);
      return;
    }

    if (parsed == item.soLuong) {
      _resetQuantityField(item.maChiTietGioHang, item.soLuong);
      return;
    }

    await _updateQuantity(item.maChiTietGioHang, parsed);

    final latest = _getCartDetail(item.maChiTietGioHang);
    if (latest != null) {
      _resetQuantityField(latest.maChiTietGioHang, latest.soLuong);
    }
  }

  bool get isAllSelected {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartItems = cartProvider.cart?.cartDetails ?? [];
    return cartItems.isNotEmpty && selectedItems.length == cartItems.length;
  }

  void _toggleSelectAll(bool? value) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartItems = cartProvider.cart?.cartDetails ?? [];

    setState(() {
      if (value == true) {
        selectedItems = cartItems.map((item) => item.maChiTietGioHang).toSet();
      } else {
        selectedItems.clear();
      }
      _calculateTotal();
    });
  }

  void _toggleSelectItem(int itemId) {
    setState(() {
      if (selectedItems.contains(itemId)) {
        selectedItems.remove(itemId);
      } else {
        selectedItems.add(itemId);
      }
    });

    _calculateTotal(); // Đảm bảo tính lại tổng tiền
  }

  Future<void> _updateQuantity(int itemId, int newQuantity) async {
    print(
      '[DEBUG] _updateQuantity called: itemId=$itemId, newQuantity=$newQuantity',
    );
    if (newQuantity <= 0) return;

    // Cập nhật UI ngay lập tức để có trải nghiệm mượt mà
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartItems = cartProvider.cart?.cartDetails ?? [];
    final itemIndex = cartItems.indexWhere(
      (item) => item.maChiTietGioHang == itemId,
    );

    if (itemIndex != -1) {
      // Giới hạn theo tồn kho của biến thể
      final variantStock = cartItems[itemIndex].productVariant?.tonKho ?? 999999;
      if (newQuantity > variantStock) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).translate('low_stock'))),
          );
        }
        return;
      }
      // Cập nhật local state trước
      cartProvider.updateItemQuantity(itemId, newQuantity);
      print('[DEBUG] Updated local state immediately');

      // Tính lại tổng tiền ngay
      _calculateTotal();
    }

    // Sau đó sync với database (background)
    try {
      final user = await SupabaseAuthService.getCurrentUser();
      if (user == null) {
        print('[DEBUG] User is null');
        return;
      }

      print('[DEBUG] Calling SupabaseCartService.updateQuantity...');
      await SupabaseCartService.updateQuantity(
        cartDetailId: itemId,
        quantity: newQuantity,
      );
      print('[DEBUG] SupabaseCartService.updateQuantity successful');

      // Reload cart từ CartProvider để đảm bảo sync
      await cartProvider.loadCart();
      print('[DEBUG] Synced with database');
    } catch (e) {
      print('[DEBUG] Error updating quantity: $e');
      // Revert local changes nếu có lỗi
      await cartProvider.loadCart();
      _calculateTotal();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
      );
    }
  }

  Future<void> _removeItem(int itemId) async {
    print('[DEBUG] _removeItem called: $itemId');
    try {
      final user = await SupabaseAuthService.getCurrentUser();
      if (user == null) {
        print('[DEBUG] User is null');
        return;
      }

      print('[DEBUG] Calling SupabaseCartService.removeFromCart...');
      await SupabaseCartService.removeFromCart(itemId);
      print('[DEBUG] SupabaseCartService.removeFromCart successful');

      // Reload cart từ CartProvider thay vì cập nhật local state
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.loadCart();
      print('[DEBUG] Reloaded cart from CartProvider');

      // Cập nhật local state với delay để tránh conflict với Dismissible
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        setState(() {
          selectedItems.remove(itemId);
          print('[DEBUG] Removed item from selection');
        });

        _disposeQuantityController(itemId);

        _calculateTotal();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('remove_item')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('[DEBUG] Error removing item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
        );
      }
    }
  }

  Future<bool> _confirmDeleteItem() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                    title: Text(AppLocalizations.of(context).translate('confirm_delete')),
                    content: Text(AppLocalizations.of(context).translate('remove_item')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(AppLocalizations.of(context).cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(AppLocalizations.of(context).delete, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          AppLocalizations.of(context).translate('my_cart'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              final items = cartProvider.cartDetails;
              if (items.isNotEmpty) {
                return TextButton(
                  onPressed: () async {
                    final hasSelection = selectedItems.isNotEmpty;
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AppLocalizations.of(context).translate('confirm_delete')),
                        content: Text(AppLocalizations.of(context).translate('remove_item')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(AppLocalizations.of(context).cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(AppLocalizations.of(context).delete),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;

                    final user = await SupabaseAuthService.getCurrentUser();
                    if (user == null) return;

                    try {
                      final idsToRemove = hasSelection
                          ? selectedItems.toSet()
                          : items.map((e) => e.maChiTietGioHang).toSet();

                      if (hasSelection) {
                        await SupabaseCartService.removeSelectedFromCart(user.maNguoiDung, selectedItems);
                        setState(() {
                          _hiddenItemIds.addAll(selectedItems);
                          selectedItems.clear();
                          _calculateTotal();
                        });
                      } else {
                        await SupabaseCartService.clearCart(user.maNguoiDung);
                        setState(() {
                          _hiddenItemIds.addAll(items.map((e) => e.maChiTietGioHang));
                          selectedItems.clear();
                          totalAmount = 0.0;
                        });
                      }

                      for (final id in idsToRemove) {
                        _disposeQuantityController(id);
                      }
                      await cartProvider.loadCart();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Xóa',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Consumer<CartProvider>(
                builder: (context, cartProvider, _) {
                  final sourceItems = cartProvider.cartDetails;
                  final items = sourceItems.where((d) => !_hiddenItemIds.contains(d.maChiTietGioHang)).toList();
                  if (items.isEmpty) {
                    return _buildEmptyCart();
                  }
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: items.length,
                              separatorBuilder:
                                  (context, index) => Container(
                                    height: 8,
                                    color: AppColors.background,
                                  ),
                              itemBuilder: (context, index) {
                                return _buildCartItem(items[index]);
                              },
                            ),
                          ),
                          _buildBottomBar(),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  @override
  void dispose() {
    // Restore chat bubble visibility when leaving cart screen
    BubbleVisibility.show();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _quantityControllers.clear();
    super.dispose();
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).translate('empty_cart'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).translate('cart_empty_message'),
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartDetail item) {
    final isSelected = selectedItems.contains(item.maChiTietGioHang);
    final quantityController = kIsWeb ? _controllerForItem(item) : null;

    return Dismissible(
      key: ValueKey(item.maChiTietGioHang),
      direction: DismissDirection.endToStart,
      resizeDuration: const Duration(milliseconds: 200),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await _confirmDeleteItem();
      },
      onDismissed: (direction) async {
        setState(() {
          _hiddenItemIds.add(item.maChiTietGioHang);
          selectedItems.remove(item.maChiTietGioHang);
        });
        await _removeItem(item.maChiTietGioHang);
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (value) => _toggleSelectItem(item.maChiTietGioHang),
              activeColor: AppColors.accentRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Product Image
            Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child:
                    item.productVariant?.product != null &&
                            item.productVariant!.product!.hinhAnh.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: item.productVariant!.product!.hinhAnh.first,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => const Icon(
                                Icons.image_not_supported,
                                color: AppColors.mediumGray,
                              ),
                        )
                        : const Icon(Icons.image, color: AppColors.mediumGray),
              ),
            ),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    item.productVariant?.product?.tenSanPham ?? 'Sản phẩm',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Variant Info (Size & Color)
                  Row(
                    children: [
                      if (item.productVariant?.color != null)
                        Text(
                          'Phân loại: ${item.productVariant!.color!.tenMau}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (item.productVariant?.size != null) ...[
                        if (item.productVariant?.color != null)
                          const Text(
                            ', ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        Text(
                          item.productVariant!.size!.tenSize,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Price and Quantity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        CurrencyFormatter.formatVND(
                          item.giaTienTaiThoiDiemThem,
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentRed,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.borderLight),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (item.soLuong > 1) {
                                      _updateQuantity(
                                        item.maChiTietGioHang,
                                        item.soLuong - 1,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 16,
                                      color:
                                          item.soLuong > 1
                                              ? AppColors.textSecondary
                                              : AppColors.mediumGray,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: kIsWeb ? 56 : 36,
                                  child: kIsWeb
                                      ? TextField(
                                          controller: quantityController,
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                          ],
                                          onSubmitted: (value) =>
                                              _handleQuantityInput(item, value),
                                          onEditingComplete: () async {
                                            await _handleQuantityInput(
                                              item,
                                              quantityController!.text,
                                            );
                                            if (!mounted) return;
                                            FocusScope.of(context).unfocus();
                                          },
                                        )
                                      : Center(
                                          child: Text(
                                            '${item.soLuong}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                ),
                                InkWell(
                                  onTap: () {
                                    final stock = item.productVariant?.tonKho ?? 999999;
                                    final next = item.soLuong + 1;
                                    if (next > stock) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Chỉ còn $stock sản phẩm trong kho')),
                                      );
                                      return;
                                    }
                                    _updateQuantity(
                                      item.maChiTietGioHang,
                                      next,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (kIsWeb)
                            TextButton.icon(
                              onPressed: () async {
                                final confirmed = await _confirmDeleteItem();
                                if (!confirmed) return;
                                setState(() {
                                  _hiddenItemIds.add(item.maChiTietGioHang);
                                  selectedItems.remove(item.maChiTietGioHang);
                                });
                                _disposeQuantityController(item.maChiTietGioHang);
                                await _removeItem(item.maChiTietGioHang);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                foregroundColor: AppColors.accentRed,
                              ),
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: AppColors.accentRed,
                              ),
                              label: Text(
                                AppLocalizations.of(context).delete,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final selectedCount = selectedItems.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Select All Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Checkbox(
                    value: isAllSelected,
                    onChanged: _toggleSelectAll,
                    activeColor: AppColors.accentRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).translate('all'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Tổng thanh toán:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatVND(totalAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed:
                        selectedCount > 0
                            ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutScreen(
                                    selectedCartDetailIds: selectedItems,
                                  ),
                                ),
                              );
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRed,
                      disabledBackgroundColor: AppColors.mediumGray,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      AppLocalizations.of(context).translate('place_order') + ' ($selectedCount)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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
}
