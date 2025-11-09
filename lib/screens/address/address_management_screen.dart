import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/user_address.dart';
import '../../services/supabase_address_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../widgets/common/app_header.dart';
import 'add_edit_address_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/web/web_page_wrapper.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() =>
      _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  List<UserAddress> _addresses = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = await SupabaseAuthService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('login_to_manage_addresses')),
            ),
          );
        }
        return;
      }

      _currentUserId = user.maNguoiDung;
      final addresses = await SupabaseAddressService.getUserAddresses(
        user.maNguoiDung,
      );

      setState(() {
        _addresses = addresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')));
      }
    }
  }

  Future<void> _deleteAddress(UserAddress address) async {
    try {
      await SupabaseAddressService.deleteAddress(address.id);
      await _loadAddresses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('address_deleted_success')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')));
      }
    }
  }

  Future<void> _setDefaultAddress(UserAddress address) async {
    if (address.isDefault) return;

    try {
      await SupabaseAddressService.setDefaultAddress(
        _currentUserId!,
        address.id,
      );
      await _loadAddresses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('set_default_success')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')));
      }
    }
  }

  void _showDeleteDialog(UserAddress address) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).translate('delete_address')),
            content: Text(
              '${AppLocalizations.of(context).translate('confirm_delete_address')}\n\n${address.fullAddress}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteAddress(address);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(AppLocalizations.of(context).delete),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebPageWrapper(
      showTopBar: false,
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: AppLocalizations.of(context).translate('manage_addresses'),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditAddressScreen(),
                ),
              );
              if (result == true) {
                _loadAddresses();
              }
            },
            icon: const Icon(Icons.add),
            tooltip: AppLocalizations.of(context).translate('add_new_address'),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: _addresses.isEmpty
                        ? _buildEmptyState()
                        : _buildAddressList(),
                  ),
                ),
    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.location_off,
                size: 40,
                color: AppColors.accentRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).translate('no_addresses'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).translate('add_address_to_continue'),
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditAddressScreen(),
                  ),
                );
                if (result == true) {
                  _loadAddresses();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context).translate('add_first_address')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final address = _addresses[index];
        return _buildAddressCard(address);
      },
    );
  }

  Widget _buildAddressCard(UserAddress address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              address.isDefault ? AppColors.accentRed : AppColors.borderLight,
          width: address.isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với tên và badge mặc định
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        address.addressTypeIcon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context).translate('default'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Số điện thoại
            Text(
              address.phone,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 8),

            // Địa chỉ
            Text(
              address.fullAddress,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),

            // Loại địa chỉ
            Text(
              address.addressTypeName,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons (responsive layout)
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isNarrow = constraints.maxWidth < 360;
                final buttonStyleBase = OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  minimumSize: const Size.fromHeight(44),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                );

                if (isNarrow) {
                  // Stack vertically on narrow screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!address.isDefault) ...[
                        OutlinedButton.icon(
                          onPressed: () => _setDefaultAddress(address),
                          icon: const Icon(Icons.star_outline, size: 18),
                          label: Text(AppLocalizations.of(context).translate('set_as_default')),
                          style: buttonStyleBase.copyWith(
                            foregroundColor: WidgetStateProperty.all(
                              AppColors.accentRed,
                            ),
                            side: WidgetStateProperty.all(
                              const BorderSide(color: AppColors.accentRed),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      AddEditAddressScreen(address: address),
                            ),
                          );
                          if (result == true) {
                            _loadAddresses();
                          }
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(AppLocalizations.of(context).edit),
                        style: buttonStyleBase.copyWith(
                          foregroundColor: WidgetStateProperty.all(
                            AppColors.primary,
                          ),
                          side: WidgetStateProperty.all(
                            const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showDeleteDialog(address),
                        icon: const Icon(Icons.delete, size: 18),
                        label: Text(AppLocalizations.of(context).delete),
                        style: buttonStyleBase.copyWith(
                          foregroundColor: WidgetStateProperty.all(Colors.red),
                          side: WidgetStateProperty.all(
                            const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Row layout for wider screens
                return Row(
                  children: [
                    if (!address.isDefault)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _setDefaultAddress(address),
                          icon: const Icon(Icons.star_outline, size: 18),
                          label: Text(AppLocalizations.of(context).translate('set_as_default')),
                          style: buttonStyleBase.copyWith(
                            foregroundColor: WidgetStateProperty.all(
                              AppColors.accentRed,
                            ),
                            side: WidgetStateProperty.all(
                              const BorderSide(color: AppColors.accentRed),
                            ),
                          ),
                        ),
                      ),
                    if (!address.isDefault) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      AddEditAddressScreen(address: address),
                            ),
                          );
                          if (result == true) {
                            _loadAddresses();
                          }
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(AppLocalizations.of(context).edit),
                        style: buttonStyleBase.copyWith(
                          foregroundColor: WidgetStateProperty.all(
                            AppColors.primary,
                          ),
                          side: WidgetStateProperty.all(
                            const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteDialog(address),
                        icon: const Icon(Icons.delete, size: 18),
                        label: Text(AppLocalizations.of(context).delete),
                        style: buttonStyleBase.copyWith(
                          foregroundColor: WidgetStateProperty.all(Colors.red),
                          side: WidgetStateProperty.all(
                            const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
