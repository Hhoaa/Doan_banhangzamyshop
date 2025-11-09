import 'package:flutter/foundation.dart';
import '../web/auth_web_page.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../utils/phone_validator.dart';
import '../../services/supabase_auth_service.dart';
import 'login_screen.dart';
import '../../l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    AppLocalizations.of(context).appName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _buildRegisterForm(),
                const SizedBox(height: 24),
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(
            context,
          ).translate('register_title').toUpperCase(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        AppTextField(
          label: AppLocalizations.of(context).translate('full_name'),
          controller: _fullNameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context).translate('full_name');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: AppLocalizations.of(context).phone_number,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: buildPhoneInputFormatters(),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return AppLocalizations.of(context).translate('invalid_phone');
            }
            if (!isValidVietnamPhone(trimmed)) {
              return AppLocalizations.of(context).translate('invalid_phone');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: AppLocalizations.of(context).translate('email_or_username'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context).translate('invalid_email');
            }
            final emailRegex = RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            );
            if (!emailRegex.hasMatch(value)) {
              return AppLocalizations.of(context).translate('invalid_email');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: AppLocalizations.of(context).password,
          controller: _passwordController,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context).translate('invalid_password');
            }
            if (value.length < 6) {
              return AppLocalizations.of(
                context,
              ).translate('password_too_short');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: AppLocalizations.of(context).translate('confirm_password'),
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context).translate('confirm_password');
            }
            if (value != _passwordController.text) {
              return AppLocalizations.of(
                context,
              ).translate('passwords_not_match');
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        AppButton(
          text: AppLocalizations.of(context).translate('create_account'),
          type: AppButtonType.primary,
          size: AppButtonSize.large,
          isLoading: _isLoading,
          onPressed: _handleRegister,
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context).translate('have_account_q'),
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () {
            if (kIsWeb) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthWebPage(child: LoginScreen()),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          },
          child: Text(
            AppLocalizations.of(context).login,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.accentRed,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = await SupabaseAuthService.register(
          _emailController.text.trim(),
          _passwordController.text,
          _fullNameController.text.trim(),
          _phoneController.text.trim(),
        );

        if (user != null) {
          _showSuccessDialog();
        } else {
          _showErrorDialog(
            AppLocalizations.of(context).translate('register_failed'),
          );
        }
      } catch (e) {
        print(' Lỗi đăng ký: $e');

        // Làm sạch chuỗi lỗi (bỏ "Exception: ")
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }

        // Hiển thị dialog lỗi thân thiện
        _showErrorDialog(errorMessage);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              AppLocalizations.of(context).translate('register_title') +
                  ' ' +
                  AppLocalizations.of(context).translate('success'),
            ),
            content: Text(
              AppLocalizations.of(
                context,
              ).translate('account_created_check_email'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (kIsWeb) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const AuthWebPage(child: LoginScreen()),
                      ),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                },
                child: Text(AppLocalizations.of(context).ok),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.accentRed,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).translate('notification'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).ok,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }
}
