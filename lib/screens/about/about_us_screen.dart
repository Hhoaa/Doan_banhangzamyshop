import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../widgets/web/web_page_wrapper.dart';
import '../../l10n/app_localizations.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Beige background
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: EdgeInsets.only(
                left: 40,
                right: 40,
                top: kIsWeb ? 0 : 60,
                bottom: 60,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Main title
                  _buildMainTitle(context),
                  const SizedBox(height: 40),
                  
                  // Two column introduction text
                  _buildTwoColumnIntro(context),
                  const SizedBox(height: 60),
                  
                  // Two large images with overlay
                  _buildImageGallery(context),
                  const SizedBox(height: 60),
                  
                  // Brand story section
                  _buildBrandStory(context),
                  const SizedBox(height: 60),
                  
                  // Core values section
                  _buildCoreValues(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (kIsWeb) {
      return WebPageWrapper(
        showWebHeader: true,
        showTopBar: false,
        showFooter: true,
        child: content,
      );
    }
    return content;
  }

  Widget _buildMainTitle(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context).translate('about_us_title'),
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513), // Dark brown
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 200,
          height: 2,
          color: const Color(0xFF8B4513),
        ),
      ],
    );
  }

  Widget _buildTwoColumnIntro(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildIntroText(
                      AppLocalizations.of(context).translate('about_intro_1'),
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: _buildIntroText(
                      AppLocalizations.of(context).translate('about_intro_2'),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildIntroText(
                    AppLocalizations.of(context).translate('about_intro_1'),
                  ),
                  const SizedBox(height: 20),
                  _buildIntroText(
                    AppLocalizations.of(context).translate('about_intro_2'),
                  ),
                ],
              );
      },
    );
  }

  Widget _buildIntroText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF333333),
        height: 1.8,
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return isWide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildImageWithOverlay(
                    'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=400',
                    AppLocalizations.of(context).translate('about_overlay_chamo'),
                  ),
                  const SizedBox(width: 20),
                  _buildImageWithOverlay(
                    'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
                    AppLocalizations.of(context).translate('about_overlay_chamo'),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildImageWithOverlay(
                    'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=400',
                    AppLocalizations.of(context).translate('about_overlay_chamo'),
                  ),
                  const SizedBox(height: 20),
                  _buildImageWithOverlay(
                    'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
                    AppLocalizations.of(context).translate('about_overlay_chamo'),
                  ),
                ],
              );
      },
    );
  }

  Widget _buildImageWithOverlay(String imageUrl, String overlayText) {
    return Container(
      width: 400,
      height: 600,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.border,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.border,
                child: const Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                overlayText,
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.9),
                  fontStyle: FontStyle.italic,
                  letterSpacing: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandStory(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context).translate('brand_story'),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            AppLocalizations.of(context).translate('brand_story_paragraph'),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF333333),
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildCoreValues(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context).translate('core_values'),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCoreValuesText(context),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: _buildCoreValuesImages(context),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildCoreValuesText(context),
                      const SizedBox(height: 30),
                      _buildCoreValuesImages(context),
                    ],
                  );
          },
        ),
      ],
    );
  }

  Widget _buildCoreValuesText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('core_values_intro'),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF333333),
            height: 1.8,
          ),
        ),
        const SizedBox(height: 30),
        _buildValueItem(
          1,
          AppLocalizations.of(context).translate('core_value_1_vi'),
          AppLocalizations.of(context).translate('core_value_1_en'),
        ),
        const SizedBox(height: 16),
        _buildValueItem(
          2,
          AppLocalizations.of(context).translate('core_value_2_vi'),
          AppLocalizations.of(context).translate('core_value_2_en'),
        ),
        const SizedBox(height: 16),
        _buildValueItem(
          3,
          AppLocalizations.of(context).translate('core_value_3_vi'),
          AppLocalizations.of(context).translate('core_value_3_en'),
        ),
        const SizedBox(height: 16),
        _buildValueItem(
          4,
          AppLocalizations.of(context).translate('core_value_4_vi'),
          AppLocalizations.of(context).translate('core_value_4_en'),
        ),
        const SizedBox(height: 16),
        _buildValueItem(
          5,
          AppLocalizations.of(context).translate('core_value_5_vi'),
          AppLocalizations.of(context).translate('core_value_5_en'),
        ),
      ],
    );
  }

  Widget _buildValueItem(int number, String vietnamese, String english) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF8B4513),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vietnamese,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                english,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoreValuesImages(BuildContext context) {
    return Column(
      children: [
        _buildSmallImage(
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=600',
          AppLocalizations.of(context).translate('about_overlay_just_date'),
        ),
        const SizedBox(height: 20),
        _buildSmallImage(
          'https://images.unsplash.com/photo-1445205170230-053b83016050?w=600',
          AppLocalizations.of(context).translate('about_overlay_just_date'),
        ),
      ],
    );
  }

  Widget _buildSmallImage(String imageUrl, String overlayText) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.border,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.border,
                child: const Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              overlayText,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w300,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

