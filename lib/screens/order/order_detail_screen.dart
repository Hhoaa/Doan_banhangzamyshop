import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/order.dart';
import '../../utils/currency_formatter.dart'; 
import '../../widgets/common/app_button.dart';
import '../review/review_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: Text(
          'Chi tiết đơn hàng #${order.maDonHang}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1100;
          final content = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatusCard(),
                                const SizedBox(height: 16),
                                _buildOrderInfoCard(),
                                const SizedBox(height: 16),
                                if (_isDeliveredOrder()) _buildReviewButton(context),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOrderItemsCard(),
                                const SizedBox(height: 16),
                                _buildOrderSummaryCard(),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusCard(),
                          const SizedBox(height: 16),
                          _buildOrderInfoCard(),
                          const SizedBox(height: 16),
                          _buildOrderItemsCard(),
                          const SizedBox(height: 16),
                          _buildOrderSummaryCard(),
                          const SizedBox(height: 16),
                          if (_isDeliveredOrder()) _buildReviewButton(context),
                        ],
                      ),
              ),
            ),
          );
          return content;
        },
      ),
    );
  }

  // === TRẠNG THÁI ĐƠN HÀNG ===
  Widget _buildStatusCard() {
    final statusText = order.trangThai;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(statusText),
                color: _getStatusColor(statusText),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trạng thái đơn hàng',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(statusText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusTimeline(statusText),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String statusText) {
    final statusMap = {
      'Chờ xác nhận': {'icon': Icons.access_time, 'color': Colors.orange},
      'Đã xác nhận': {'icon': Icons.check_circle_outline, 'color': Colors.blue},
      'Đang giao hàng': {'icon': Icons.local_shipping, 'color': Colors.purple},
      'Đã giao hàng': {'icon': Icons.done_all, 'color': Colors.green},
      'Đã hủy': {'icon': Icons.cancel, 'color': Colors.red},
      'Đã trả hàng': {'icon': Icons.undo, 'color': Colors.grey},
    };

    final info = statusMap[statusText] ?? {'icon': Icons.help_outline, 'color': Colors.grey};

    // Nếu có ngày giao hàng, ưu tiên hiển thị; ngược lại dùng ngày đặt
    final DateTime displayedDate = order.ngayGiaoHang ?? order.ngayDatHang;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lộ trình đơn hàng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(shape: BoxShape.circle, color: info['color'] as Color),
              child: Icon(info['icon'] as IconData, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: info['color'] as Color),
                  ),
                  Text(
                    // Hiển thị ngày giao nếu có, nếu không hiển thị ngày đặt
                    'Cập nhật: ${_formatDate(displayedDate)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ĐÃ SỬA HOÀN CHỈNH: DÙNG DỮ LIỆU THỰC TỪ CSDL
  Widget _buildOrderInfoCard() {
    final phuongThuc = order.hinhThucThanhToan; // LẤY TỪ CSDL
    final daThanhToan = order.daThanhToan;      // LẤY TỪ GETTER

    String phuongThucHienThi = order.phuongThucThanhToan; // DÙNG GETTER ĐÃ SỬA
    String trangThaiThanhToan = daThanhToan ? 'Đã thanh toán' : 'Chưa thanh toán';
    Color mauPhuongThuc = phuongThuc == 'vnpay' ? Colors.green.shade700 : AppColors.textPrimary;
    Color mauTrangThai = daThanhToan ? Colors.green.shade700 : Colors.orange.shade700;

    // ƯU TIÊN: ĐÃ GIAO HÀNG → LUÔN ĐÃ THANH TOÁN
    if (order.trangThai == 'Đã giao hàng') {
      trangThaiThanhToan = 'Đã thanh toán';
      mauTrangThai = Colors.green.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin đơn hàng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Mã đơn hàng', '#${order.maDonHang}'),
          _buildInfoRow('Ngày đặt', _formatDate(order.ngayDatHang)),

          // Thêm: Ngày giao hàng (có thể null)
          _buildInfoRow(
            'Ngày giao hàng',
            order.ngayGiaoHang != null ? _formatDate(order.ngayGiaoHang!) : 'Chưa cập nhật',
          ),

          _buildInfoRow('Địa chỉ giao hàng', order.diaChiGiaoHang),

          _buildInfoRow(
            'Phương thức thanh toán',
            phuongThucHienThi,
            valueColor: mauPhuongThuc,
          ),

          _buildInfoRow(
            'Trạng thái thanh toán',
            trangThaiThanhToan,
            valueColor: mauTrangThai,
          ),

          if (order.ghiChu?.trim().isNotEmpty == true)
            _buildInfoRow('Ghi chú', order.ghiChu!),
        ],
      ),
    );
  }

  // === SẢN PHẨM ĐÃ ĐẶT ===
  Widget _buildOrderItemsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sản phẩm đã đặt',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ...order.orderItems.map((item) => _buildOrderItem(item)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderDetail item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
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
                      errorBuilder: (_, __, ___) => const Icon(Icons.image, color: AppColors.mediumGray, size: 30),
                    )
                  : const Icon(Icons.image, color: AppColors.mediumGray, size: 30),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product?.tenSanPham ?? 'Sản phẩm',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: ${item.size ?? 'N/A'} | Màu: ${item.mauSac ?? 'N/A'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  'Số lượng: ${item.soLuong}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatVND(item.giaBan),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                CurrencyFormatter.formatVND(item.thanhTien),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.priceRed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === TỔNG TIỀN ===
  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tổng cộng:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          Text(
            CurrencyFormatter.formatVND(order.tongGiaTriDonHang),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.priceRed),
          ),
        ],
      ),
    );
  }

  // === HÀNG THÔNG TIN ===
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === HỖ TRỢ TRẠNG THÁI ===
  IconData _getStatusIcon(String status) {
    return {
      'Chờ xác nhận': Icons.access_time,
      'Đã xác nhận': Icons.check_circle_outline,
      'Đang giao hàng': Icons.local_shipping,
      'Đã giao hàng': Icons.done_all,
      'Đã hủy': Icons.cancel,
      'Đã trả hàng': Icons.undo,
    }[status] ?? Icons.help_outline;
  }

  Color _getStatusColor(String status) {
    return {
      'Chờ xác nhận': Colors.orange,
      'Đã xác nhận': Colors.blue,
      'Đang giao hàng': Colors.purple,
      'Đã giao hàng': Colors.green,
      'Đã hủy': Colors.red,
      'Đã trả hàng': Colors.grey,
    }[status] ?? Colors.grey;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  bool _isDeliveredOrder() => order.trangThai == 'Đã giao hàng';

  // === NÚT ĐÁNH GIÁ ===
  Widget _buildReviewButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đánh giá sản phẩm',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn đã nhận được sản phẩm. Hãy chia sẻ trải nghiệm của bạn!',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'ĐÁNH GIÁ SẢN PHẨM',
            type: AppButtonType.accent,
            size: AppButtonSize.large,
            onPressed: () => _navigateToReview(context),
          ),
        ],
      ),
    );
  }

  void _navigateToReview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReviewScreen(order: order)),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cảm ơn bạn đã đánh giá sản phẩm!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }
}
