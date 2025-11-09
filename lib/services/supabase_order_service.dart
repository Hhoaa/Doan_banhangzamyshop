import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../config/supabase_config.dart';
import 'supabase_notification_service.dart';

class SupabaseOrderService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Lấy ID của trạng thái "Chờ xác nhận"
  static Future<int?> _getPendingStatusId() async {
    try {
      final response = await _client
          .from('order_statuses')
          .select('ma_trang_thai_don_hang')
          .eq('ten_trang_thai', 'Chờ xác nhận')
          .single();
      return response['ma_trang_thai_don_hang'] as int?;
    } catch (e) {
      print('Error getting pending status ID: $e');
      return null;
    }
  }

  // Lấy danh sách đơn hàng của user
  static Future<List<Order>> getUserOrders(
    int userId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final query = _client
          .from('orders')
          .select('''
            *,
            hinh_thuc_thanh_toan,
            trang_thai_thanh_toan,
            order_details:order_details(
              *,
              product_variant:ma_bien_the_san_pham(
                *,
                product:ma_san_pham(
                  *,
                  product_images:product_images(*)
                ),
                size:ma_size(*),
                color:ma_mau(*)
              )
            ),
            order_status:ma_trang_thai_don_hang(*)
          ''')
          .eq('ma_nguoi_dung', userId)
          .order('ngay_dat_hang', ascending: false);

      final response = await query.range(offset, offset + limit - 1);

      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  // Lấy chi tiết đơn hàng
  static Future<Order?> getOrderById(int orderId) async {
    try {
      final response = await _client
          .from('orders')
          .select('''
            *,
            hinh_thuc_thanh_toan,
            trang_thai_thanh_toan,
            order_details:order_details(
              *,
              product_variant:ma_bien_the_san_pham(
                *,
                product:ma_san_pham(*),
                size:ma_size(*),
                color:ma_mau(*)
              )
            ),
            order_status:ma_trang_thai_don_hang(*)
          ''')
          .eq('ma_don_hang', orderId)
          .maybeSingle();

      if (response == null) return null;
      return Order.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Tạo đơn hàng mới
  static Future<int?> createOrder({
    required int userId,
    required List<Map<String, dynamic>> items,
    required String diaChiGiaoHang,
    double? tongGiaTriDonHang,
    String? ghiChu,
    int? maGiamGia,
    required String hinhThucThanhToan, // 'tien_mat' hoặc 'vnpay'
  }) async {
    try {
      final trangThaiThanhToan =
          hinhThucThanhToan == 'vnpay' ? 'da_thanh_toan' : 'chua_thanh_toan';
      final pendingStatusId = await _getPendingStatusId();

      // Kiểm tra & trừ tồn kho
      final Map<int, int> variantToQty = {};
      for (final raw in items) {
        final int variantId =
            (raw['ma_bien_the_san_pham'] ?? raw['variantId']) as int;
        final int qty = (raw['so_luong_mua'] ?? raw['quantity']) as int;
        variantToQty.update(variantId, (old) => old + qty, ifAbsent: () => qty);
      }

      for (final entry in variantToQty.entries) {
        final variantId = entry.key;
        final qty = entry.value;
        final stockRow = await _client
            .from('product_variants')
            .select('ton_kho')
            .eq('ma_bien_the', variantId)
            .single();
        final currentStock = stockRow['ton_kho'] as int;
        if (currentStock < qty) {
          throw Exception('Sản phẩm không đủ hàng (variant $variantId)');
        }
        await _client
            .from('product_variants')
            .update({'ton_kho': currentStock - qty})
            .eq('ma_bien_the', variantId);
      }

      // Tạo đơn hàng
      final orderResponse = await _client
          .from('orders')
          .insert({
            'ma_nguoi_dung': userId,
            'dia_chi_giao_hang': diaChiGiaoHang,
            'ma_giam_gia': maGiamGia,
            'tong_gia_tri_don_hang': tongGiaTriDonHang,
            'ghi_chu': ghiChu,
            'ma_trang_thai_don_hang': pendingStatusId,
            'hinh_thuc_thanh_toan': hinhThucThanhToan,
            'trang_thai_thanh_toan': trangThaiThanhToan,
          })
          .select('ma_don_hang')
          .single();

      final orderId = orderResponse['ma_don_hang'];

      // Tạo order_details
      for (final item in items) {
        await _client.from('order_details').insert({
          'ma_don_hang': orderId,
          'ma_bien_the_san_pham':
              item['ma_bien_the_san_pham'] ?? item['variantId'],
          'thanh_tien': item['thanh_tien'] ??
              (item['price'] != null && item['quantity'] != null
                  ? item['price'] * item['quantity']
                  : 0),
          'so_luong_mua': item['so_luong_mua'] ?? item['quantity'],
        });
      }

      // Gửi thông báo
      await SupabaseNotificationService.createOrderNotification(
        userId: userId,
        orderId: orderId,
        status: 'pending',
      );

      return orderId;
    } catch (e, stack) {
      print('[DEBUG] Lỗi tạo đơn hàng: $e');
      print(stack);
      throw Exception('Failed to create order: $e');
    }
  }

  // Cập nhật trạng thái đơn hàng
  static Future<bool> updateOrderStatus(int orderId, int statusId) async {
    try {
      final statusRow = await _client
          .from('order_statuses')
          .select('ten_trang_thai')
          .eq('ma_trang_thai_don_hang', statusId)
          .maybeSingle();
      final statusName =
          statusRow != null ? (statusRow['ten_trang_thai'] as String) : '';

      await _client
          .from('orders')
          .update({'ma_trang_thai_don_hang': statusId})
          .eq('ma_don_hang', orderId);

      // Nếu trạng thái là "Đã trả hàng" → hoàn kho
      if (statusName.toLowerCase().contains('đã trả hàng') ||
          statusName.toLowerCase().contains('da tra hang') ||
          statusName.toLowerCase().contains('hoàn')) {
        final orderDetails = await _client
            .from('order_details')
            .select('ma_bien_the_san_pham, so_luong_mua')
            .eq('ma_don_hang', orderId);

        for (final d in (orderDetails as List)) {
          final int variantId = d['ma_bien_the_san_pham'] as int;
          final int qty = d['so_luong_mua'] as int;
          final stockRow = await _client
              .from('product_variants')
              .select('ton_kho')
              .eq('ma_bien_the', variantId)
              .single();
          final currentStock = stockRow['ton_kho'] as int;
          await _client
              .from('product_variants')
              .update({'ton_kho': currentStock + qty})
              .eq('ma_bien_the', variantId);
        }

        final orderRow = await _client
            .from('orders')
            .select('ma_nguoi_dung')
            .eq('ma_don_hang', orderId)
            .maybeSingle();
        final userId =
            orderRow != null ? orderRow['ma_nguoi_dung'] as int : null;

        if (userId != null) {
          await SupabaseNotificationService.createNotification(
            userId: userId,
            title: 'Đã trả hàng thành công',
            content:
                'Đơn hàng #$orderId của bạn đã được xác nhận trả hàng thành công.',
            type: 'order',
            orderId: orderId,
          );
        }
      }

      return true;
    } catch (e, stack) {
      print('[DEBUG] Lỗi updateOrderStatus: $e');
      print(stack);
      throw Exception('Failed to update order status: $e');
    }
  }

  // Đánh dấu đơn hàng đã trả hàng
  static Future<bool> markOrderReturned(int orderId) async {
    try {
      final returnedStatusRow = await _client
          .from('order_statuses')
          .select('ma_trang_thai_don_hang, ten_trang_thai')
          .ilike('ten_trang_thai', '%đã trả hàng%')
          .maybeSingle();

      if (returnedStatusRow == null || returnedStatusRow.isEmpty) {
        throw Exception('Không tìm thấy trạng thái "Đã trả hàng"');
      }

      final statusId = returnedStatusRow['ma_trang_thai_don_hang'] as int;
      return await updateOrderStatus(orderId, statusId);
    } catch (e, stack) {
      print('[DEBUG] Lỗi markOrderReturned: $e');
      print(stack);
      throw Exception('Failed to mark order as returned: $e');
    }
  }

  // Cập nhật ghi chú đơn hàng
  static Future<bool> updateOrderNote(int orderId, String note) async {
    try {
      await _client
          .from('orders')
          .update({'ghi_chu': note})
          .eq('ma_don_hang', orderId);
      return true;
    } catch (e) {
      throw Exception('Failed to update order note: $e');
    }
  }

  // Hủy đơn hàng
  static Future<bool> cancelOrder(int orderId, {String? reason}) async {
    try {
      final orderRow = await _client
          .from('orders')
          .select('ma_nguoi_dung')
          .eq('ma_don_hang', orderId)
          .maybeSingle();
      final userId = orderRow?['ma_nguoi_dung'] as int?;

      final cancelledStatusResponse = await _client
          .from('order_statuses')
          .select('ma_trang_thai_don_hang')
          .eq('ten_trang_thai', 'Đã hủy')
          .maybeSingle();

      if (cancelledStatusResponse != null) {
        await _client.from('orders').update({
          'ma_trang_thai_don_hang':
              cancelledStatusResponse['ma_trang_thai_don_hang'],
          if (reason != null && reason.isNotEmpty)
            'ghi_chu': 'Hủy đơn: ' + reason,
        }).eq('ma_don_hang', orderId);
      }

      // Hoàn kho
      final orderDetails = await _client
          .from('order_details')
          .select('ma_bien_the_san_pham, so_luong_mua')
          .eq('ma_don_hang', orderId);

      for (final d in (orderDetails as List)) {
        final int variantId = d['ma_bien_the_san_pham'] as int;
        final int qty = d['so_luong_mua'] as int;
        final stockRow = await _client
            .from('product_variants')
            .select('ton_kho')
            .eq('ma_bien_the', variantId)
            .single();
        final currentStock = stockRow['ton_kho'] as int;
        await _client
            .from('product_variants')
            .update({'ton_kho': currentStock + qty})
            .eq('ma_bien_the', variantId);
      }

      if (userId != null) {
        await SupabaseNotificationService.createNotification(
          userId: userId,
          title: 'Đơn hàng đã bị hủy',
          content: reason?.isNotEmpty == true
              ? reason!
              : 'Đơn hàng của bạn đã bị hủy',
          type: 'order',
          orderId: orderId,
        );
      }

      return true;
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Gửi yêu cầu hoàn hàng
  static Future<bool> requestReturn(int orderId, {required String reason}) async {
    try {
      final orderRow = await _client
          .from('orders')
          .select('ma_nguoi_dung')
          .eq('ma_don_hang', orderId)
          .maybeSingle();
      final userId = orderRow?['ma_nguoi_dung'] as int?;

      final statuses = await _client
          .from('order_statuses')
          .select('ma_trang_thai_don_hang, ten_trang_thai');
      final match = (statuses as List?)
          ?.cast<Map<String, dynamic>>()
          .firstWhere(
            (e) => (e['ten_trang_thai'] as String)
                .toLowerCase()
                .contains('hoàn'),
            orElse: () => {},
          );

      final updateData = <String, dynamic>{
        if (match != null && match.isNotEmpty)
          'ma_trang_thai_don_hang': match['ma_trang_thai_don_hang'],
        'ghi_chu': 'Yêu cầu hoàn hàng: ' + reason,
      };

      await _client.from('orders').update(updateData).eq('ma_don_hang', orderId);

      // Thông báo user
      if (userId != null) {
        await SupabaseNotificationService.createNotification(
          userId: userId,
          title: 'Yêu cầu hoàn hàng',
          content: reason,
          type: 'order',
          orderId: orderId,
        );
      }

      // Thông báo admin
      try {
        final orderInfo = await _client
            .from('orders')
            .select('ma_don_hang, users!orders_ma_nguoi_dung_fkey(ten_nguoi_dung)')
            .eq('ma_don_hang', orderId)
            .single();

        String customerName = 'Khách hàng';
        if (orderInfo['users'] != null) {
          final usersData = orderInfo['users'];
          if (usersData is Map && usersData.containsKey('ten_nguoi_dung')) {
            customerName = usersData['ten_nguoi_dung'] as String? ?? 'Khách hàng';
          } else if (usersData is List && usersData.isNotEmpty) {
            customerName = usersData[0]['ten_nguoi_dung'] as String? ?? 'Khách hàng';
          }
        }

        final orderCode = '#$orderId';
        final adminId = 1;

        await SupabaseNotificationService.createNotification(
          userId: adminId,
          title: 'Yêu cầu hoàn hàng - Đơn $orderCode',
          content: 'Khách hàng $customerName đã yêu cầu hoàn hàng cho đơn hàng $orderCode. Lý do: $reason',
          type: 'order',
          orderId: orderId,
        );
      } catch (e) {
        print('[Order] Error creating admin notification (non-critical): $e');
      }

      return true;
    } catch (e) {
      throw Exception('Failed to request return: $e');
    }
  }
}
