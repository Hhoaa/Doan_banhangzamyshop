import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../product/products_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/web_ui_provider.dart';

class ProductsWebScreen extends StatelessWidget {
  const ProductsWebScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final webUi = context.watch<WebUiProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumbs
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: const [
              Text('Trang chủ', style: TextStyle(color: AppColors.textSecondary)),
              SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text('Sản phẩm', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ProductsScreen(
            key: ValueKey('${webUi.searchQuery}|${webUi.selectedCategoryName ?? ''}'),
            initialQuery: webUi.searchQuery,
            initialCategoryName: webUi.selectedCategoryName,
          ),
        ),
      ],
    );
  }
}


