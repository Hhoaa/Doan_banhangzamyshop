import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../web/auth_combined_web_screen.dart';
import '../order/order_screen.dart';
import '../favorites/favorites_screen.dart';
import '../notifications/notifications_screen.dart';
import '../chat/chat_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../store/free_store_info_screen.dart';
import '../news/news_screen.dart';
import '../policy/shipping_policy_screen.dart';
import '../policy/size_guide_screen.dart';
import '../address/address_management_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/phone_validator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          AppLocalizations.of(context).translate('account'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.user == null) {
            return _buildLoginPrompt();
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildMenuItems(),
                    const SizedBox(height: 24),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).translate('login_to_use_full_features'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).translate('manage_orders_and_more'),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AppButton(
            text: AppLocalizations.of(context).login,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            size: AppButtonSize.large,
          ),
          const SizedBox(height: 16),
          AppButton(
            text: AppLocalizations.of(context).register,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            width: double.infinity,
            backgroundColor: Colors.transparent,
            textColor: AppColors.accentRed,
            borderColor: AppColors.accentRed,
            size: AppButtonSize.large,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return SizedBox(
          width: double.infinity,
          child: AppCard(
            child: Column(
              children: [
              GestureDetector(
                onTap: () => _pickAndUploadAvatar(context),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.accentRed,
                      backgroundImage: user?.avatar != null && user!.avatar!.isNotEmpty
                          ? NetworkImage(user.avatar!)
                          : null,
                      child: user?.avatar == null || user!.avatar!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.camera_alt, size: 18, color: AppColors.accentRed),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.tenNguoiDung ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (user?.soDienThoai != null && user!.soDienThoai!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  user.soDienThoai!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: AppLocalizations.of(context).translate('edit_profile'),
                  type: AppButtonType.secondary,
                  onPressed: () => _showEditProfileDialog(),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildMenuItems() {
    return AppCard(
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.shopping_bag_outlined,
            title: AppLocalizations.of(context).translate('my_orders'),
            subtitle: AppLocalizations.of(context).translate('order_history'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrderScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.favorite_outline,
            title: AppLocalizations.of(context).favorites,
            subtitle: AppLocalizations.of(context).translate('favorites'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: AppLocalizations.of(context).translate('manage_addresses'),
            subtitle: AppLocalizations.of(context).translate('addresses'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddressManagementScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: AppLocalizations.of(context).translate('notifications'),
            subtitle: AppLocalizations.of(context).translate('notifications'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.smart_toy_outlined,
            title: AppLocalizations.of(context).translate('ai_chat_title'),
            subtitle: AppLocalizations.of(context).translate('ai_chat_title'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIChatScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.chat_outlined,
            title: AppLocalizations.of(context).translate('customer_service'),
            subtitle: AppLocalizations.of(context).translate('help_center'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen(adminUserId: 1)),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.store_outlined,
            title: AppLocalizations.of(context).translate('store'),
            subtitle: AppLocalizations.of(context).translate('store'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FreeStoreInfoScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.newspaper_outlined,
            title: AppLocalizations.of(context).translate('news'),
            subtitle: AppLocalizations.of(context).translate('news'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewsScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.local_shipping_outlined,
            title: AppLocalizations.of(context).translate('shipping_policy'),
            subtitle: AppLocalizations.of(context).translate('shipping_policy'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShippingPolicyScreen()),
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.straighten_outlined,
            title: AppLocalizations.of(context).translate('size_guide'),
            subtitle: AppLocalizations.of(context).translate('size_guide'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SizeGuideScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.accentRed,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return AppButton(
      text: AppLocalizations.of(context).logout,
      onPressed: _handleLogout,
      width: double.infinity,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      size: AppButtonSize.large,
    );
  }

  void _showEditProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) return;
    
    final nameController = TextEditingController(text: user.tenNguoiDung);
    final phoneController = TextEditingController(text: user.soDienThoai ?? '');
    final addressController = TextEditingController(text: user.diaChi ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('edit_profile')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('full_name'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).phone_number,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: buildPhoneInputFormatters(),
                maxLength: 10,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('address'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => _updateProfile(
              nameController.text,
              phoneController.text,
              addressController.text,
            ),
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(String name, String phone, String address) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) return;

      final trimmedName = name.trim();
      final trimmedPhone = phone.trim();
      final trimmedAddress = address.trim();

      if (trimmedPhone.isNotEmpty && !isValidVietnamPhone(trimmedPhone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('invalid_phone'))),
        );
        return;
      }

      // Update user profile in Supabase
      await SupabaseAuthService.updateUserProfile(
        authProvider.user!.maNguoiDung,
        name: trimmedName,
        phone: trimmedPhone,
        address: trimmedAddress,
      );

      // Refresh user data
      await authProvider.checkCurrentUser();

      Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('update_success'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).translate('update_failed')}: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      if (currentUser == null) return;

      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      // Upload to Supabase Storage
      final url = await SupabaseAuthService.uploadUserAvatar(
        userId: currentUser.maNguoiDung,
        data: bytes,
        contentType: picked.mimeType ?? 'image/jpeg',
      );

      // Update profile with avatar URL
      await SupabaseAuthService.updateUserProfile(
        currentUser.maNguoiDung,
        avatarUrl: url,
      );

      // Refresh user from backend
      await authProvider.checkCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('update_avatar_success'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('update_avatar_failed').replaceFirst('{error}', e.toString()))),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      setState(() => isLoading = true);
      
      await Provider.of<AuthProvider>(context, listen: false).logout();
      
      if (mounted) {
        if (kIsWeb) {
          // On web, navigate to AuthCombinedWebScreen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const AuthCombinedWebScreen(),
            ),
            (route) => false,
          );
        } else {
          // On mobile, navigate to home
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('logout_failed').replaceFirst('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}