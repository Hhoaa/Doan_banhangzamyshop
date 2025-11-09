import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Thêm gói http
import 'dart:convert'; // Thêm để xử lý JSON
import '../models/review.dart';
import '../config/supabase_config.dart';

class SupabaseReviewService {
  static SupabaseClient get _client => SupabaseConfig.client;
  static const String _bucket = 'review-images';

  // LẤY DANH SÁCH BÌNH LUẬN THEO SẢN PHẨM (HIỂN THỊ PHÂN CẤP ĐẦY ĐỦ)
  static Future<List<Review>> getProductReviews(
    int productId, {
    int? ratingFilter,
  }) async {
    try {
      print('[DEBUG] Getting reviews for product: $productId, filter: $ratingFilter');

      var query = _client
          .from('reviews')
          .select('''
            *,
            users!inner(ten_nguoi_dung, avatar),
            review_images(*)
          ''')
          .eq('ma_san_pham', productId)
          .eq('trang_thai', 1)
          .filter('ma_danh_gia_cha', 'is', null);

      if (ratingFilter != null && ratingFilter > 0) {
        query = query.eq('diem_danh_gia', ratingFilter);
      }

      final reviewsResponse = await query.order('thoi_gian_tao', ascending: false);
      print('[DEBUG] Found ${reviewsResponse.length} parent reviews');

      final List<Review> result = [];

      for (final reviewData in reviewsResponse) {
        final parentReview = Review.fromJson(reviewData);

        // Gọi đệ quy để lấy toàn bộ phản hồi con
        final replies = await _fetchRepliesRecursively(parentReview.maDanhGia);

        result.add(
          Review(
            maDanhGia: parentReview.maDanhGia,
            maSanPham: parentReview.maSanPham,
            maNguoiDung: parentReview.maNguoiDung,
            tenNguoiDung: parentReview.tenNguoiDung,
            avatarNguoiDung: parentReview.avatarNguoiDung,
            diemDanhGia: parentReview.diemDanhGia,
            noiDungDanhGia: parentReview.noiDungDanhGia,
            ngayTao: parentReview.ngayTao,
            ngaySua: parentReview.ngaySua,
            trangThaiHienThi: parentReview.trangThaiHienThi,
            hinhAnh: parentReview.hinhAnh,
            maDanhGiaCha: parentReview.maDanhGiaCha,
            replies: replies,
          ),
        );
      }

      return result;
    } catch (e, stackTrace) {
      print('[DEBUG] Error getting product reviews: $e');
      print('[DEBUG] Stack trace: $stackTrace');
      return [];
    }
  }

  // HÀM ĐỆ QUY LẤY CÁC PHẢN HỒI CON NHIỀU CẤP
  static Future<List<Review>> _fetchRepliesRecursively(int parentId) async {
    try {
      final repliesResponse = await _client
          .from('reviews')
          .select('''
            *,
            users!inner(ten_nguoi_dung, avatar),
            review_images(*)
          ''')
          .eq('ma_danh_gia_cha', parentId)
          .eq('trang_thai', 1)
          .order('thoi_gian_tao', ascending: true);

      if (repliesResponse.isEmpty) return [];

      final List<Review> replies = [];

      for (final replyData in repliesResponse) {
        final reply = Review.fromJson(replyData);
        final subReplies = await _fetchRepliesRecursively(reply.maDanhGia); // Đệ quy
        replies.add(
          Review(
            maDanhGia: reply.maDanhGia,
            maSanPham: reply.maSanPham,
            maNguoiDung: reply.maNguoiDung,
            tenNguoiDung: reply.tenNguoiDung,
            avatarNguoiDung: reply.avatarNguoiDung,
            diemDanhGia: reply.diemDanhGia,
            noiDungDanhGia: reply.noiDungDanhGia,
            ngayTao: reply.ngayTao,
            ngaySua: reply.ngaySua,
            trangThaiHienThi: reply.trangThaiHienThi,
            hinhAnh: reply.hinhAnh,
            maDanhGiaCha: reply.maDanhGiaCha,
            replies: subReplies,
          ),
        );
      }

      return replies;
    } catch (e, stackTrace) {
      print('[DEBUG] Error fetching replies recursively: $e');
      print('[DEBUG] Stack trace: $stackTrace');
      return [];
    }
  }

