import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../providers/auth_provider.dart';
import '../../config/supabase_config.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';

class VerifyPhoneScreen extends StatefulWidget {
  final String phoneNumber;
  
  const VerifyPhoneScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSendingOTP = false;
  String? _otpCode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isSendingOTP = true;
      _errorMessage = null;
    });

    try {
      // Validate số điện thoại với phone_numbers_parser
      final phoneNumberObj = PhoneNumber.parse(
        widget.phoneNumber,
        destinationCountry: IsoCode.VN,
      );
      
      if (!phoneNumberObj.isValid()) {
        setState(() {
          _isSendingOTP = false;
          _errorMessage = AppLocalizations.of(context).translate('phone_invalid') ?? 'Số điện thoại không hợp lệ';
        });
        return;
      }

      // Tạo OTP code (6 số ngẫu nhiên)
      final otp = _generateOTP();
      _otpCode = otp;

      // TODO: Gửi OTP qua SMS service (Twilio, Firebase, etc.)
      // Ở đây tạm thời chỉ log ra console để test
      if (kDebugMode) {
        print('OTP Code for ${widget.phoneNumber}: $otp');
      }

      // Lưu OTP vào database để verify sau
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final client = SupabaseConfig.client;
        await client
            .from('users')
            .update({
              'otp': otp,
              'thoi_diem_het_han_otp': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
            })
            .eq('id', authProvider.user!.maNguoiDung);
      }
      
      setState(() {
        _isSendingOTP = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mã OTP đã được gửi đến ${_formatPhoneNumber(widget.phoneNumber)}\nMã OTP: $otp (Demo)'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSendingOTP = false;
        _errorMessage = 'Lỗi gửi OTP: $e';
      });
    }
  }

  String _generateOTP() {
    // Tạo mã OTP 6 số ngẫu nhiên
    final random = DateTime.now().millisecondsSinceEpoch;
    final otp = (random % 900000 + 100000).toString();
    return otp;
  }

  String? _validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).translate('otp_required') ?? 'Vui lòng nhập mã OTP';
    }
    
    if (value.length != 6) {
      return AppLocalizations.of(context).translate('otp_6_digits') ?? 'Mã OTP phải có 6 số';
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return AppLocalizations.of(context).translate('otp_numbers_only') ?? 'Mã OTP chỉ được chứa số';
    }
    
    return null;
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final enteredOTP = _otpController.text.trim();
      
      // Verify OTP
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Người dùng chưa đăng nhập';
        });
        return;
      }

      final client = SupabaseConfig.client;
      
      // Lấy OTP từ database
      final userData = await client
          .from('users')
          .select('otp, thoi_diem_het_han_otp')
          .eq('id', authProvider.user!.maNguoiDung)
          .single();

      final storedOTP = userData['otp'] as String?;
      final expiryTime = userData['thoi_diem_het_han_otp'] as String?;

      if (storedOTP == null || storedOTP != enteredOTP) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context).translate('otp_invalid') ?? 'Mã OTP không đúng';
        });
        return;
      }

      // Kiểm tra OTP còn hạn không
      if (expiryTime != null) {
        final expiry = DateTime.parse(expiryTime);
        if (DateTime.now().isAfter(expiry)) {
          setState(() {
            _isLoading = false;
            _errorMessage = AppLocalizations.of(context).translate('otp_expired') ?? 'Mã OTP đã hết hạn';
          });
          return;
        }
      }

      // OTP đúng, cập nhật số điện thoại
      await client
          .from('users')
          .update({
            'so_dien_thoai': widget.phoneNumber,
            'otp': null,
            'thoi_diem_het_han_otp': null,
          })
          .eq('id', authProvider.user!.maNguoiDung);

      setState(() {
        _isLoading = false;
      });

      // Reload user
      await authProvider.refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('phone_verified_success') ?? 'Xác nhận số điện thoại thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi: $e';
      });
    }
  }

  String _formatPhoneNumber(String phone) {
    // Format: 0123 456 789
    if (phone.length == 10) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).translate('verify_phone') ?? 'Xác nhận số điện thoại',
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
                  AppLocalizations.of(context).translate('enter_otp') ?? 'Nhập mã OTP',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppLocalizations.of(context).translate('otp_sent_to') ?? 'Mã OTP đã được gửi đến số điện thoại'}: ${_formatPhoneNumber(widget.phoneNumber)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(8),
                    fieldHeight: 56,
                    fieldWidth: 50,
                    activeFillColor: AppColors.cardBackground,
                    inactiveFillColor: AppColors.cardBackground,
                    selectedFillColor: AppColors.cardBackground,
                    activeColor: AppColors.accentRed,
                    inactiveColor: AppColors.borderLight,
                    selectedColor: AppColors.accentRed,
                  ),
                  enableActiveFill: true,
                  onChanged: (value) {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                  validator: _validateOTP,
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.accentRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isSendingOTP ? null : _sendOTP,
                  child: _isSendingOTP
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context).translate('resend_otp') ?? 'Gửi lại mã OTP'),
                ),
                const SizedBox(height: 16),
                AppButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  text: AppLocalizations.of(context).translate('verify') ?? 'Xác nhận',
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context).translate('cancel') ?? 'Hủy'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

