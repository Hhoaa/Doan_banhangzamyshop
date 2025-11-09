import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/size.dart';
import '../models/color.dart';
import '../models/product_variant.dart';
import '../config/supabase_config.dart';

class SupabaseProductService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Lấy danh sách sản phẩm với tìm kiếm và lọc
  static Future<List<Product>> getProducts({
    int? categoryId,
    String? search,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 20,
  }) async {
        try {
          print('Fetching products with limit: $limit');
          dynamic query = _client
              .from('products')
              .select('*, product_images(duong_dan_anh)');

      // Filter by category
      if (categoryId != null) {
        query = query.eq('ma_danh_muc', categoryId);
      }

      // Search by name
      if (search != null && search.isNotEmpty) {
        query = query.ilike('ten_san_pham', '%$search%');
      }

      // Filter by price range
      if (minPrice != null && minPrice > 0) {
        query = query.gte('gia_ban', minPrice);
      }
      if (maxPrice != null && maxPrice > 0) {
        query = query.lte('gia_ban', maxPrice);
      }

      // Sort
      switch (sortBy) {
        case 'price_asc':
          query = query.order('gia_ban', ascending: true);
          break;
        case 'price_desc':
          query = query.order('gia_ban', ascending: false);
          break;
        case 'name_asc':
          query = query.order('ten_san_pham', ascending: true);
          break;
        case 'name_desc':
          query = query.order('ten_san_pham', ascending: false);
          break;
        default:
          query = query.order('ngay_tao_ban_ghi', ascending: false);
      }

      // Pagination
      final offset = (page - 1) * limit;
      query = query.range(offset, offset + limit - 1);

      final response = await query;
      print('Raw products response: ${response.length} items');

      final products = (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('Successfully parsed ${products.length} products');
      return products;
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  // Lấy danh sách sản phẩm nổi bật (sản phẩm bán chạy nhất)
 // Lấy danh sách sản phẩm bán chạy nhất trong tháng hiện tại
static Future<List<Product>> getFeaturedProducts({int limit = 8}) async {
  try {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    print('Fetching top $limit best-selling products in ${now.month}/${now.year}...');

    // Bước 1: Lấy chi tiết đơn hàng trong tháng hiện tại (lọc theo order_date)
    final response = await _client
        .from('order_details')
        .select('''
          so_luong_mua,
          orders(ngay_dat_hang),
          product_variants!ma_bien_the_san_pham(ma_san_pham)
        ''')
        .gte('orders.ngay_dat_hang', startOfMonth.toIso8601String())
        .lte('orders.ngay_dat_hang', endOfMonth.toIso8601String());

    if ((response as List).isEmpty) {
      print('No order details found for this month');
      return [];
    }

    // Bước 2: Tính tổng số lượng bán theo sản phẩm
    final productSales = <int, int>{};
    for (final item in response) {
      final qty = item['so_luong_mua'] as int? ?? 0;
      final variantData = item['product_variants'] as Map<String, dynamic>?;
      final productId = variantData?['ma_san_pham'] as int?;
      if (productId != null) {
        productSales[productId] = (productSales[productId] ?? 0) + qty;
      }
    }

    if (productSales.isEmpty) {
      print('No sales data this month');
      return [];
    }

    // Bước 3: Sắp xếp giảm dần theo số lượng bán và lấy top N
    final topProductIds = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topIds = topProductIds.take(limit).map((e) => e.key).toList();

    // Bước 4: Lấy thông tin sản phẩm + ảnh
    final productsResponse = await _client
        .from('products')
        .select('*, product_images(duong_dan_anh)')
        .inFilter('ma_san_pham', topIds);

    final products = (productsResponse as List)
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();

    // Bước 5: Sắp xếp lại theo số lượng bán
    products.sort((a, b) {
      final aSales = productSales[a.maSanPham] ?? 0;
      final bSales = productSales[b.maSanPham] ?? 0;
      return bSales.compareTo(aSales);
    });

    print('Loaded ${products.length} best-selling products for this month');
    return products;
  } catch (e, stackTrace) {
    print('Error in getFeaturedProducts: $e');
    print('Stack trace: $stackTrace');
    return [];
  }
}


  // Lấy chi tiết sản phẩm
  static Future<Product?> getProductById(int productId) async {
    try {
      final response = await _client
          .from('products')
          .select('*, product_images(duong_dan_anh)')
          .eq('ma_san_pham', productId)
          .maybeSingle();

      if (response != null) {
        return Product.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  // Lấy danh mục
  static Future<List<Category>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select('*');

      return (response as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Lấy sizes
  static Future<List<Size>> getSizes() async {
    try {
      final response = await _client
          .from('sizes')
          .select('*');

      return (response as List)
          .map((json) => Size.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting sizes: $e');
      return [];
    }
  }

  // Lấy màu sắc
  static Future<List<ColorModel>> getColors() async {
    try {
      final response = await _client
          .from('colors')
          .select('*');

      return (response as List)
          .map((json) => ColorModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting colors: $e');
      return [];
    }
  }

  // Lấy biến thể sản phẩm
  static Future<List<ProductVariant>> getProductVariants(int productId) async {
    try {
      final response = await _client
          .from('product_variants')
          .select('*')
          .eq('ma_san_pham', productId);

      return (response as List)
          .map((json) => ProductVariant.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting product variants: $e');
      return [];
    }
  }

  // Tìm kiếm sản phẩm - version đơn giản
  static Future<List<Product>> searchProducts(String query) async {
    try {
      // Tạm thời trả về tất cả sản phẩm
      final response = await _client
          .from('products')
          .select('*')
          .limit(20);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // Lấy sản phẩm liên quan
  static Future<List<Product>> getRelatedProducts(String productId) async {
    try {
      // Tạm thời trả về danh sách rỗng
      return [];
    } catch (e) {
      print('Error getting related products: $e');
      return [];
    }
  }

  // Lấy hình ảnh sản phẩm
  static Future<List<String>> getProductImages(String productId) async {
    try {
      final response = await _client
          .from('product_images')
          .select('duong_dan_anh')
          .eq('ma_san_pham', productId);

      return (response as List)
          .map((json) => json['duong_dan_anh'] as String)
          .toList();
    } catch (e) {
      print('Error getting product images: $e');
      return [];
    }
  }
}