  // LẤY THỐNG KÊ ĐÁNH GIÁ (TÍNH CẢ CON, CHỈ TRẠNG THÁI = 1)
  static Future<Map<String, dynamic>> getProductReviewStats(int productId) async {
    try {
      final allReviews = await _client
          .from('reviews')
          .select('diem_danh_gia, trang_thai, ma_danh_gia_cha')
          .eq('ma_san_pham', productId)
          .eq('trang_thai', 1); // chỉ lấy những bình luận trạng thái = 1

      if (allReviews.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      // Đếm tổng tất cả các review (bao gồm cả con) có trạng thái = 1
      final totalReviews = allReviews.length;

      // Trung bình và phân bố sao chỉ tính các đánh giá cha
      final parentReviews =
          allReviews.where((r) => r['ma_danh_gia_cha'] == null).toList();

      if (parentReviews.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': totalReviews,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final ratings = parentReviews
          .map<int>((data) => (data['diem_danh_gia'] as num).toInt())
          .toList();

      final averageRating =
          ratings.isNotEmpty ? ratings.reduce((a, b) => a + b) / ratings.length : 0.0;

      final ratingDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = ratings.where((r) => r == i).length;
      }

      return {
        'averageRating': averageRating,
        'totalReviews': totalReviews, // cập nhật đếm tất cả trạng thái = 1
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      print('Error getting product review stats: $e');
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  // === THÊM BÌNH LUẬN - GỌI API PHP ===
  static Future<bool> addReview({
    required int productId,
    required int userId,
    required int rating,
    required String comment,
    List<XFile>? images,
    int? parentReviewId,
  }) async {
    try {
      print('[DEBUG] Thêm bình luận cho sản phẩm: $productId');
      print('[DEBUG] Người dùng: $userId');
      print('[DEBUG] Điểm đánh giá: $rating, Nội dung: $comment');
      print('[DEBUG] Số lượng hình ảnh: ${images?.length ?? 0}');

      // Chuẩn bị dữ liệu gửi tới API PHP
      final reviewData = {
        'ma_san_pham': productId,
        'ma_nguoi_dung': userId,
        'noi_dung_danh_gia': comment,
        if (parentReviewId == null) 'diem_danh_gia': rating,
        if (parentReviewId != null) 'ma_danh_gia_cha': parentReviewId,
      };

      // Gọi API PHP
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/add_review.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reviewData),
      ).timeout(const Duration(seconds: 10));

      print('[DEBUG] Trạng thái phản hồi API: ${response.statusCode}');
      print('[DEBUG] Nội dung phản hồi API: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['error'] == false) {
          final reviewId = result['ma_danh_gia'];
          if (reviewId != null && images != null && images.isNotEmpty) {
            await _uploadReviewImages(reviewId, images);
          }
          return true;
        }
      }
      return false;
    } catch (e, stackTrace) {
      print('[DEBUG] Lỗi khi thêm bình luận: $e');
      print('[DEBUG] Stack trace: $stackTrace');
      return false;
    }
  }

  // TẢI LÊN HÌNH ẢNH BÌNH LUẬN
  static Future<void> _uploadReviewImages(
    int reviewId,
    List<XFile> images,
  ) async {
    try {
      print('[DEBUG] Uploading ${images.length} images for review: $reviewId');

      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        final fileName =
            'review_${reviewId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final filePath = 'reviews/$fileName';

        final fileBytes = await image.readAsBytes();
        final uploadRes = await _client.storage.from(_bucket).uploadBinary(
              filePath,
              fileBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        print('[DEBUG] Storage upload result: $uploadRes');

        final imageUrl = _client.storage.from(_bucket).getPublicUrl(filePath);
        print('[DEBUG] Public URL: $imageUrl');

        final insertImg = await _client.from('review_images').insert({
          'ma_danh_gia': reviewId,
          'duong_dan_anh': imageUrl,
        }).select();

        print('[DEBUG] Image $i inserted: $insertImg');
      }
    } catch (e, stackTrace) {
      print('[DEBUG] Error uploading review images: $e');
      print('[DEBUG] Stack trace: $stackTrace');
    }
  }

  // CẬP NHẬT BÌNH LUẬN
  static Future<bool> updateReview({
    required int reviewId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _client
          .from('reviews')
          .update({
            'diem_danh_gia': rating,
            'noi_dung_danh_gia': comment,
            'ngay_sua': DateTime.now().toIso8601String(),
          })
          .eq('ma_danh_gia', reviewId);

      return true;
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  // XÓA BÌNH LUẬN
  static Future<bool> deleteReview(int reviewId) async {
    try {
      await _client
          .from('reviews')
          .update({'trang_thai': 0})
          .eq('ma_danh_gia', reviewId);

      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }
}
