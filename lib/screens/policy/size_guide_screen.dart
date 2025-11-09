import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/web/web_page_wrapper.dart';

class SizeGuideScreen extends StatelessWidget {
  const SizeGuideScreen({super.key});

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
                    AppLocalizations.of(context).translate('size_guide'),
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
                      ).translate('size_guide').toUpperCase(),
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

                  // Size chart section
                  _buildSectionTitle(
                    context,
                    'Bảng kích thước',
                    Icons.straighten_outlined,
                    isMobile,
                  ),

                  SizedBox(height: isMobile ? 12 : 16),

                  // Size chart table
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
                              ? _buildMobileSizeCards(context)
                              : _buildDesktopSizeTable(context),
                    ),
                  ),

                  SizedBox(height: isMobile ? 24 : 40),

                  // Measurement guide section
                  _buildSectionTitle(
                    context,
                    'Hướng dẫn đo',
                    Icons.info_outline,
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
                          _buildMeasurementStep(
                            context,
                            '1',
                            'Vòng ngực',
                            'Đo vòng ngực tại vị trí rộng nhất',
                            Icons.accessibility_new,
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 16 : 20),
                          _buildMeasurementStep(
                            context,
                            '2',
                            'Vòng eo',
                            'Đo vòng eo tại vị trí nhỏ nhất',
                            Icons.radio_button_unchecked,
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 16 : 20),
                          _buildMeasurementStep(
                            context,
                            '3',
                            'Vòng mông',
                            'Đo vòng mông tại vị trí rộng nhất',
                            Icons.lens_outlined,
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 16 : 20),
                          _buildMeasurementStep(
                            context,
                            '4',
                            'Cân nặng',
                            'Cân trọng lượng cơ thể (kg)',
                            Icons.monitor_weight_outlined,
                            isMobile,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isMobile ? 24 : 40),

                  // Tips section
                  _buildSectionTitle(
                    context,
                    'Lưu ý khi chọn size',
                    Icons.lightbulb_outline,
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
                          _buildTipItem(
                            'Nếu số đo của bạn nằm giữa 2 size, hãy chọn size lớn hơn để thoải mái',
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          _buildTipItem(
                            'Đo sát cơ thể nhưng không quá chặt để có kết quả chính xác nhất',
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          _buildTipItem(
                            'Tham khảo phần mô tả sản phẩm để biết độ co giãn của chất liệu',
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          _buildTipItem(
                            'Mỗi dáng người có đặc điểm riêng, hãy liên hệ để được tư vấn chi tiết',
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          _buildTipItem(
                            'Kiểm tra chính sách đổi trả trong vòng 7 ngày nếu size không phù hợp',
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
                    AppLocalizations.of(context).translate('help_center'),
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

  Widget _buildDesktopSizeTable(BuildContext context) {
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
                  'SIZE',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'NGỰC (cm)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'EO (cm)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'MÔNG (cm)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'CÂN NẶNG (kg)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Table rows
        _buildSizeRow('S', '82-85', '64-66', '90-92', '42-47', true),
        _buildSizeRow('M', '86-89', '67-70', '93-96', '48-53', false),
        _buildSizeRow('L', '90-93', '71-74', '97-100', '54-59', true),
        _buildSizeRow('XL', '94-97', '75-78', '101-104', '60-65', false),
      ],
    );
  }

  Widget _buildMobileSizeCards(BuildContext context) {
    return Column(
      children: [
        _buildMobileSizeCard('S', '82-85', '64-66', '90-92', '42-47', true),
        const Divider(height: 1, thickness: 1),
        _buildMobileSizeCard('M', '86-89', '67-70', '93-96', '48-53', false),
        const Divider(height: 1, thickness: 1),
        _buildMobileSizeCard('L', '90-93', '71-74', '97-100', '54-59', false),
        const Divider(height: 1, thickness: 1),
        _buildMobileSizeCard('XL', '94-97', '75-78', '101-104', '60-65', false),
      ],
    );
  }

  Widget _buildMobileSizeCard(
    String size,
    String chest,
    String waist,
    String hip,
    String weight,
    bool isFirst,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: size == 'XL' ? const Radius.circular(16) : Radius.zero,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Size label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'SIZE $size',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Measurements
          _buildMeasurementRow('Ngực', chest, Icons.accessibility_new),
          const SizedBox(height: 8),
          _buildMeasurementRow('Eo', waist, Icons.radio_button_unchecked),
          const SizedBox(height: 8),
          _buildMeasurementRow('Mông', hip, Icons.lens_outlined),
          const SizedBox(height: 8),
          _buildMeasurementRow(
            'Cân nặng',
            weight,
            Icons.monitor_weight_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSizeRow(
    String size,
    String chest,
    String waist,
    String hip,
    String weight,
    bool isEven,
  ) {
    final bool isLast = size == 'XL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFFAFAFA),
        borderRadius:
            isLast
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                size,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentRed,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              chest,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              waist,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              hip,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              weight,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementStep(
    BuildContext context,
    String step,
    String title,
    String description,
    IconData icon,
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
              Row(
                children: [
                  Icon(
                    icon,
                    size: isMobile ? 18 : 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
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

  Widget _buildTipItem(String text, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.accentRed,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
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
