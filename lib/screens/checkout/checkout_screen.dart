import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/currency_formatter.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/phone_check_dialog.dart';
import '../../services/supabase_order_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/supabase_cart_service.dart';
import '../../services/supabase_discount_service.dart';
import '../../services/vnpay_service.dart';
import '../../config/supabase_config.dart';
import '../../services/supabase_payment_service.dart';
import '../../models/payment_method.dart';
import '../order/order_screen.dart';
import '../address/address_selection_screen.dart';
import '../address/add_edit_address_screen.dart';
import '../../models/cart.dart';
import '../../models/user_address.dart';
import '../../l10n/app_localizations.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, this.selectedCartDetailIds});

  final Set<int>? selectedCartDetailIds;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'COD'; // Mặc định COD
  final TextEditingController _notesController = TextEditingController();
  UserAddress? _selectedAddress;
  String? _selectedDiscountId;
  Map<String, dynamic>? _selectedDiscount;
  List<Map<String, dynamic>> _availableDiscounts = [];
  bool _submitting = false;
  bool _loadingDiscounts = false;

  // Payment methods từ settings
  List<PaymentMethod> _availablePaymentMethods = [];
  bool _loadingPaymentMethods = true;

  // Helper: lấy danh sách cart details nguồn theo lựa chọn
  List<CartDetail> _getSourceDetails(CartProvider cart) {
    final all = cart.cartDetails;
    final ids = widget.selectedCartDetailIds;
    if (ids == null || ids.isEmpty) return all;
    return all.where((d) => ids.contains(d.maChiTietGioHang)).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _loadDiscounts();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      setState(() => _loadingPaymentMethods = true);
      final methods = await SupabasePaymentService.getActivePaymentMethods();
      if (methods.isNotEmpty) {
        setState(() {
          _availablePaymentMethods = methods;
          // Set payment method mặc định là phương thức đầu tiên được kích hoạt
          _paymentMethod = methods.first.maPhuongThuc;
        });
      }
    } catch (e) {
      print('Error loading payment methods: $e');
      // Fallback về COD nếu có lỗi
      setState(() {
        _availablePaymentMethods = [];
        _paymentMethod = 'COD';
      });
    } finally {
      setState(() => _loadingPaymentMethods = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );

    if (authProvider.user != null) {
      await addressProvider.fetchAddresses(authProvider.user!.maNguoiDung);

      if (addressProvider.addresses.isNotEmpty) {
        final defaultAddress = addressProvider.addresses.firstWhere(
          (addr) => addr.isDefault,
          orElse: () => addressProvider.addresses.first,
        );
        setState(() {
          _selectedAddress = defaultAddress;
        });
      }
    }
  }

  String? _validateDiscount(Map<String, dynamic> discount, double orderAmount) {
    final minOrder = discount['don_gia_toi_thieu'] as num?;
    if (minOrder != null && orderAmount < minOrder.toDouble()) {
      return 'Đơn hàng chưa đạt giá trị tối thiểu ${CurrencyFormatter.formatVND(minOrder.toDouble())}';
    }

    final totalQuantity = discount['so_luong_ban_dau'] as int? ?? 0;
    final usedQuantity = discount['so_luong_da_dung'] as int? ?? 0;
    if (totalQuantity > 0 && usedQuantity >= totalQuantity) {
      return 'Mã giảm giá đã hết lượt sử dụng';
    }

    final startDate = discount['ngay_bat_dau'] as String?;
    final endDate = discount['ngay_ket_thuc'] as String?;
    final now = DateTime.now();

    if (startDate != null) {
      final start = DateTime.parse(startDate);
      if (now.isBefore(start)) {
        return 'Mã giảm giá chưa có hiệu lực';
      }
    }

    if (endDate != null) {
      final end = DateTime.parse(endDate);
      if (now.isAfter(end)) {
        return 'Mã giảm giá đã hết hạn';
      }
    }

    return null;
  }

  double _calculateDiscountAmount(double orderAmount) {
    if (_selectedDiscount == null) return 0.0;

    final validationError = _validateDiscount(_selectedDiscount!, orderAmount);
    if (validationError != null) return 0.0;

    final discountType = _selectedDiscount!['loai_giam_gia'] as String;
    final discountValue =
        (_selectedDiscount!['muc_giam_gia'] as num).toDouble();

    if (discountType == 'percentage') {
      return (orderAmount * discountValue / 100).roundToDouble();
    } else if (discountType == 'fixed') {
      return discountValue > orderAmount ? orderAmount : discountValue;
    }
    return 0.0;
  }

  double _calculateTotalAfterDiscount(double orderAmount) {
    final discountAmount = _calculateDiscountAmount(orderAmount);
    return orderAmount - discountAmount;
  }

  Future<void> _placeOrder() async {
    print('[DEBUG] Bắt đầu đặt đơn hàng...');
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('please_select_address'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (auth.user == null || cartProvider.cartDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('empty_cart')),
        ),
      );
      return;
    }

    // Kiểm tra số điện thoại trước khi đặt hàng
    final userPhone = auth.user!.soDienThoai;
    if (userPhone == null ||
        userPhone.isEmpty ||
        !PhoneChecker.isValidPhone(userPhone)) {
      // Hiển thị popup yêu cầu cập nhật số điện thoại
      final result = await PhoneCheckDialog.show(
        context,
        auth.user!.maNguoiDung,
        onPhoneUpdated: () {
          // Reload user sau khi cập nhật
          auth.refreshUser();
        },
      );

      // Nếu người dùng không cập nhật số điện thoại, không cho đặt hàng
      if (result != true) {
        return;
      }

      // Reload lại user để lấy số điện thoại mới
      await auth.refreshUser();

      // Kiểm tra lại
      final updatedUser = auth.user;
      if (updatedUser?.soDienThoai == null ||
          updatedUser!.soDienThoai!.isEmpty ||
          !PhoneChecker.isValidPhone(updatedUser.soDienThoai)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                      context,
                    ).translate('phone_required_for_order') ??
                    'Vui lòng cập nhật số điện thoại để đặt hàng',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    try {
      setState(() => _submitting = true);

      final userId = auth.user!.maNguoiDung;
      final source = _getSourceDetails(cartProvider);
      if (source.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn sản phẩm để đặt hàng')),
        );
        return;
      }

      final mergedDetails = <int, CartDetail>{};
      for (final d in source) {
        final key = d.maBienTheSanPham;
        if (mergedDetails.containsKey(key)) {
          final old = mergedDetails[key]!;
          mergedDetails[key] = CartDetail(
            maChiTietGioHang: old.maChiTietGioHang,
            maGioHang: old.maGioHang,
            maBienTheSanPham: old.maBienTheSanPham,
            soLuong: old.soLuong + d.soLuong,
            giaTienTaiThoiDiemThem: old.giaTienTaiThoiDiemThem,
            productVariant: old.productVariant,
          );
        } else {
          mergedDetails[key] = d;
        }
      }
      final details = mergedDetails.values.toList();
      final total = details.fold<double>(
        0.0,
        (s, it) => s + it.giaTienTaiThoiDiemThem * it.soLuong,
      );

      final isStockOk = await _validateStock(details);
      if (!isStockOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('low_stock')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      double finalTotal = total;
      if (_selectedDiscount != null) {
        final validationError = _validateDiscount(_selectedDiscount!, total);
        if (validationError == null) {
          final discountAmount = _calculateDiscountAmount(total);
          finalTotal = total - discountAmount;
        }
      }

      // XÁC ĐỊNH HÌNH THỨC THANH TOÁN
      final hinhThucThanhToan =
          _paymentMethod == 'VNPay' ? 'vnpay' : 'tien_mat';

      print('[DEBUG] Thông tin đơn hàng:');
      print('   - User ID: $userId');
      print('   - Hình thức thanh toán: $hinhThucThanhToan');
      print(
        '   - Tổng tiền sau giảm: ${CurrencyFormatter.formatVND(finalTotal)}',
      );

      // TRỪ MÃ GIẢM NGAY KHI NHẤN "ĐẶT ĐƠN" (DÙ COD HAY VNPAY)
      if (_selectedDiscount != null && _selectedDiscount!['code'] != null) {
        try {
          await SupabaseDiscountService.updateDiscountUsage(
            _selectedDiscount!['code'],
          );
          print(
            '[DEBUG] ĐÃ TRỪ so_luong_da_dung NGAY LẬP TỨC cho mã: ${_selectedDiscount!['code']}',
          );
        } catch (e) {
          print('Warning: [DEBUG] Không thể trừ mã giảm giá ngay: $e');
          // Vẫn tiếp tục đặt đơn dù lỗi
        }
      }

      if (_paymentMethod == 'VNPay') {
        await _handleVNPayPaymentFlow(
          userId: userId,
          amount: finalTotal,
          details: details,
          hinhThucThanhToan: hinhThucThanhToan,
        );
      } else {
        // COD: Tạo đơn ngay (mã đã trừ rồi)
        final orderId = await SupabaseOrderService.createOrder(
          userId: userId,
          diaChiGiaoHang: _buildFullAddress(_selectedAddress!),
          ghiChu:
              _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
          tongGiaTriDonHang: finalTotal,
          maGiamGia: _selectedDiscount?['ma_giam_gia'],
          items:
              details
                  .map(
                    (d) => {
                      'ma_bien_the_san_pham': d.maBienTheSanPham,
                      'so_luong_mua': d.soLuong,
                      'thanh_tien': d.giaTienTaiThoiDiemThem * d.soLuong,
                    },
                  )
                  .toList(),
          hinhThucThanhToan: hinhThucThanhToan,
        );

        await _handleCODPayment(userId, cartProvider);
      }
    } catch (e, stackTrace) {
      print('[DEBUG] Lỗi đặt hàng: $e');
      print('[DEBUG] Stack trace: $stackTrace');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đặt hàng: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).checkout,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          final sourceDetails = _getSourceDetails(cart);
          final merged = <int, CartDetail>{};
          for (final d in sourceDetails) {
            final key = d.maBienTheSanPham;
            if (merged.containsKey(key)) {
              final old = merged[key]!;
              merged[key] = CartDetail(
                maChiTietGioHang: old.maChiTietGioHang,
                maGioHang: old.maGioHang,
                maBienTheSanPham: old.maBienTheSanPham,
                soLuong: old.soLuong + d.soLuong,
                giaTienTaiThoiDiemThem: old.giaTienTaiThoiDiemThem,
                productVariant: old.productVariant,
              );
            } else {
              merged[key] = d;
            }
          }
          final items = merged.values.toList();
          final total = items.fold<double>(
            0.0,
            (s, it) => s + it.giaTienTaiThoiDiemThem * it.soLuong,
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1100;
              final summaryPanel = Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng cộng',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          CurrencyFormatter.formatVND(total),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (_selectedDiscount != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_offer,
                                size: 16,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Giảm giá (${_selectedDiscount!['code']})',
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '-${CurrencyFormatter.formatVND(_calculateDiscountAmount(total))}',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(height: 1, color: AppColors.borderLight),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDiscount != null
                              ? AppLocalizations.of(
                                context,
                              ).translate('total_amount')
                              : AppLocalizations.of(context).translate('total'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatVND(
                            _calculateTotalAfterDiscount(total),
                          ),
                          style: const TextStyle(
                            color: AppColors.accentRed,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: _submitting ? 'Đang đặt...' : 'ĐẶT ĐƠN',
                      type: AppButtonType.accent,
                      size: AppButtonSize.large,
                      onPressed: _submitting ? null : _placeOrder,
                    ),
                  ],
                ),
              );

              final leftContent = SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(
                        context,
                      ).translate('shipping_address'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAddressCards(),
                    const SizedBox(height: 16),

                    _buildPaymentMethodSectionStyled(),
                    const SizedBox(height: 16),

                    Text(
                      AppLocalizations.of(context).translate('order_summary'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map(
                      (d) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: AppColors.lightGray,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.borderLight,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child:
                                    (d
                                                .productVariant
                                                ?.product
                                                ?.hinhAnh
                                                .isNotEmpty ==
                                            true)
                                        ? CachedNetworkImage(
                                          imageUrl:
                                              d
                                                  .productVariant!
                                                  .product!
                                                  .hinhAnh
                                                  .first,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) => const Center(
                                                child: SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                          errorWidget:
                                              (context, url, error) =>
                                                  const Icon(
                                                    Icons.image_not_supported,
                                                    size: 24,
                                                    color: AppColors.mediumGray,
                                                  ),
                                        )
                                        : const Icon(
                                          Icons.image,
                                          color: AppColors.mediumGray,
                                        ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.productVariant?.product?.tenSanPham ??
                                        'Sản phẩm',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context).size +
                                        ': ${d.productVariant?.size?.tenSize ?? '-'} · ' +
                                        AppLocalizations.of(context).color +
                                        ': ${d.productVariant?.color?.tenMau ?? '-'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'x${d.soLuong}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.formatVND(
                                    d.giaTienTaiThoiDiemThem * d.soLuong,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.priceRed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('discount'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_selectedDiscount != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDiscountId = null;
                                _selectedDiscount = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).translate('reset'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showDiscountDialog,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                _selectedDiscount != null
                                    ? AppColors.accentRed
                                    : AppColors.borderLight,
                            width: _selectedDiscount != null ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color:
                              _selectedDiscount != null
                                  ? AppColors.accentRed.withOpacity(0.05)
                                  : Colors.white,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    _selectedDiscount != null
                                        ? AppColors.accentRed
                                        : AppColors.lightGray,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.local_offer,
                                size: 20,
                                color:
                                    _selectedDiscount != null
                                        ? Colors.white
                                        : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedDiscount != null
                                        ? _selectedDiscount!['noi_dung']
                                        : AppLocalizations.of(
                                          context,
                                        ).translate('discount'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          _selectedDiscount != null
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                    ),
                                  ),
                                  if (_selectedDiscount != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedDiscount!['mo_ta'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color:
                                  _selectedDiscount != null
                                      ? AppColors.accentRed
                                      : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      AppLocalizations.of(context).translate('order_note'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập ghi chú cho đơn hàng (tùy chọn)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );

              if (!wide) {
                return Column(
                  children: [Expanded(child: leftContent), summaryPanel],
                );
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: leftContent),
                      const SizedBox(width: 16),
                      SizedBox(width: 380, child: summaryPanel),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Lấy icon từ payment method hoặc default
  IconData _getPaymentIcon(String? iconName) {
    switch (iconName) {
      case 'cash':
        return Icons.local_shipping;
      case 'payment':
        return Icons.payment;
      case 'credit_card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.accentRed.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.accentRed : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accentRed : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? AppColors.accentRed : AppColors.textPrimary,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _paymentMethod,
              onChanged:
                  (value) =>
                      setState(() => _paymentMethod = value ?? _paymentMethod),
              activeColor: AppColors.accentRed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCards() {
    return Consumer<AddressProvider>(
      builder: (context, addressProvider, child) {
        if (addressProvider.addresses.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.location_off_outlined,
                  size: 48,
                  color: AppColors.textLight,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).translate('no_addresses'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).translate('please_add_address'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(
                  width: 400,
                  text: AppLocalizations.of(
                    context,
                  ).translate('add_new_address'),
                  type: AppButtonType.secondary,
                  onPressed: _addNewAddress,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            ...addressProvider.addresses.map((address) {
              final isSelected = _selectedAddress?.id == address.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.accentRed.withOpacity(0.08)
                          : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.accentRed
                            : AppColors.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Radio<UserAddress>(
                      value: address,
                      groupValue: _selectedAddress,
                      onChanged:
                          (value) => setState(() => _selectedAddress = value),
                      activeColor: AppColors.accentRed,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  address.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (address.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentRed.withOpacity(
                                      0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).translate('default'),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.accentRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _selectAddress,
                                child: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            address.phone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buildFullAddress(address),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            AppButton(
              width: 400,
              text: AppLocalizations.of(context).translate('add_new_address'),
              type: AppButtonType.secondary,
              onPressed: _addNewAddress,
            ),
          ],
        );
      },
    );
  }

  String _buildFullAddress(UserAddress address) {
    final parts = <String>[
      address.addressLine1,
      if (address.addressLine2 != null) address.addressLine2!,
      if (address.ward != null) address.ward!,
      if (address.district != null) address.district!,
      address.city,
    ];
    return parts.join(', ');
  }

  void _selectAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddressSelectionScreen(
              selectedAddress: _selectedAddress,
              onAddressSelected: (address) {
                setState(() => _selectedAddress = address);
                Navigator.pop(context);
              },
            ),
      ),
    );
  }

  void _addNewAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditAddressScreen()),
    ).then((value) {
      if (value == true) _loadAddresses();
    });
  }

  Widget _buildPaymentMethodSectionStyled() {
    if (_loadingPaymentMethods) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('payment_methods'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.accentRed),
            ),
          ),
        ],
      );
    }

    if (_availablePaymentMethods.isEmpty) {
      // Fallback nếu không có payment method nào được kích hoạt
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('payment_methods'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            'COD',
            AppLocalizations.of(context).translate('cod'),
            Icons.local_shipping,
            _paymentMethod == 'COD',
            () => setState(() => _paymentMethod = 'COD'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('payment_methods'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._availablePaymentMethods.map((method) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildPaymentOption(
              method.maPhuongThuc,
              method.tenPhuongThuc,
              _getPaymentIcon(method.icon),
              _paymentMethod == method.maPhuongThuc,
              () => setState(() => _paymentMethod = method.maPhuongThuc),
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _handleVNPayPaymentFlow({
    required int userId,
    required double amount,
    required List<CartDetail> details,
    required String hinhThucThanhToan,
  }) async {
    try {
      // start VNPay processing

      final paymentUrl = await VNPayService.createPaymentUrl(
        orderId: DateTime.now().millisecondsSinceEpoch,
        amount: amount,
        orderInfo: 'Thanh toan don hang ',
        returnUrl: 'zamyapp://vnpay-return',
      );

      if (paymentUrl != null) {
        await VNPayService.showPayment(
          context: context,
          paymentUrl: paymentUrl,
          onPaymentSuccess: (params) async {
            // VNPay success

            // MÃ ĐÃ TRỪ Ở TRÊN → KHÔNG GỌI LẠI

            final orderId = await SupabaseOrderService.createOrder(
              userId: userId,
              diaChiGiaoHang: _buildFullAddress(_selectedAddress!),
              ghiChu: 'Đã thanh toán online',
              tongGiaTriDonHang: amount,
              maGiamGia: _selectedDiscount?['ma_giam_gia'],
              items:
                  details
                      .map(
                        (d) => {
                          'ma_bien_the_san_pham': d.maBienTheSanPham,
                          'so_luong_mua': d.soLuong,
                          'thanh_tien': d.giaTienTaiThoiDiemThem * d.soLuong,
                        },
                      )
                      .toList(),
              hinhThucThanhToan: hinhThucThanhToan,
            );

            final cartProvider = Provider.of<CartProvider>(
              context,
              listen: false,
            );
            final selectedIds = widget.selectedCartDetailIds ?? {};
            await SupabaseCartService.removeSelectedFromCart(
              userId,
              selectedIds,
            );
            await cartProvider.loadCart();

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(
                    context,
                  ).translate('order_placed_success'),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const OrderScreen()),
              (route) => route.isFirst,
            );
          },
          onPaymentError: (params) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).translate('payment_failed'),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('payment_failed'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('payment_failed'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _validateStock(List<CartDetail> details) async {
    try {
      final client = SupabaseConfig.client;
      for (final d in details) {
        final row =
            await client
                .from('product_variants')
                .select('ton_kho')
                .eq('ma_bien_the', d.maBienTheSanPham)
                .maybeSingle();
        if (row == null) return false;
        final stock = (row['ton_kho'] as num).toInt();
        if (d.soLuong > stock) return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleCODPayment(int userId, CartProvider cartProvider) async {
    try {
      final selectedIds = widget.selectedCartDetailIds ?? {};
      await SupabaseCartService.removeSelectedFromCart(userId, selectedIds);
      await cartProvider.loadCart();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đặt hàng thành công')));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OrderScreen()),
        (route) => route.isFirst,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadDiscounts() async {
    setState(() => _loadingDiscounts = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.user?.maNguoiDung;
      final discounts =
          userId != null
              ? await SupabaseDiscountService.getAvailableDiscountsForUser(
                userId,
              )
              : await SupabaseDiscountService.getAvailableDiscounts();

      setState(() {
        _availableDiscounts = discounts;
        _loadingDiscounts = false;
      });
    } catch (e, stackTrace) {
      print('Lỗi tải mã giảm giá: $e\n$stackTrace');
      setState(() => _loadingDiscounts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải mã giảm giá: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDiscountDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        color: AppColors.accentRed,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Chọn mã giảm giá',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      _loadingDiscounts
                          ? const Center(child: CircularProgressIndicator())
                          : _availableDiscounts.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Không có mã giảm giá nào',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _availableDiscounts.length,
                            itemBuilder: (context, index) {
                              final discount = _availableDiscounts[index];
                              final isSelected =
                                  _selectedDiscountId == discount['code'];
                              final cartProvider = Provider.of<CartProvider>(
                                context,
                                listen: false,
                              );
                              final totalAmount = cartProvider.cartDetails
                                  .fold<double>(
                                    0.0,
                                    (sum, item) =>
                                        sum +
                                        (item.giaTienTaiThoiDiemThem *
                                            item.soLuong),
                                  );
                              final validationError = _validateDiscount(
                                discount,
                                totalAmount,
                              );
                              final canApply = validationError == null;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppColors.accentRed
                                            : canApply
                                            ? Colors.grey.shade300
                                            : Colors.red.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      isSelected
                                          ? AppColors.accentRed.withOpacity(
                                            0.05,
                                          )
                                          : canApply
                                          ? Colors.white
                                          : Colors.red.shade50,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? AppColors.accentRed
                                              : canApply
                                              ? Colors.grey.shade200
                                              : Colors.red.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      canApply
                                          ? Icons.local_offer
                                          : Icons.block,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : canApply
                                              ? Colors.grey.shade600
                                              : Colors.red.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    discount['noi_dung'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isSelected
                                              ? AppColors.accentRed
                                              : canApply
                                              ? AppColors.textPrimary
                                              : Colors.red.shade600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        canApply
                                            ? (discount['mo_ta'] ?? '')
                                            : validationError!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              canApply
                                                  ? AppColors.textLight
                                                  : Colors.red.shade600,
                                          fontWeight:
                                              canApply
                                                  ? FontWeight.normal
                                                  : FontWeight.w500,
                                        ),
                                      ),
                                      if (canApply) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.accentRed
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                discount['code'],
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.accentRed,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                discount['loai_giam_gia'] ==
                                                        'percentage'
                                                    ? 'Giảm ${discount['muc_giam_gia']}%'
                                                    : 'Giảm ${CurrencyFormatter.formatVND((discount['muc_giam_gia'] as num).toDouble())}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.green.shade600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing:
                                      isSelected
                                          ? Icon(
                                            Icons.check_circle,
                                            color: AppColors.accentRed,
                                            size: 24,
                                          )
                                          : canApply
                                          ? Icon(
                                            Icons.radio_button_unchecked,
                                            color: Colors.grey.shade400,
                                            size: 24,
                                          )
                                          : Icon(
                                            Icons.block,
                                            color: Colors.red.shade400,
                                            size: 24,
                                          ),
                                  onTap:
                                      canApply
                                          ? () {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedDiscountId = null;
                                                _selectedDiscount = null;
                                              } else {
                                                _selectedDiscountId =
                                                    discount['code'];
                                                _selectedDiscount = discount;
                                              }
                                            });
                                            Navigator.pop(context);
                                          }
                                          : null,
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
    );
  }
}

