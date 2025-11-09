import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../providers/web_ui_provider.dart';
import '../../screens/news/news_screen.dart';
import '../../screens/store/free_store_info_screen.dart';
import '../../screens/policy/shipping_policy_screen.dart';
import '../../screens/policy/size_guide_screen.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  // Gradient TỪ TRÁI SANG PHẢI (Horizontal)
  static const LinearGradient _footerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFDF6F3), // Trái: trắng hồng nhạt
      Color(0xFFF4D0C2), // Giữa: #f4d0c2
      Color(0xFFEDB8A3), // Phải: hồng cam nhạt
    ],
    stops: [0.0, 0.5, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _footerGradient),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  return isWide
                      ? _buildWideLayout(context)
                      : _buildMobileLayout(context);
                },
              ),

              const SizedBox(height: 48),

              Divider(
                color: const Color(0xFFEDB8A3).withOpacity(0.4),
                height: 1,
                thickness: 1,
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  '© ${DateTime.now().year} ${AppLocalizations.of(context).appName}. ${AppLocalizations.of(context).translate('all_rights_reserved')}',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF8B5A4A).withOpacity(0.85),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 30, child: _buildZamyColumn(context)),
        const SizedBox(width: 24),
        Expanded(flex: 20, child: _buildLinksColumn(context)),
        const SizedBox(width: 24),
        Expanded(flex: 25, child: _buildPolicyColumn(context)),
        const SizedBox(width: 24),
        Expanded(flex: 30, child: _buildNewsletterColumn(context)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildZamyColumn(context),
        const SizedBox(height: 32),
        _buildLinksColumn(context),
        const SizedBox(height: 32),
        _buildPolicyColumn(context),
        const SizedBox(height: 32),
        _buildNewsletterColumn(context),
      ],
    );
  }

  Widget _buildZamyColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/Logo/logo-Photoroom.png',
            height: 65,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Text(
                AppLocalizations.of(context).appName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B3A2D),
                  letterSpacing: 3,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        _buildFooterLink(context, AppLocalizations.of(context).translate('about_us'), () => context.read<WebUiProvider>().goToTab(0)),
        const SizedBox(height: 11),
        _buildFooterLink(context, AppLocalizations.of(context).translate('news'), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewsScreen()))),
        const SizedBox(height: 11),
        _buildFooterLink(context, AppLocalizations.of(context).translate('store'), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FreeStoreInfoScreen()))),
      ],
    );
  }

  Widget _buildLinksColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'follow_us'),
        const SizedBox(height: 16),
        _buildSocialLink(context, 'Facebook', Icons.facebook, const Color(0xFF1877F2), () => _launchURL('https://www.facebook.com')),
        const SizedBox(height: 13),
        _buildSocialLink(context, 'Instagram', Icons.camera_alt, const Color(0xFFE4405F), () => _launchURL('https://www.instagram.com')),
      ],
    );
  }

  Widget _buildPolicyColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'customer_service'),
        const SizedBox(height: 16),
        _buildFooterLink(context, AppLocalizations.of(context).translate('shipping_policy'), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShippingPolicyScreen()))),
        const SizedBox(height: 11),
        _buildFooterLink(context, AppLocalizations.of(context).translate('return_policy'), () => _showComingSoon(context)),
        const SizedBox(height: 11),
        _buildFooterLink(context, AppLocalizations.of(context).translate('size_guide'), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SizeGuideScreen()))),
      ],
    );
  }

  Widget _buildNewsletterColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'newsletter_title'),
        const SizedBox(height: 16),
        _buildNewsletterForm(context),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context).translate('collections_coming_soon'),
          style: TextStyle(
            fontSize: 12.5,
            color: const Color(0xFF8B5A4A).withOpacity(0.8),
            fontStyle: FontStyle.italic,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String key) {
    return Text(
      AppLocalizations.of(context).translate(key).toUpperCase(),
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFF6B3A2D),
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildFooterLink(BuildContext context, String text, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF5D2F20),
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLink(BuildContext context, String text, IconData icon, Color iconColor, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(icon, size: 23, color: iconColor),
              const SizedBox(width: 13),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF5D2F20),
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsletterForm(BuildContext context) {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).translate('newsletter_hint_email'),
              hintStyle: TextStyle(color: const Color(0xFF8B5A4A).withOpacity(0.7), fontSize: 14),
              prefixIcon: Icon(Icons.email_outlined, size: 20, color: const Color(0xFF8B5A4A).withOpacity(0.8)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.95),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEDB8A3), width: 1.3)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEDB8A3), width: 1.3)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2.2)),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF5D2F20)),
            onFieldSubmitted: (_) => _subscribe(context, controller),
          ),
        ),
        const SizedBox(width: 14),
        ElevatedButton(
          onPressed: () => _subscribe(context, controller),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 17),
            elevation: 5,
            shadowColor: const Color(0xFFE91E63).withOpacity(0.35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            AppLocalizations.of(context).translate('newsletter_subscribe'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.6),
          ),
        ),
      ],
    );
  }

  void _subscribe(BuildContext context, TextEditingController controller) {
    final email = controller.text.trim();
    if (email.isEmpty) {
      _showSnackBar(context, 'newsletter_input_email_required');
      return;
    }
    _showSnackBar(context, 'newsletter_subscribe_success', email: email);
    controller.clear();
  }

  void _showSnackBar(BuildContext context, String key, {String? email}) {
    final text = email != null
        ? AppLocalizations.of(context).translate(key).replaceFirst('{email}', email)
        : AppLocalizations.of(context).translate(key);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontSize: 14, color: Colors.white)),
        backgroundColor: const Color(0xFFE91E63),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }

  void _showComingSoon(BuildContext context) => _showSnackBar(context, 'coming_soon');

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}