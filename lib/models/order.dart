import 'product_variant.dart';
import 'product.dart';

class Order {
  final int maDonHang;
  final int maNguoiDung;
  final int? maGiamGia;
  final String diaChiGiaoHang;
  final String? ghiChu;
  final DateTime ngayDatHang;
  final double tongGiaTriDonHang;
  final String? lyDoHuyHoanHang;
  final int? maTrangThaiDonHang;
  final List<OrderDetail> orderDetails;
  final OrderStatus? orderStatus;

  // ✅ Thêm trường mới để hỗ trợ kiểm tra hoàn hàng
  final DateTime? ngayGiaoHang;

  // THÊM 2 FIELD TỪ CSDL (BẮT BUỘC)
  final String hinhThucThanhToan;
  final String trangThaiThanhToan;

  Order({
    required this.maDonHang,
    required this.maNguoiDung,
    this.maGiamGia,
    required this.diaChiGiaoHang,
    this.ghiChu,
    required this.ngayDatHang,
    required this.tongGiaTriDonHang,
    this.lyDoHuyHoanHang,
    this.maTrangThaiDonHang,
    required this.orderDetails,
    this.orderStatus,
    required this.hinhThucThanhToan,
    required this.trangThaiThanhToan,
    this.ngayGiaoHang, // ✅ thêm vào constructor
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      maDonHang: (json['ma_don_hang'] as int?) ?? 0,
      maNguoiDung: (json['ma_nguoi_dung'] as int?) ?? 0,
      maGiamGia: json['ma_giam_gia'] as int?,
      diaChiGiaoHang: (json['dia_chi_giao_hang'] as String?) ?? '',
      ghiChu: json['ghi_chu'] as String?,
      ngayDatHang: DateTime.tryParse(json['ngay_dat_hang']?.toString() ?? '') ?? DateTime.now(),
      tongGiaTriDonHang: (json['tong_gia_tri_don_hang'] as num?)?.toDouble() ?? 0.0,
      lyDoHuyHoanHang: json['ly_do_huy_hoan_hang'] as String?,
      maTrangThaiDonHang: json['ma_trang_thai_don_hang'] as int?,
      orderDetails: (json['order_details'] as List?)
              ?.map((item) => OrderDetail.fromJson(item))
              .toList() ??
          [],
      orderStatus: json['order_status'] != null
          ? OrderStatus.fromJson(json['order_status'])
          : null,
      hinhThucThanhToan:
          (json['hinh_thuc_thanh_toan'] as String?) ?? 'tien_mat',
      trangThaiThanhToan:
          (json['trang_thai_thanh_toan'] as String?) ?? 'chua_thanh_toan',
      // ✅ Parse ngày giao hàng nếu có
      ngayGiaoHang: json['ngay_giao_hang'] != null
          ? DateTime.parse(json['ngay_giao_hang'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_don_hang': maDonHang,
      'ma_nguoi_dung': maNguoiDung,
      'ma_giam_gia': maGiamGia,
      'dia_chi_giao_hang': diaChiGiaoHang,
      'ghi_chu': ghiChu,
      'ngay_dat_hang': ngayDatHang.toIso8601String(),
      'tong_gia_tri_don_hang': tongGiaTriDonHang,
      'ly_do_huy_hoan_hang': lyDoHuyHoanHang,
      'ma_trang_thai_don_hang': maTrangThaiDonHang,
      'hinh_thuc_thanh_toan': hinhThucThanhToan,
      'trang_thai_thanh_toan': trangThaiThanhToan,
      // ✅ Lưu cả ngày giao hàng nếu có
      'ngay_giao_hang': ngayGiaoHang?.toIso8601String(),
    };
  }

  // --- Các getter tiện dụng ---
  String get phuongThucThanhToan =>
      hinhThucThanhToan == 'vnpay' ? 'VNPay' : 'Tiền mặt (COD)';

  bool get daThanhToan => trangThaiThanhToan == 'da_thanh_toan';

  List<OrderDetail> get orderItems => orderDetails;
  DateTime get createdAt => ngayDatHang;
  double get tongTien => tongGiaTriDonHang;
  String get trangThai => orderStatus?.tenTrangThai ?? 'Chưa xác định';
}

class OrderStatus {
  final int maTrangThaiDonHang;
  final String tenTrangThai;
  final bool trangThaiKichHoat;

  OrderStatus({
    required this.maTrangThaiDonHang,
    required this.tenTrangThai,
    required this.trangThaiKichHoat,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(
      maTrangThaiDonHang: json['ma_trang_thai_don_hang'] as int,
      tenTrangThai: json['ten_trang_thai'] as String,
      trangThaiKichHoat: json['trang_thai_kich_hoat'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_trang_thai_don_hang': maTrangThaiDonHang,
      'ten_trang_thai': tenTrangThai,
      'trang_thai_kich_hoat': trangThaiKichHoat,
    };
  }
}

class OrderDetail {
  final int maChiTietDonHang;
  final int maDonHang;
  final int maBienTheSanPham;
  final double thanhTien;
  final int soLuongMua;
  final ProductVariant? productVariant;

  OrderDetail({
    required this.maChiTietDonHang,
    required this.maDonHang,
    required this.maBienTheSanPham,
    required this.thanhTien,
    required this.soLuongMua,
    this.productVariant,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      maChiTietDonHang: (json['ma_chi_tiet_don_hang'] as int?) ?? 0,
      maDonHang: (json['ma_don_hang'] as int?) ?? 0,
      maBienTheSanPham: (json['ma_bien_the_san_pham'] as int?) ?? 0,
      thanhTien: (json['thanh_tien'] as num?)?.toDouble() ?? 0.0,
      soLuongMua: (json['so_luong_mua'] as int?) ?? 0,
      productVariant: json['product_variant'] != null
          ? ProductVariant.fromJson(json['product_variant'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_chi_tiet_don_hang': maChiTietDonHang,
      'ma_don_hang': maDonHang,
      'ma_bien_the_san_pham': maBienTheSanPham,
      'thanh_tien': thanhTien,
      'so_luong_mua': soLuongMua,
    };
  }

  Product? get product => productVariant?.product;
  double get giaBan => thanhTien / soLuongMua;
  int get soLuong => soLuongMua;
  String? get size => productVariant?.size?.tenSize;
  String? get mauSac => productVariant?.color?.tenMau;
}
