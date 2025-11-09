import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../providers/auth_provider.dart';
import '../../config/supabase_config.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/phone_validator.dart';

class UpdatePhoneScreen extends StatefulWidget {
  const UpdatePhoneScreen({super.key});

  @override
  State<UpdatePhoneScreen> createState() => _UpdatePhoneScreenState();
}

class _UpdatePhoneScreenState extends State<UpdatePhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.soDienThoai != null) {
      _phoneController.text = authProvider.user!.soDienThoai!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final l10n = AppLocalizations.of(context);
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.translate('phone_required');
    }
    if (!isValidVietnamPhone(trimmed)) {
      return l10n.translate('invalid_phone');
    }

    return null;
  }

  Future<void> _updatePhone() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Người dùng chưa đăng nhập';
        });
        return;
      }

      final phoneNumber = _phoneController.text.trim();

      // Cập nhật số điện thoại trực tiếp
      final client = SupabaseConfig.client;
      await client
          .from('users')
          .update({'so_dien_thoai': phoneNumber})
          .eq('id', authProvider.user!.maNguoiDung);

      setState(() {
        _isLoading = false;
      });

      // Reload user
      await authProvider.refreshUser();

      if (mounted) {
        final successMessage = AppLocalizations.of(
          context,
        ).translate('update_success');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).translate('update_phone'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context).translate('enter_new_phone'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).translate('phone_digits_rule'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).translate('phone_number'),
                    hintText: '0123456789',
                    prefixIcon: const Icon(Icons.phone),
                    border: const OutlineInputBorder(),
                    errorText: _errorMessage,
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: buildPhoneInputFormatters(),
                  validator: _validatePhone,
                  autofocus: true,
                ),
                const SizedBox(height: 32),
                AppButton(
                  onPressed: _isLoading ? null : _updatePhone,
                  text: AppLocalizations.of(context).translate('update'),
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context).translate('cancel')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
