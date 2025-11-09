import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/user_address.dart';
import '../../services/supabase_address_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../utils/phone_validator.dart';
import '../../l10n/app_localizations.dart';

class AddEditAddressScreen extends StatefulWidget {
  final UserAddress? address; // null nếu là thêm mới, có giá trị nếu là chỉnh sửa

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _wardController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  bool _isLoading = false;
  bool _isDefault = false;
  String _addressType = 'home';
  int? _currentUserId;

  final List<Map<String, String>> _addressTypes = [
    {'value': 'home', 'label': 'home'},
    {'value': 'office', 'label': 'office'},
    {'value': 'other', 'label': 'other'},
  ];
  String _localizeAddressType(String key) {
    switch (key) {
      case 'home':
        return AppLocalizations.of(context).translate('address_type');
      case 'office':
        return AppLocalizations.of(context).translate('office');
      default:
        return AppLocalizations.of(context).translate('other');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    final user = await SupabaseAuthService.getCurrentUser();
    _currentUserId = user?.maNguoiDung;

    if (widget.address != null) {
      // Chỉnh sửa địa chỉ
      final address = widget.address!;
      _fullNameController.text = address.fullName;
      _phoneController.text = address.phone;
      _addressLine1Controller.text = address.addressLine1;
      _addressLine2Controller.text = address.addressLine2 ?? '';
      _wardController.text = address.ward ?? '';
      _districtController.text = address.district ?? '';
      _cityController.text = address.city;
      _postalCodeController.text = address.postalCode ?? '';
      _isDefault = address.isDefault;
      _addressType = address.addressType;
    } else {
      // Thêm địa chỉ mới - set mặc định nếu chưa có địa chỉ nào
      if (_currentUserId != null) {
        final hasAddresses = await SupabaseAddressService.hasAddresses(_currentUserId!);
        _isDefault = !hasAddresses;
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: widget.address == null
            ? AppLocalizations.of(context).translate('add_address')
            : AppLocalizations.of(context).translate('edit_address'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Receiver info
              _buildSectionTitle(AppLocalizations.of(context).translate('receiver_info')),
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _fullNameController,
                label: AppLocalizations.of(context).translate('full_name') + ' *',
                hint: AppLocalizations.of(context).translate('enter_full_name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context).translate('enter_full_name');
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _phoneController,
                label: AppLocalizations.of(context).phone_number + ' *',
                hint: AppLocalizations.of(context).translate('enter_phone'),
                keyboardType: TextInputType.phone,
                inputFormatters: buildPhoneInputFormatters(),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return AppLocalizations.of(context).translate('enter_phone');
                  }
                  if (!isValidVietnamPhone(trimmed)) {
                    return AppLocalizations.of(context).translate('invalid_phone');
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Address section
              _buildSectionTitle(AppLocalizations.of(context).translate('address_section')),
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _addressLine1Controller,
                label: AppLocalizations.of(context).translate('address_line1') + ' *',
                hint: AppLocalizations.of(context).translate('address_line1_hint'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context).translate('address_line1');
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _addressLine2Controller,
                label: AppLocalizations.of(context).translate('address_line2'),
                hint: AppLocalizations.of(context).translate('address_line2_hint'),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _wardController,
                      label: AppLocalizations.of(context).translate('ward'),
                      hint: AppLocalizations.of(context).translate('ward'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _districtController,
                      label: AppLocalizations.of(context).translate('district'),
                      hint: AppLocalizations.of(context).translate('district'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _cityController,
                      label: AppLocalizations.of(context).translate('city') + ' *',
                      hint: AppLocalizations.of(context).translate('city'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context).translate('city');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _postalCodeController,
                      label: AppLocalizations.of(context).translate('postal_code'),
                      hint: '700000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Address type
              _buildSectionTitle(AppLocalizations.of(context).translate('address_type')),
              const SizedBox(height: 16),
              
              _buildAddressTypeSelector(),
              
              const SizedBox(height: 32),
              
              // Default address
              if (widget.address == null || !widget.address!.isDefault)
                _buildDefaultAddressToggle(),
              
              const SizedBox(height: 40),
              
              // Save button
              AppButton(
                text: widget.address == null
                    ? AppLocalizations.of(context).translate('add_address')
                    : AppLocalizations.of(context).translate('update'),
                onPressed: _isLoading ? null : _saveAddress,
                isLoading: _isLoading,
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildAddressTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: _addressTypes.map((type) {
          final isSelected = _addressType == type['value'];
          return InkWell(
            onTap: () {
              setState(() {
                _addressType = type['value']!;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentRed.withOpacity(0.05) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _localizeAddressType(type['label']!),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppColors.accentRed : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check,
                      color: AppColors.accentRed,
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDefaultAddressToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('set_default_address'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).translate('default_address_note'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isDefault,
            onChanged: (value) {
              setState(() {
                _isDefault = value;
              });
            },
            activeColor: AppColors.accentRed,
          ),
        ],
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final address = UserAddress(
        id: widget.address?.id ?? 0,
        userId: _currentUserId!,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim().isEmpty 
            ? null 
            : _addressLine2Controller.text.trim(),
        ward: _wardController.text.trim().isEmpty 
            ? null 
            : _wardController.text.trim(),
        district: _districtController.text.trim().isEmpty 
            ? null 
            : _districtController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty 
            ? null 
            : _postalCodeController.text.trim(),
        isDefault: _isDefault,
        addressType: _addressType,
        createdAt: widget.address?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.address == null) {
        // Thêm mới
        await SupabaseAddressService.addAddress(address);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm địa chỉ thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Cập nhật
        await SupabaseAddressService.updateAddress(address);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật địa chỉ thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}
