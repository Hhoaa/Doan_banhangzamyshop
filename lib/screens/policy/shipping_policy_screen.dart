import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/web/web_page_wrapper.dart';

class ShippingPolicyScreen extends StatelessWidget {
  const ShippingPolicyScreen({super.key});

  Widget _wrapCard(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return WebPageWrapper(
      showTopBar: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar:
            kIsWeb
                ? null
                : AppBar(
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  title: Text(
                    AppLocalizations.of(context).translate('shipping_policy'),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 18 : 20,
                    ),
                  ),
                  centerTitle: true,
                ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main title
                  Center(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      ).translate('shipping_policy').toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Underline
                  Center(
                    child: Container(
                      width: isMobile ? 80 : 120,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentRed.withOpacity(0.3),
                            AppColors.accentRed,
                            AppColors.accentRed.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  SizedBox(height: isMobile ? 24 : 40),

                  // Delivery time section
                  _buildSectionTitle(
                    context,
                    AppLocalizations.of(context).translate('delivery'),
                    Icons.local_shipping_outlined,
                    isMobile,
                  ),

                  SizedBox(height: isMobile ? 12 : 16),

                  // Delivery time table
                  _wrapCard(
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child:
                          isMobile
                              ? _buildMobileDeliveryCards(context)
                              : _buildDesktopDeliveryTable(context),
                    ),
                  ),

                  SizedBox(height: isMobile ? 24 : 40),

                  // Shipping fees section
                  _buildSectionTitle(
                    context,
                    AppLocalizations.of(context).translate('shipping_fee'),
                    Icons.payment_outlined,
                    isMobile,
                  ),

                  SizedBox(height: isMobile ? 12 : 16),

                  _wrapCard(
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeeItem(
                            '🎉 ' +
                                AppLocalizations.of(context).translate('free'),
                            'Đơn hàng từ 500.000 VND',
                            true,
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          _buildFeeItem(
                            '📦 Nội thành',
                            '30.000 VND',
                            false,
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          _buildFeeItem(
                            '🚚 Ngoại thành & xa',
                            '50.000 VND',
                            false,
                            isMobile,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isMobile ? 24 : 40),

                  // Delivery process section
                  _buildSectionTitle(
                    context,
                    'Quy trình giao hàng',
                    Icons.timeline_outlined,
                    isMobile,
                  ),

                  SizedBox(height: isMobile ? 12 : 16),

                  _wrapCard(
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProcessStep(
                            context,
                            '1',
                            AppLocalizations.of(
                              context,
                            ).translate('order_details'),
                            AppLocalizations.of(
                              context,
                            ).translate('processing_payment'),
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 16 : 20),
                          _buildProcessStep(
                            context,
                            '2',
                            AppLocalizations.of(
                              context,
                            ).translate('order_summary'),
                            AppLocalizations.of(
                              context,
                            ).translate('place_order'),
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 16 : 20),
                          _buildProcessStep(
                            context,
                            '3',
                            AppLocalizations.of(context).translate('shipping'),
                            AppLocalizations.of(
                              context,
                            ).translate('shipping_policy'),
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 16 : 20),
                          _buildProcessStep(
                            context,
                            '4',
                            AppLocalizations.of(context).translate('confirm'),
                            'Giao hàng thành công',
                            isMobile,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isMobile ? 24 : 40),

                  // Contact section
                  _buildSectionTitle(
                    context,
                    AppLocalizations.of(context).translate('customer_service'),
                    Icons.support_agent_outlined,
                    isMobile,
                  ),

                  SizedBox(height: isMobile ? 12 : 16),

                  _wrapCard(
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accentRed.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentRed.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).translate('contact') +
                                ':',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: isMobile ? 16 : 20),
                          _buildContactItem(
                            '📞',
                            'Hotline',
                            '1900 1234',
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          _buildContactItem(
                            '📧',
                            'Email',
                            'support@zamy.com',
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          _buildContactItem(
                            '💬',
                            'Chat',
                            'Hỗ trợ 24/7',
                            isMobile,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isMobile ? 24 : 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    IconData icon,
    bool isMobile,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.accentRed,
            size: isMobile ? 20 : 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopDeliveryTable(BuildContext context) {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE8B4B8), Color(0xFFF0C5C9)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'STT',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Khu vực',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Thời gian giao hàng',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Table rows
        _buildTableRow(
          '1',
          'Nội thành Hà Nội',
          'Từ 01 – 03 ngày làm việc',
          true,
        ),
        _buildTableRow(
          '2',
          'Ngoại thành & các thành phố lớn',
          'Từ 03 – 05 ngày làm việc',
          false,
        ),
        _buildTableRow(
          '3',
          'Các khu vực khác',
          'Từ 04 – 07 ngày làm việc',
          true,
        ),
      ],
    );
  }

  Widget _buildMobileDeliveryCards(BuildContext context) {
    return Column(
      children: [
        _buildMobileDeliveryCard(
          '1',
          'Nội thành Hà Nội',
          'Từ 01 – 03 ngày làm việc',
          true,
        ),
        const Divider(height: 1, thickness: 1),
        _buildMobileDeliveryCard(
          '2',
          'Ngoại thành & các thành phố lớn',
          'Từ 03 – 05 ngày làm việc',
          false,
        ),
        const Divider(height: 1, thickness: 1),
        _buildMobileDeliveryCard(
          '3',
          'Các khu vực khác',
          'Từ 04 – 07 ngày làm việc',
          false,
        ),
      ],
    );
  }

  Widget _buildMobileDeliveryCard(
    String number,
    String area,
    String time,
    bool isFirst,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: number == '3' ? const Radius.circular(16) : Radius.zero,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentRed,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        time,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String stt, String area, String time, bool isEven) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFFAFAFA),
        borderRadius:
            stt == '3'
                ? const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                )
                : BorderRadius.zero,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              stt,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              area,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              time,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeItem(
    String title,
    String amount,
    bool isFree,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color:
            isFree
                ? AppColors.accentRed.withOpacity(0.05)
                : Colors.grey.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isFree
                  ? AppColors.accentRed.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 15 : 16,
                fontWeight: isFree ? FontWeight.bold : FontWeight.w500,
                color: isFree ? AppColors.accentRed : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: isFree ? AppColors.accentRed : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(
    BuildContext context,
    String step,
    String title,
    String description,
    bool isMobile,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isMobile ? 36 : 40,
          height: isMobile ? 36 : 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentRed, Color(0xFFFF6B7A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentRed.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 16 : 18,
              ),
            ),
          ),
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 15 : 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(
    String emoji,
    String label,
    String value,
    bool isMobile,
  ) {
    return Row(
      children: [
        Text(emoji, style: TextStyle(fontSize: isMobile ? 20 : 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
