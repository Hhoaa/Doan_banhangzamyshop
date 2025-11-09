import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../utils/phone_validator.dart';
import '../../services/supabase_auth_service.dart';
import '../../providers/web_ui_provider.dart';
import 'package:provider/provider.dart';
import '../../screens/auth/forgot_password_screen.dart';
import 'web_shell.dart';
import 'auth_web_page.dart';
import '../../navigation/navigator_key.dart';
import '../main/main_web_screen.dart';

class AuthCombinedWebScreen extends StatefulWidget {
  const AuthCombinedWebScreen({super.key});

  @override
  State<AuthCombinedWebScreen> createState() => _AuthCombinedWebScreenState();
}

class _AuthCombinedWebScreenState extends State<AuthCombinedWebScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Login controllers
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscurePassword = true;
  bool _loginIsLoading = false;

  // Register controllers
  final _registerFullNameController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  bool _registerObscurePassword = true;
  bool _registerObscureConfirmPassword = true;
  bool _registerIsLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _registerFullNameController.dispose();
    _registerPhoneController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // Fallback cho mobile
      return const Scaffold(
        body: Center(child: Text('Auth screen for mobile')),
      );
    }

    return WebShell(
      showWebHeader: true,
      showTopBar: false,
      showFooter: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.accentRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        'assets/Logo/logo-Photoroom.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.shopping_bag_outlined,
                            size: 50,
                            color: AppColors.accentRed,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ZAMY SHOP',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).translate('tagline').isEmpty
                        ? ' '
                        : AppLocalizations.of(context).translate('tagline'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.accentRed,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.accentRed,
                    tabs: [
                      Tab(text: AppLocalizations.of(context).login),
                      Tab(text: AppLocalizations.of(context).register),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Tab Content
                  SizedBox(
                    height: 500, // Fixed height for TabBarView
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildLoginTab(), _buildRegisterTab()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: AppLocalizations.of(context).translate('email'),
              controller: _loginUsernameController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(
                    context,
                  ).translate('invalid_email');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: AppLocalizations.of(context).password,
              controller: _loginPasswordController,
              obscureText: _loginObscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(
                    context,
                  ).translate('invalid_password');
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _loginObscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _loginObscurePassword = !_loginObscurePassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              const AuthWebPage(child: ForgotPasswordScreen()),
                    ),
                  );
                },
                child: Text(
                  AppLocalizations.of(context).translate('forgot_password'),
                  style: const TextStyle(color: AppColors.accentRed),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text:
                  _loginIsLoading
                      ? AppLocalizations.of(context).loading
                      : AppLocalizations.of(context).login,
              type: AppButtonType.accent,
              size: AppButtonSize.large,
              onPressed: _loginIsLoading ? null : _handleLogin,
            ),
            const SizedBox(height: 24),
            _buildSocialLogin(),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: AppLocalizations.of(context).translate('full_name'),
              controller: _registerFullNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(
                    context,
                  ).translate('enter_full_name');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: AppLocalizations.of(context).phone_number,
              controller: _registerPhoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: buildPhoneInputFormatters(),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return AppLocalizations.of(context).translate('enter_phone');
                }
                if (!isValidVietnamPhone(trimmed)) {
                  return AppLocalizations.of(
                    context,
                  ).translate('invalid_phone');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: AppLocalizations.of(context).email,
              controller: _registerEmailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(
                    context,
                  ).translate('invalid_email');
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return AppLocalizations.of(
                    context,
                  ).translate('invalid_email');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: AppLocalizations.of(context).password,
              controller: _registerPasswordController,
              obscureText: _registerObscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(
                    context,
                  ).translate('invalid_password');
                }
                if (value.length < 6) {
                  return AppLocalizations.of(
                    context,
                  ).translate('password_too_short');
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _registerObscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _registerObscurePassword = !_registerObscurePassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: AppLocalizations.of(context).translate('confirm_password'),
              controller: _registerConfirmPasswordController,
              obscureText: _registerObscureConfirmPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(
                    context,
                  ).translate('confirm_password');
                }
                if (value != _registerPasswordController.text) {
                  return AppLocalizations.of(
                    context,
                  ).translate('passwords_not_match');
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _registerObscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _registerObscureConfirmPassword =
                        !_registerObscureConfirmPassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text:
                  _registerIsLoading
                      ? AppLocalizations.of(context).loading
                      : AppLocalizations.of(context).register,
              type: AppButtonType.accent,
              size: AppButtonSize.large,
              onPressed: _registerIsLoading ? null : _handleRegister,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '—',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loginIsLoading ? null : _handleGoogleLogin,
                icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                label: const Text('Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loginIsLoading ? null : _handleFacebookLogin,
                icon: const Icon(Icons.facebook, color: Colors.blue),
                label: const Text('Facebook'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      setState(() {
        _loginIsLoading = true;
      });

      try {
        final user = await SupabaseAuthService.loginWithEmail(
          _loginUsernameController.text,
          _loginPasswordController.text,
        );

        if (user != null && mounted) {
          context.read<WebUiProvider>().goToTab(3); // Go to Profile tab
          if (kIsWeb) {
            // On web, replace stack with MainWebScreen to avoid stale routes
            AppNavigator.navigator?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainWebScreen()),
              (route) => false,
            );
          } else {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else {
          _showErrorDialog(AppLocalizations.of(context).loginFailed);
        }
      } catch (e) {
        _showErrorDialog('${AppLocalizations.of(context).error}: $e');
      } finally {
        if (mounted) {
          setState(() {
            _loginIsLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_registerFormKey.currentState!.validate()) {
      setState(() {
        _registerIsLoading = true;
      });

      try {
        final user = await SupabaseAuthService.register(
          _registerEmailController.text.trim(),
          _registerPasswordController.text,
          _registerFullNameController.text.trim(),
          _registerPhoneController.text.trim(),
        );

        if (user != null && mounted) {
          context.read<WebUiProvider>().goToTab(3); // Go to Profile tab
          if (kIsWeb) {
            AppNavigator.navigator?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainWebScreen()),
              (route) => false,
            );
          } else {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else {
          _showErrorDialog(
            AppLocalizations.of(context).translate('register_failed'),
          );
        }
      } catch (e) {
        _showErrorDialog('${AppLocalizations.of(context).error}: $e');
      } finally {
        if (mounted) {
          setState(() {
            _registerIsLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      setState(() {
        _loginIsLoading = true;
      });
      await SupabaseAuthService.loginWithGoogle();
      if (mounted) {
        context.read<WebUiProvider>().goToTab(3);
        if (kIsWeb) {
          AppNavigator.navigator?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainWebScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      _showErrorDialog(
        '${AppLocalizations.of(context).translate('login_with_google')} ${AppLocalizations.of(context).translate('login_failed')}: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loginIsLoading = false;
        });
      }
    }
  }

  Future<void> _handleFacebookLogin() async {
    try {
      setState(() {
        _loginIsLoading = true;
      });
      await SupabaseAuthService.loginWithFacebook();
      if (mounted) {
        context.read<WebUiProvider>().goToTab(3);
        if (kIsWeb) {
          AppNavigator.navigator?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainWebScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      _showErrorDialog(
        'Facebook ${AppLocalizations.of(context).translate('login_failed')}: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loginIsLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).error),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).close),
              ),
            ],
          ),
    );
  }
}
