import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/auth_api_service.dart';

/// SC-AUT-02: Verify OTP Page
/// Trang xác thực mã OTP gồm 6 ô nhập liệu
class VerifyOtpPage extends StatefulWidget {
  final String phoneNumber;

  const VerifyOtpPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;

  bool _isLoading = false;
  bool _canResend = false;
  int _remainingSeconds = 60;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        _startResendTimer();
      } else if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  void _handleOtpInput(int index, String value) {
    if (value.isNotEmpty && value.length == 1) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
    }
  }

  String _getOtpCode() {
    return _otpControllers.map((c) => c.text).join();
  }

  void _handleVerify() async {
    final l10n = AppLocalizations.of(context);
    final otpCode = _getOtpCode();

    if (otpCode.length != 6) {
      _showError(l10n.translate('auth.otp_incomplete'));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = AuthApiService();
      final response = await apiService.verifyOtp(
        phone: widget.phoneNumber,
        otpCode: otpCode,
      );

      if (response['success'] == true) {
        _showSuccess(l10n.translate('auth.verify_success'));

        // TODO: Save token to local storage
        // TODO: Navigate to home screen
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        });
      } else {
        _showError(response['message'] ?? l10n.translate('auth.verify_failed'));
      }
    } catch (e) {
      _showError('${l10n.translate('common.error')}: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleResend() async {
    final l10n = AppLocalizations.of(context);
    if (!_canResend) return;

    try {
      final apiService = AuthApiService();
      final response = await apiService.resendOtp(
        phone: widget.phoneNumber,
      );

      if (response['success'] == true) {
        _showSuccess(l10n.translate('auth.resend_success'));

        setState(() {
          _canResend = false;
          _remainingSeconds = 60;
        });
        _startResendTimer();

        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
      } else {
        _showError(response['message'] ?? l10n.translate('auth.resend_failed'));
      }
    } catch (e) {
      _showError('${l10n.translate('common.error')}: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.translate('auth.verify_otp_title')),
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF23C4C1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phonelink_lock,
                  size: 40,
                  color: Color(0xFF23C4C1),
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                l10n.translate('auth.verify_phone_title'),
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.md),

              // Description
              Text(
                '${l10n.translate('auth.verify_otp_subtitle')}\n${widget.phoneNumber}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xl),

              // OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (index) => _buildOtpBox(index),
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // Verify Button
              AppButton(
                label: _isLoading ? l10n.translate('common.loading') : l10n.translate('auth.verify_button'),
                isFullWidth: true,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handleVerify,
                type: AppButtonType.primary,
                size: AppButtonSize.large,
              ),
              SizedBox(height: AppSpacing.xl),

              // Resend Section
              if (_canResend)
                GestureDetector(
                  onTap: _handleResend,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${l10n.translate('auth.didnt_receive')} ',
                        style: AppTextStyles.bodyMedium,
                      ),
                      Text(
                        l10n.translate('auth.resend_otp'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF23C4C1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${l10n.translate('auth.resend_after')} ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      '$_remainingSeconds${l10n.translate('auth.seconds')}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF23C4C1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 50,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.divider,
          width: 2,
        ),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        onChanged: (value) => _handleOtpInput(index, value),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
