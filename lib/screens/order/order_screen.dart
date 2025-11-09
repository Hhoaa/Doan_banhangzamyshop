import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/order.dart';
import '../../services/supabase_order_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/currency_formatter.dart';
import 'package:provider/provider.dart';
import 'order_detail_screen.dart';
import '../../navigation/home_tabs.dart';
import '../../navigation/navigator_key.dart';
import '../main/main_screen.dart';
import '../main/main_web_screen.dart';
import '../../providers/web_ui_provider.dart';
import '../../widgets/web/web_page_wrapper.dart';
import '../../l10n/app_localizations.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<Order> orders = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int _page = 0;
  static const int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadOrders(reset: true);
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadOrders({bool reset = false}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        if (reset) {
          setState(() {
            isLoading = true;
            orders = [];
            hasMore = true;
            _page = 0;
          });
        }

        if (!hasMore) return;

        final userOrders = await SupabaseOrderService.getUserOrders(
          authProvider.user!.maNguoiDung,
          limit: _pageSize,
          offset: _page * _pageSize,
        );

        setState(() {
          if (reset) orders = [];
          orders.addAll(userOrders);
          isLoading = false;
          isLoadingMore = false;
          hasMore = userOrders.length == _pageSize;
          if (userOrders.isNotEmpty) _page += 1;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
        );
      }
    }
  }

  void _onScroll() {
    if (!hasMore || isLoadingMore || isLoading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      setState(() => isLoadingMore = true);
      _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: Text(
          AppLocalizations.of(context).translate('my_orders'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: orders.isEmpty
                    ? _buildEmptyOrders()
                    : _buildOrdersList(),
              ),
            ),
    );

    // Wrap with WebShell only if not already inside one (when navigating from outside MainWebScreen)
    if (kIsWeb) {
      // Check if we're already inside a WebShell by looking for WebHeader in the widget tree
      // For simplicity, we'll always wrap when on web, and WebShell will handle duplicate prevention
      return WebPageWrapper(
        showWebHeader: true, // Show full header and footer for standalone pages
        showTopBar: false,
        showFooter: true,
        child: content,
      );
    }

    return content;
  }

  Widget _buildEmptyOrders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).translate('no_orders'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).translate('continue_shopping'),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              debugPrint('[OrderScreen] Continue shopping tapped');
              if (kIsWeb) {
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
            child: Text(AppLocalizations.of(context).translate('continue_shopping')),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: () => _loadOrders(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: orders.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= orders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildOrderCard(orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).translate('order_id') + ' #' + order.maDonHang.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.trangThai),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(order.trangThai),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).translate('order_date') + ': ' + _formatDate(order.ngayDatHang),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Order items
          ...order.orderItems.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.product?.hinhAnhDauTien != null
                            ? Image.network(
                                item.product!.hinhAnhDauTien!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.image,
                                    color: AppColors.mediumGray,
                                    size: 30,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.image,
                                color: AppColors.mediumGray,
                                size: 30,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product?.tenSanPham ?? 'Sản phẩm',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Size: ${item.size ?? 'N/A'} | ' + AppLocalizations.of(context).color + ': ${item.mauSac ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context).quantity + ': ${item.soLuong}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatVND(item.giaBan),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.priceRed,
                      ),
                    ),
                  ],
                ),
              )),

          const Divider(height: 20),

          // Order total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('total') + ':',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                CurrencyFormatter.formatVND(order.tongGiaTriDonHang),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.priceRed,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewOrderDetails(order),
                  child: Text(AppLocalizations.of(context).translate('order_details')),
                ),
              ),
              const SizedBox(width: 8),

              if (order.trangThai == 'Chờ xác nhận')
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCancelDialog(order.maDonHang),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: Text(AppLocalizations.of(context).translate('cancel_order')),
                  ),
                ),

              // ✅ Ẩn nút hoàn hàng nếu quá 7 ngày kể từ ngày giao
              if (order.trangThai == 'Đã giao hàng' && !_isReturnExpired(order))
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showReturnDialog(order.maDonHang),
                    child: Text(AppLocalizations.of(context).translate('return_policy')),
                  ),
                ),
            ],
          ),

          // ✅ Nếu quá hạn thì hiển thị dòng thông báo nhỏ
          if (order.trangThai == 'Đã giao hàng' && _isReturnExpired(order))
            Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                AppLocalizations.of(context).translate('order_placed_failed'),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.redAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// ✅ Kiểm tra xem đơn hàng có quá 7 ngày kể từ ngày giao hay chưa
  bool _isReturnExpired(Order order) {
    if (order.ngayGiaoHang == null) return false;
    final now = DateTime.now();
    final diff = now.difference(order.ngayGiaoHang!).inDays;
    return diff > 7;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Chờ xác nhận':
        return Colors.orange;
      case 'Đã xác nhận':
        return Colors.blue;
      case 'Đang giao hàng':
        return Colors.purple;
      case 'Đã giao hàng':
        return Colors.green;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Chờ xác nhận':
        return 'Chờ xác nhận';
      case 'Đã xác nhận':
        return 'Đã xác nhận';
      case 'Đang giao hàng':
        return 'Đang giao hàng';
      case 'Đã giao hàng':
        return 'Đã giao hàng';
      case 'Đã hủy':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(order: order),
      ),
    );
  }

  Future<void> _cancelOrder(int orderId) async {
    try {
      await SupabaseOrderService.cancelOrder(orderId);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy đơn hàng')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi hủy đơn hàng: $e')),
        );
      }
    }
  }

  void _showCancelDialog(int orderId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vui lòng nhập lý do hủy:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ví dụ: Đặt nhầm, muốn đổi địa chỉ...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          ElevatedButton(
            onPressed: () async {
              final parentContext = this.context;
              try {
                await SupabaseOrderService.cancelOrder(orderId, reason: controller.text.trim());
                if (mounted) Navigator.of(context).pop();
                await _loadOrders();
                if (!mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('Đã hủy đơn hàng')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(content: Text('Lỗi hủy: $e')));
              }
            },
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
  }

  void _showReturnDialog(int orderId) {
    final controller = TextEditingController();
    final parentContext = context;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Hoàn hàng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lý do hoàn hàng:'),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ví dụ: Sản phẩm lỗi, không đúng size...',
                  ),
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Đóng')),
            ElevatedButton(
              onPressed: () async {
                final reason = controller.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập lý do hoàn hàng')),
                  );
                  return;
                }
                try {
                  await SupabaseOrderService.requestReturn(orderId, reason: reason);
                  if (mounted) Navigator.of(context).pop();
                  await _loadOrders();
                  if (!mounted) return;
                  ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu hoàn hàng')));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(content: Text('Lỗi gửi yêu cầu: $e')));
                }
              },
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        ),
      ),
    );
  }
}
