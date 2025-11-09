import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/web_ui_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../screens/web/auth_combined_web_screen.dart';
import '../../screens/collections/collections_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/favorites/favorites_screen.dart';
import '../../screens/about/about_us_screen.dart';
import '../../navigation/navigator_key.dart';
import '../../screens/main/main_web_screen.dart';
import '../language_selector.dart';
import '../../l10n/app_localizations.dart';

class WebHeader extends StatefulWidget {
  const WebHeader({super.key});

  @override
  State<WebHeader> createState() => _WebHeaderState();
}

class _WebHeaderState extends State<WebHeader> {
  // Navigation menu items
  final List<String> _navCategories = [
    'ĐẦM',
    'ÁO',
    'QUẦN',
    'CHÂN VÁY',
    'LOOKBOOK',
    'VỀ CHÚNG TÔI',
  ];

  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    // Load favorites when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavoritesIfNeeded();
    });
  }

  void _loadFavoritesIfNeeded() {
    final auth = context.read<AuthProvider>();
    final favorites = context.read<FavoritesProvider>();
    if (auth.user != null) {
      favorites.ensureLoaded(auth.user!.maNguoiDung);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main header with logo, navigation, cart, account
        Container(
          color: AppColors.background,
          padding: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Row(
                children: [
                  // Logo / Brand
                  InkWell(
                    onTap: () {
                      _popCollectionsScreenIfExists();
                      context.read<WebUiProvider>().setSearchQuery('');
                      context.read<WebUiProvider>().setSelectedStaticPage(null);
                      context.read<WebUiProvider>().setSelectedCategoryName(null);
                      _goToMainTab(0);
                    },
                    child: Row(
                      children: [
                        if (kIsWeb)
                          Image.asset(
                            'assets/Logo/logo-Photoroom.png',
                            height: 52,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.storefront,
                                size: 28,
                                color: AppColors.textPrimary,
                              );
                            },
                          )
                        else
                          const Icon(
                            Icons.storefront,
                            size: 28,
                            color: AppColors.textPrimary,
                          ),
                        // Only show text on mobile, hide on web
                        if (!kIsWeb) ...[
                          const SizedBox(width: 10),
                          Text(
                            AppLocalizations.of(context).appName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Navigation menu (expanded)
                  Expanded(child: _buildNavigationMenu()),
                  const SizedBox(width: 16),
                  // Actions with counts and navigation
                  Consumer4<
                    CartProvider,
                    AuthProvider,
                    NotificationProvider,
                    FavoritesProvider
                  >(
                    builder: (context, cart, auth, notif, favorites, _) {
                      // Load favorites when user is logged in (sau khi build xong)
                      if (auth.user != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          favorites.ensureLoaded(auth.user!.maNguoiDung);
                        });
                      }
                      final cartCount = cart.items.length;
                      final unreadCount = notif.unreadCount;
                      final favoriteCount = favorites.favoriteIds.length;
                      return Row(
                        children: [
                          _BadgeIconButton(
                            icon: Icons.shopping_cart_outlined,
                            count: cartCount,
                            tooltip: AppLocalizations.of(context).cart,
                            onPressed: () {
                              _popCollectionsScreenIfExists();
                              _goToMainTab(2);
                            },
                          ),
                          const SizedBox(width: 4),
                          // Favorite icon (only on web)
                          if (kIsWeb)
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.favorite_outline),
                                  color: AppColors.textPrimary,
                                  onPressed: () {
                                    if (auth.user == null) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                                  const AuthCombinedWebScreen(),
                                        ),
                                      );
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (_) => const FavoritesScreen(),
                                        ),
                                      );
                                    }
                                  },
                                  tooltip:
                                      AppLocalizations.of(context).favorites,
                                ),
                                if (favoriteCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.accentRed,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        favoriteCount > 99
                                            ? '99+'
                                            : favoriteCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          if (kIsWeb) const SizedBox(width: 6),
                          // Notification icon (only on web)
                          if (kIsWeb)
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                  ),
                                  color: AppColors.textPrimary,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                  tooltip: AppLocalizations.of(
                                    context,
                                  ).translate('notifications'),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.accentRed,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        unreadCount > 99
                                            ? '99+'
                                            : unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          if (kIsWeb) const SizedBox(width: 6),
                          // Language selector
                          const LanguageSelector(
                            showIcon: true,
                            showText: false,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.account_circle_outlined),
                            color: AppColors.textPrimary,
                            onPressed: () {
                              if (auth.user == null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AuthCombinedWebScreen(),
                                  ),
                                );
                              } else {
                                _popCollectionsScreenIfExists();
                                _goToMainTab(3);
                              }
                            },
                            tooltip: AppLocalizations.of(
                              context,
                            ).translate('account'),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _popCollectionsScreenIfExists() {
    // Use global navigator to pop CollectionsScreen if it exists
    final navigator = AppNavigator.navigator;
    if (navigator != null && navigator.canPop()) {
      // Pop until we're back to MainWebScreen (first route)
      navigator.popUntil((route) => route.isFirst);
    }
  }

  void _goToMainTab(int index) {
    context.read<WebUiProvider>().goToTab(index);
    if (kIsWeb) {
      // Ensure we are on the MainWebScreen so tab change takes effect
      AppNavigator.navigator?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainWebScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildNavigationMenu() {
    final webUi = context.watch<WebUiProvider>();
    final selectedCategory = webUi.selectedCategoryName;
    final selectedStatic = webUi.selectedStaticPage; // 'lookbook' | 'about'

    return Container(
      height: 40,
      decoration: BoxDecoration(
        // Removed background color
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:
            _navCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              final isLookbook = category == 'LOOKBOOK';
              final isAboutUs = category == 'VỀ CHÚNG TÔI';
              // Selected state for: product categories OR special static pages
              final isSelected = (!isLookbook && !isAboutUs && selectedCategory == category) ||
                  (isLookbook && selectedStatic == 'lookbook') ||
                  (isAboutUs && selectedStatic == 'about');
              final isLast = index == _navCategories.length - 1;

              return Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _hoveredIndex = index),
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      hoverColor: AppColors.accentRed.withOpacity(0.06),
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () {
                      if (isLookbook) {
                        context.read<WebUiProvider>().setSelectedStaticPage('lookbook');
                      // Navigate to Collections screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CollectionsScreen(),
                        ),
                      );
                    } else if (category == 'VỀ CHÚNG TÔI') {
                      context.read<WebUiProvider>().setSelectedStaticPage('about');
                      // Navigate to About Us screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutUsScreen(),
                        ),
                      );
                    } else {
                      _popCollectionsScreenIfExists();
                      context.read<WebUiProvider>().setSelectedCategoryName(category);
                      context.read<WebUiProvider>().setSearchQuery('');
                      _goToMainTab(1);
                    }
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                      border:
                          isLast
                              ? null
                              : Border(
                                right: BorderSide(
                                  color: AppColors.border.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                        ),
                        child: Text(
                      _localizedCategoryLabel(category),
                      style: TextStyle(
                        fontSize: 14,
                            fontWeight: isSelected || _hoveredIndex == index
                                ? FontWeight.w700
                                : FontWeight.w600,
                        color:
                                isSelected
                                    ? const Color(0xFF8B4513)
                                    : (_hoveredIndex == index
                                        ? AppColors.accentRed
                                        : const Color(0xFFA0522D)),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  String _localizedCategoryLabel(String category) {
    final l10n = AppLocalizations.of(context);
    switch (category) {
      case 'ĐẦM':
        return l10n.translate('nav_dress');
      case 'ÁO':
        return l10n.translate('nav_shirt');
      case 'QUẦN':
        return l10n.translate('nav_pants');
      case 'CHÂN VÁY':
        return l10n.translate('nav_skirt');
      case 'LOOKBOOK':
        return l10n.translate('nav_lookbook');
      case 'VỀ CHÚNG TÔI':
        return l10n.translate('nav_about_us');
      default:
        return category;
    }
  }
}

class _BadgeIconButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final String tooltip;
  final VoidCallback onPressed;

  const _BadgeIconButton({
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = count > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon),
          color: AppColors.textPrimary,
          onPressed: onPressed,
          tooltip: tooltip,
        ),
        if (showBadge)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
