import 'package:flutter/material.dart';
import '../../screens/profile/update_phone_screen.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/phone_validator.dart';

class PhoneCheckDialog extends StatelessWidget {
  final int userId;
  final VoidCallback? onPhoneUpdated;
  
  const PhoneCheckDialog({
    super.key,
    required this.userId,
    this.onPhoneUpdated,
  });

  static Future<bool> show(
    BuildContext context,
    int userId, {
    VoidCallback? onPhoneUpdated,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PhoneCheckDialog(
        userId: userId,
        onPhoneUpdated: onPhoneUpdated,
      ),
    ) ?? false;
  }

  Future<void> _navigateToUpdatePhone(BuildContext context) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UpdatePhoneScreen(),
      ),
    );

    if (updated == true) {
      if (onPhoneUpdated != null) {
        onPhoneUpdated!();
      }
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.phone, color: AppColors.accentRed),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context).translate('update_phone')),
        ],
      ),
      content: Text(
        AppLocalizations.of(context).translate('phone_required_for_order'),
        style: const TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppLocalizations.of(context).translate('cancel')),
        ),
        ElevatedButton(
          onPressed: () => _navigateToUpdatePhone(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentRed,
          ),
          child: Text(AppLocalizations.of(context).translate('update')),
        ),
      ],
    );
  }
}

/// Utility class để kiểm tra số điện thoại
class PhoneChecker {
  /// Kiểm tra số điện thoại có hợp lệ không
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return false;
    }
    return isValidVietnamPhone(phone);
  }

  /// Validate số điện thoại và trả về error message
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    
    if (!isValidVietnamPhone(value)) {
      return 'Số điện thoại phải có đúng 10 số và bắt đầu bằng 0';
    }
    
    return null;
  }
}

