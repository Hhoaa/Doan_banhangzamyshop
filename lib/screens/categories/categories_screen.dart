import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../../theme/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/product/product_card.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/supabase_product_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> categories = [];
  List<Product> products = [];
  int? selectedCategoryId;
  bool isLoading = true;
  bool isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categoriesData = await SupabaseProductService.getCategories();
      setState(() {
        categories = categoriesData;
        isLoading = false;
      });
      
      // Load products for first category
      if (categories.isNotEmpty) {
        _loadProducts(categories.first.maDanhMuc);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadProducts(int categoryId) async {
    setState(() {
      isLoadingProducts = true;
      selectedCategoryId = categoryId;
    });

    try {
      final productsData = await SupabaseProductService.getProducts(
        categoryId: categoryId,
        limit: 20,
      );
      setState(() {
        products = productsData;
        isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        isLoadingProducts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Danh mục sản phẩm'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  children: [
                    _buildCategoriesList(),
                    _buildProductsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategoriesList() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategoryId == category.maDanhMuc;
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _loadProducts(category.maDanhMuc),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentRed : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppColors.accentRed : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  category.tenDanhMuc,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              selectedCategoryId != null 
                  ? categories.firstWhere((c) => c.maDanhMuc == selectedCategoryId).tenDanhMuc
                  : 'Sản phẩm',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: isLoadingProducts
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? _buildEmptyProducts()
                    : _buildProductsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProducts() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.textLight,
          ),
          SizedBox(height: 16),
          Text(
            'Không có sản phẩm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Danh mục này chưa có sản phẩm nào',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns = 2;
        if (width >= 1600) columns = 5;
        else if (width >= 1300) columns = 4;
        else if (width >= 900) columns = 3;
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: kIsWeb ? 0.75 : 0.42,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(
              product: products[index],
              onTap: () {},
              onFavorite: () {},
            );
          },
        );
      },
    );
  }
}
