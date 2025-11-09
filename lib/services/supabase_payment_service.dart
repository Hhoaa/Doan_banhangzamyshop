import '../../config/supabase_config.dart';
import '../models/payment_method.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePaymentService {
  static final SupabaseClient _client = SupabaseConfig.client;

  /// Lấy danh sách phương thức thanh toán đã được kích hoạt
  static Future<List<PaymentMethod>> getActivePaymentMethods() async {
    try {
      final response = await _client
          .from('payment_methods_settings')
          .select()
          .eq('da_kich_hoat', true)
          .order('thu_tu_hien_thi', ascending: true);

      return (response as List)
          .map((json) => PaymentMethod.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting active payment methods: $e');
      return [];
    }
  }

  /// Lấy tất cả phương thức thanh toán (bao gồm cả chưa kích hoạt) - dùng cho admin
  static Future<List<PaymentMethod>> getAllPaymentMethods() async {
    try {
      final response = await _client
          .from('payment_methods_settings')
          .select()
          .order('thu_tu_hien_thi', ascending: true);

      return (response as List)
          .map((json) => PaymentMethod.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting all payment methods: $e');
      return [];
    }
  }

  /// Lấy phương thức thanh toán theo mã
  static Future<PaymentMethod?> getPaymentMethodByCode(String code) async {
    try {
      final response = await _client
          .from('payment_methods_settings')
          .select()
          .eq('ma_phuong_thuc', code)
          .eq('da_kich_hoat', true)
          .maybeSingle();

      if (response == null) return null;
      return PaymentMethod.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error getting payment method by code: $e');
      return null;
    }
  }
}

