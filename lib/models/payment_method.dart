class PaymentMethod {
  final int id;
  final String maPhuongThuc;
  final String tenPhuongThuc;
  final String? moTa;
  final bool daKichHoat;
  final int thuTuHienThi;
  final String? icon;

  PaymentMethod({
    required this.id,
    required this.maPhuongThuc,
    required this.tenPhuongThuc,
    this.moTa,
    required this.daKichHoat,
    required this.thuTuHienThi,
    this.icon,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      maPhuongThuc: json['ma_phuong_thuc'] as String,
      tenPhuongThuc: json['ten_phuong_thuc'] as String,
      moTa: json['mo_ta'] as String?,
      daKichHoat: json['da_kich_hoat'] as bool? ?? true,
      thuTuHienThi: json['thu_tu_hien_thi'] as int? ?? 0,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ma_phuong_thuc': maPhuongThuc,
      'ten_phuong_thuc': tenPhuongThuc,
      'mo_ta': moTa,
      'da_kich_hoat': daKichHoat,
      'thu_tu_hien_thi': thuTuHienThi,
      'icon': icon,
    };
  }
}

