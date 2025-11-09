import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/supabase_product_service.dart';
import '../../services/supabase_review_service.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/common/search_bar.dart';
import '../../widgets/product/price_filter_widget.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ai_search_service.dart';
import 'product_detail_screen.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/product/product_options_bottom_sheet.dart';
import 'package:provider/provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/ai_chat/bubble_visibility.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' hide Category;

class ProductsScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategoryName;
  const ProductsScreen({
    super.key,
    this.initialQuery,
    this.initialCategoryName,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Category> _categories = [];
  List<Product> _filteredProducts = [];
  Map<int, Map<String, num>> _productRatings = {}; // productId -> {avg,count}
  String _selectedCategory = 'Tất cả';
  String _sortBy = 'newest';
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  // Phân trang
  int _currentPage = 1;
  static const int _itemsPerPage = 8; // 8 items/trang
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Price filter state
  double _minPrice = 0;
  double _maxPrice = 5000000;
  double _selectedMinPrice = 0;
  double _selectedMaxPrice = 5000000;

  @override
  void initState() {
    super.initState();
    // Show chat bubble on Products screen
    BubbleVisibility.show();
    _applyInitialParams();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant ProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newQuery = widget.initialQuery?.trim() ?? '';
    final oldQuery = oldWidget.initialQuery?.trim() ?? '';
    final newCat = widget.initialCategoryName?.trim() ?? '';
    final oldCat = oldWidget.initialCategoryName?.trim() ?? '';
    if (newQuery != oldQuery || newCat != oldCat) {
      if (widget.initialQuery != null) {
        _searchController.text = widget.initialQuery!;
      }
      // Validate category exists before setting
      if (widget.initialCategoryName != null &&
          widget.initialCategoryName!.isNotEmpty) {
        final categoryName = widget.initialCategoryName!.trim();
        final categoryExists = _categories.any(
          (c) => c.tenDanhMuc == categoryName,
        );
        if (categoryExists) {
          _selectedCategory = categoryName;
        } else {
          _selectedCategory = 'Tất cả';
        }
      } else {
        _selectedCategory = 'Tất cả';
      }
      _filterProducts();
    }
  }

  void _applyInitialParams() {
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    // Category will be set after categories are loaded
  }

  void _applyCategoryFromParams() {
    if (widget.initialCategoryName != null &&
        widget.initialCategoryName!.trim().isNotEmpty) {
      final categoryName = widget.initialCategoryName!.trim();
      // Check if category exists in the loaded categories
      final categoryExists = _categories.any(
        (c) => c.tenDanhMuc == categoryName,
      );
      if (categoryExists) {
        _selectedCategory = categoryName;
      } else {
        // If category doesn't exist, reset to "Tất cả"
        _selectedCategory = 'Tất cả';
      }
    } else {
      _selectedCategory = 'Tất cả';
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load categories first
      final categories = await SupabaseProductService.getCategories();

      // Get max price from all products to initialize price filter
      final allProducts = await SupabaseProductService.getProducts(limit: 1000);
      double maxPrice = 5000000; // Default max price
      if (allProducts.isNotEmpty) {
        maxPrice = allProducts
            .map((p) => p.giaBan)
            .reduce((a, b) => a > b ? a : b);
        maxPrice = maxPrice * 1.1; // Add 10% buffer
      }

      setState(() {
        _categories = categories;
        _maxPrice = maxPrice;
        _selectedMaxPrice = maxPrice;
        // Apply category from params after categories are loaded
        _applyCategoryFromParams();
        _isLoading = false;
      });

      // Load initial products
      _filterProducts();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
        );
      }
    }
  }

  void _filterProducts() async {
    try {
      setState(() => _isLoading = true);

      // Get category ID if not "Tất cả"
      String? categoryId;
      if (_selectedCategory != 'Tất cả') {
        final category = _categories.firstWhere(
          (cat) => cat.tenDanhMuc == _selectedCategory,
          orElse:
              () => Category(
                maDanhMuc: 0,
                tenDanhMuc: '',
                createdAt: DateTime.now(),
              ),
        );
        categoryId = category.maDanhMuc.toString();
      }

      // Map sort options
      String? sortBy;
      switch (_sortBy) {
        case 'price_low_high':
          sortBy = 'price_asc';
          break;
        case 'price_high_low':
          sortBy = 'price_desc';
          break;
        case 'name_az':
          sortBy = 'name_asc';
          break;
        default:
          sortBy = null; // Default sort by creation date
      }

      // Reset pagination khi filter
      _currentPage = 1;
      _hasMore = true;

      // Fetch filtered products với phân trang
      final products = await SupabaseProductService.getProducts(
        categoryId: categoryId != null ? int.parse(categoryId) : null,
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        sortBy: sortBy,
        minPrice: _selectedMinPrice > 0 ? _selectedMinPrice : null,
        maxPrice: _selectedMaxPrice < _maxPrice ? _selectedMaxPrice : null,
        page: _currentPage,
        limit: _itemsPerPage,
      );

      // Kiểm tra còn dữ liệu không
      _hasMore = products.length >= _itemsPerPage;

      // Note: maxPrice is already set during initial load

      // Load ratings for all products
      final ratingsEntries = await Future.wait(
        products.map((p) async {
          final stats = await SupabaseReviewService.getProductReviewStats(
            p.maSanPham,
          );
          return MapEntry(p.maSanPham, {
            'avg': (stats['averageRating'] ?? 0.0) as num,
            'count': (stats['totalReviews'] ?? 0) as num,
          });
        }),
      );
      final productRatings = {for (final e in ratingsEntries) e.key: e.value};

      // Sync favorites via provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        await Provider.of<FavoritesProvider>(
          context,
          listen: false,
        ).ensureLoaded(authProvider.user!.maNguoiDung);
      }

      setState(() {
        _filteredProducts = products;
        _productRatings = productRatings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
        );
      }
    }
  }

  // Load more products (phân trang)
  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    try {
      setState(() => _isLoadingMore = true);

      _currentPage++;

      // Get category ID if not "Tất cả"
      String? categoryId;
      if (_selectedCategory != 'Tất cả') {
        final category = _categories.firstWhere(
          (cat) => cat.tenDanhMuc == _selectedCategory,
          orElse:
              () => Category(
                maDanhMuc: 0,
                tenDanhMuc: '',
                createdAt: DateTime.now(),
              ),
        );
        categoryId = category.maDanhMuc.toString();
      }

      // Map sort options
      String? sortBy;
      switch (_sortBy) {
        case 'price_low_high':
          sortBy = 'price_asc';
          break;
        case 'price_high_low':
          sortBy = 'price_desc';
          break;
        case 'name_az':
          sortBy = 'name_asc';
          break;
        default:
          sortBy = null;
      }

      // Fetch more products
      final products = await SupabaseProductService.getProducts(
        categoryId: categoryId != null ? int.parse(categoryId) : null,
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        sortBy: sortBy,
        minPrice: _selectedMinPrice > 0 ? _selectedMinPrice : null,
        maxPrice: _selectedMaxPrice < _maxPrice ? _selectedMaxPrice : null,
        page: _currentPage,
        limit: _itemsPerPage,
      );

      // Kiểm tra còn dữ liệu không
      _hasMore = products.length >= _itemsPerPage;

      // Load ratings cho products mới
      final ratingsEntries = await Future.wait(
        products.map((p) async {
          final stats = await SupabaseReviewService.getProductReviewStats(
            p.maSanPham,
          );
          return MapEntry(p.maSanPham, {
            'avg': (stats['averageRating'] ?? 0.0) as num,
            'count': (stats['totalReviews'] ?? 0) as num,
          });
        }),
      );
      final newRatings = {for (final e in ratingsEntries) e.key: e.value};

      setState(() {
        _filteredProducts.addAll(products);
        _productRatings.addAll(newRatings);
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          kIsWeb
              ? null
              : AppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                title: Text(
                  AppLocalizations.of(context).products,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                actions: [
                  // removed notification icon on product screen per request
                ],
              ),
      body: kIsWeb ? _buildWebLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildWebLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar with filters
          Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              border: Border(
                right: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price filter
                  PriceFilterWidget(
                    minPrice: _minPrice,
                    maxPrice: _maxPrice,
                    onChanged: (values) {
                      setState(() {
                        _selectedMinPrice = values.start;
                        _selectedMaxPrice = values.end;
                      });
                      _filterProducts();
                    },
                  ),
                  const SizedBox(height: 20),
                  // Category filter
                  Text(
                    AppLocalizations.of(context).translate('categories'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...['Tất cả', ..._categories.map((c) => c.tenDanhMuc)].map((
                    category,
                  ) {
                    final isSelected = _selectedCategory == category;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedCategory = category);
                        _filterProducts();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.accentRed.withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.accentRed,
                              ),
                            if (isSelected) const SizedBox(width: 8),
                            Text(
                              category == 'Tất cả'
                                  ? AppLocalizations.of(
                                    context,
                                  ).translate('all_categories')
                                  : category,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isSelected
                                        ? AppColors.accentRed
                                        : AppColors.textPrimary,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Search and Sort bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomSearchBar(
                          controller: _searchController,
                          hintText: AppLocalizations.of(
                            context,
                          ).translate('search_placeholder'),
                          onChanged: (value) => _filterProducts(),
                          onPickImage: _onPickSearchImage,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: PopupMenuButton<String>(
                          initialValue: _sortBy,
                          onSelected: (value) {
                            setState(() => _sortBy = value);
                            _filterProducts();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.sort,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _sortLabel(context, _sortBy),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                          itemBuilder:
                              (context) => [
                                PopupMenuItem(
                                  value: 'newest',
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).translate('sort_newest'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'price_low_high',
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).translate('sort_price_low_high'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'price_high_low',
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).translate('sort_price_high_low'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'name_az',
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).translate('sort_name_az'),
                                  ),
                                ),
                              ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Products Grid
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredProducts.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).translate('no_products_found'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final width = constraints.maxWidth;
                                  int columns = 4;
                                  if (width >= 1600) {
                                    columns = 5;
                                  } else if (width >= 1200) {
                                    columns = 4;
                                  } else if (width >= 900) {
                                    columns = 3;
                                  } else {
                                    columns = 2;
                                  }
                                  return Column(
                                    children: [
                                      Expanded(
                                        child: GridView.builder(
                                          padding: const EdgeInsets.all(16),
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: columns,
                                                crossAxisSpacing: 16,
                                                mainAxisSpacing: 16,
                                                childAspectRatio: kIsWeb ? 0.75 : 0.42,
                                              ),
                                          itemCount: _filteredProducts.length,
                                          itemBuilder: (context, index) {
                                            final product =
                                                _filteredProducts[index];
                                            return Consumer<FavoritesProvider>(
                                              builder: (
                                                context,
                                                favoritesProvider,
                                                _,
                                              ) {
                                                return ProductCard(
                                                  product: product,
                                                  minHeight:
                                                      400, // Tăng từ 250 lên 400 để ảnh có không gian
                                                  rating:
                                                      (_productRatings[product
                                                                  .maSanPham]?['avg'] ??
                                                              0.0)
                                                          .toDouble(),
                                                  reviewCount:
                                                      (_productRatings[product
                                                                  .maSanPham]?['count'] ??
                                                              0)
                                                          .toInt(),
                                                  onTap:
                                                      () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                context,
                                                              ) => ProductDetailScreen(
                                                                productId:
                                                                    product
                                                                        .maSanPham,
                                                              ),
                                                        ),
                                                      ),
                                                  onFavorite:
                                                      () => _toggleFavorite(
                                                        product.maSanPham,
                                                      ),
                                                  onAddToCart:
                                                      () =>
                                                          _showProductOptionsBottomSheet(
                                                            product,
                                                          ),
                                                  onBuyNow:
                                                      () =>
                                                          _showBuyNowBottomSheet(
                                                            product,
                                                          ),
                                                  isFavorite: favoritesProvider
                                                      .isFavorite(
                                                        product.maSanPham,
                                                      ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      // Load more button cho web layout
                                      if (_hasMore && !_isLoadingMore)
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: ElevatedButton(
                                            onPressed: _loadMoreProducts,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.accentRed,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 32,
                                                    vertical: 14,
                                                  ),
                                            ),
                                            child: Text(
                                              AppLocalizations.of(
                                                    context,
                                                  ).translate('load_more'),
                                            ),
                                          ),
                                        ),
                                      if (_isLoadingMore)
                                        const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(
                                            color: AppColors.accentRed,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomSearchBar(
            controller: _searchController,
            hintText: AppLocalizations.of(
              context,
            ).translate('search_placeholder'),
            onChanged: (value) => _filterProducts(),
            onPickImage: _onPickSearchImage,
          ),
        ),

        // Price Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PriceFilterWidget(
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            onChanged: (values) {
              setState(() {
                _selectedMinPrice = values.start;
                _selectedMaxPrice = values.end;
              });
              _filterProducts();
            },
          ),
        ),

        const SizedBox(height: 16),

        // Filter and Sort Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Category Filter
              Expanded(
                child: Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final small = screenWidth < 360;
                    final itemTextStyle = TextStyle(
                      fontSize: small ? 12 : 14,
                      color: AppColors.textPrimary,
                    );
                    final validItems = [
                      'Tất cả',
                      ..._categories.map((c) => c.tenDanhMuc),
                    ];
                    final validValue =
                        validItems.contains(_selectedCategory)
                            ? _selectedCategory
                            : 'Tất cả';

                    return DropdownButtonFormField<String>(
                      value: validValue,
                      isExpanded: true,
                      isDense: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      selectedItemBuilder: (context) {
                        final items = [
                          'Tất cả',
                          ..._categories.map((c) => c.tenDanhMuc),
                        ];
                        return items.map((value) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value == 'Tất cả'
                                  ? AppLocalizations.of(
                                    context,
                                  ).translate('all_categories')
                                  : value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: itemTextStyle,
                            ),
                          );
                        }).toList();
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'Tất cả',
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).translate('all_categories'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: itemTextStyle,
                          ),
                        ),
                        ..._categories.map(
                          (category) => DropdownMenuItem(
                            value: category.tenDanhMuc,
                            child: Text(
                              category.tenDanhMuc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: itemTextStyle,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategory = value!);
                        _filterProducts();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Sort Button
              Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final small = screenWidth < 360;
                  final labelStyle = TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: small ? 12 : 14,
                  );
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: PopupMenuButton<String>(
                      initialValue: _sortBy,
                      onSelected: (value) {
                        setState(() => _sortBy = value);
                        _filterProducts();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.sort,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _sortLabel(context, _sortBy),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: labelStyle,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'newest',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('sort_newest'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'price_low_high',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('sort_price_low_high'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'price_high_low',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('sort_price_high_low'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'name_az',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('sort_name_az'),
                              ),
                            ),
                          ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Products Grid
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(
                            context,
                          ).translate('no_products_found'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).translate('no_products'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                  : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      int columns = 2;
                      if (width >= 1600) {
                        columns = 5;
                      } else if (width >= 1300) {
                        columns = 4;
                      } else if (width >= 900) {
                        columns = 3;
                      }
                      return Column(
                        children: [
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: kIsWeb ? 0.75 : 0.42,
                                  ),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return Consumer<FavoritesProvider>(
                                  builder: (context, favoritesProvider, _) {
                                    return ProductCard(
                                      product: product,
                                      minHeight:
                                          400, // Tăng từ 250 lên 400 để ảnh có không gian
                                      rating:
                                          (_productRatings[product
                                                      .maSanPham]?['avg'] ??
                                                  0.0)
                                              .toDouble(),
                                      reviewCount:
                                          (_productRatings[product
                                                      .maSanPham]?['count'] ??
                                                  0)
                                              .toInt(),
                                      onTap:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      ProductDetailScreen(
                                                        productId:
                                                            product.maSanPham,
                                                      ),
                                            ),
                                          ),
                                      onFavorite:
                                          () => _toggleFavorite(
                                            product.maSanPham,
                                          ),
                                      onAddToCart:
                                          () => _showProductOptionsBottomSheet(
                                            product,
                                          ),
                                      onBuyNow:
                                          () => _showBuyNowBottomSheet(product),
                                      isFavorite: favoritesProvider.isFavorite(
                                        product.maSanPham,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          // Load more button ở dưới
                          if (_hasMore && !_isLoadingMore)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ElevatedButton(
                                onPressed: _loadMoreProducts,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                        context,
                                      ).translate('load_more'),
                                ),
                              ),
                            ),
                          if (_isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: AppColors.accentRed,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
        ),
      ],
    );
  }

  String _sortLabel(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context);
    switch (value) {
      case 'newest':
        return l10n.translate('sort_newest');
      case 'price_low_high':
        return l10n.translate('sort_price_low_high');
      case 'price_high_low':
        return l10n.translate('sort_price_high_low');
      case 'name_az':
        return l10n.translate('sort_name_az');
      default:
        return value;
    }
  }

  Future<void> _toggleFavorite(int productId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).translate('please_login_for_favorites'),
            ),
          ),
        );
        return;
      }
      final fav = Provider.of<FavoritesProvider>(context, listen: false);
      await fav.toggle(authProvider.user!.maNguoiDung, productId);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
      );
    }
  }

  void _showProductOptionsBottomSheet(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ProductOptionsBottomSheet(
            product: product,

            onAddedToCart: () {
              // Optionally refresh data or show success message
            },
          ),
    );
  }

  void _showBuyNowBottomSheet(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) =>
              ProductOptionsBottomSheet(product: product, isBuyNow: true),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onPickSearchImage() async {
    try {
      // Hỏi người dùng chọn nguồn ảnh: camera hay thư viện
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder:
            (context) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: Text(
                      AppLocalizations.of(context).translate('take_photo'),
                    ),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: Text(
                      AppLocalizations.of(
                        context,
                      ).translate('choose_from_gallery'),
                    ),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            ),
      );
      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _isLoading = true);
      final resp = await AISearchService.searchByImage(
        message: _searchController.text.trim(),
        image: image,
      );

      final products = (resp['products'] as List<dynamic>? ?? []);
      final mapped =
          products.map<Product>((p) {
            return Product(
              maSanPham:
                  p['id'] is int ? p['id'] : int.parse(p['id'].toString()),
              tenSanPham: p['name'] ?? '',
              moTaSanPham: p['description'],
              mucGiaGoc: (p['original_price'] ?? 0).toDouble(),
              giaBan: (p['price'] ?? 0).toDouble(),
              soLuongDatToiThieu: 1,
              trangThaiHienThi: true,
              ngayTaoBanGhi: DateTime.now(),
              ngaySuaBanGhi: null,
              maDanhMuc: 0,
              maBoSuuTap: null,
              maGiamGia: null,
              hinhAnh: List<String>.from(p['images'] ?? const []),
            );
          }).toList();

      setState(() {
        _filteredProducts = mapped;
        _isLoading = false;
      });
    } catch (e, st) {
      // Print logs to console only
      // ignore: avoid_print
      print('[AI-SEARCH][ERROR] $e');
      // ignore: avoid_print
      print(st);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('no_results_try_another'),
            ),
          ),
        );
      }
    }
  }
}
