import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/web/web_header.dart';
import '../../widgets/web/web_footer.dart';

class WebShell extends StatelessWidget {
  final Widget child;
  final bool showWebHeader;
  final bool showTopBar;
  final bool showFooter;

  const WebShell({
    super.key,
    required this.child,
    this.showWebHeader = true,
    this.showTopBar = false,
    this.showFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Content area (behind header)
          Column(
            children: [
              // Top bar "THEO DOI CHÚNG TÔI" - Sticky
              //  if (showTopBar) _buildTopBar(),
              // Scrollable content area with footer
              Expanded(child: _buildScrollableContent()),
            ],
          ),
          // Header on top (always clickable) - z-index cao nhất, sticky
          if (showTopBar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.white,
                elevation: 2,
                child: _buildTopBar(),
              ),
            ),
          if (showWebHeader)
            Positioned(
              top: showTopBar ? 40 : 0,
              left: 0,
              right: 0,
              child: Material(
                color: AppColors.background,
                elevation: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [const WebHeader(), const Divider(height: 1)],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScrollableContent() {
    // Tính toán height của header để tránh content che header
    final headerHeight =
        (showTopBar ? 40.0 : 0.0) + (showWebHeader ? 57.0 : 0.0);

    // Sử dụng CustomScrollView với SliverFillRemaining để child chiếm toàn bộ không gian
    // và footer sẽ nằm ở cuối scroll area
    return CustomScrollView(
      slivers: [
        // Padding để tránh content che header
        if (headerHeight > 0)
          SliverToBoxAdapter(child: SizedBox(height: headerHeight)),
        // Main content - sử dụng SliverFillRemaining để child chiếm toàn bộ không gian
        SliverFillRemaining(
          hasScrollBody: false, // Child tự xử lý scroll
          child: child,
        ),
        // Footer - nằm ở cuối scrollable content
        if (showFooter) const SliverToBoxAdapter(child: WebFooter()),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(children: [
            ],
          ),
        ),
      ),
    );
  }
}
