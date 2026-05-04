import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/reference/data/reference_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Payment Update Bottom Sheet - Cập nhật thanh toán
/// Theo thiết kế SC-ORD-03.2
class PaymentUpdateSheet extends StatefulWidget {
  final String customerName;
  final String customerPhone;
  final double totalDebt;
  final double totalPaid;
  final double remaining;
  final List<ReferenceItem> paymentMethods;
  final FutureOr<void> Function(
    double amount,
    String action,
    String paymentMethod,
    String? note,
  )
  onConfirm;

  const PaymentUpdateSheet({
    super.key,
    required this.customerName,
    required this.customerPhone,
    required this.totalDebt,
    required this.totalPaid,
    required this.remaining,
    required this.paymentMethods,
    required this.onConfirm,
  });

  @override
  State<PaymentUpdateSheet> createState() => _PaymentUpdateSheetState();
}

class _PaymentUpdateSheetState extends State<PaymentUpdateSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedAction =
      'decrease_debt'; // 'decrease_debt' or 'increase_debt'
  String? _selectedPaymentMethod;
  bool _isSubmitting = false;

  double get _enteredAmount {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(amountText) ?? 0;
  }

  bool get _canSubmit =>
      !_isSubmitting && _enteredAmount > 0 && _selectedPaymentMethod != null;

  _PaymentSummaryValues _buildSummaryValues() {
    final double baseRemaining = widget.remaining > 0
        ? widget.remaining
      : (widget.totalDebt > 0 ? widget.totalDebt : 0.0);
    final double baseTotalDebt = widget.totalDebt > 0
        ? widget.totalDebt
        : baseRemaining;
    final double baseTotalPaid = widget.totalPaid > 0 ? widget.totalPaid : 0.0;
    final double amount = _enteredAmount;

    if (amount <= 0) {
      return _PaymentSummaryValues(
        totalDebt: baseTotalDebt,
        totalPaid: baseTotalPaid,
        remaining: baseRemaining,
      );
    }

    if (_selectedAction == 'increase_debt') {
      return _PaymentSummaryValues(
        totalDebt: baseTotalDebt + amount,
        totalPaid: baseTotalPaid,
        remaining: baseRemaining + amount,
      );
    }

    final nextRemaining = (baseRemaining - amount)
        .clamp(0, double.infinity)
        .toDouble();
    final nextDebt = (baseTotalDebt - amount)
        .clamp(0, double.infinity)
        .toDouble();
    return _PaymentSummaryValues(
      totalDebt: nextDebt,
      totalPaid: baseTotalPaid + amount,
      remaining: nextRemaining,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.paymentMethods.isNotEmpty) {
      _selectedPaymentMethod = widget.paymentMethods.first.code;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_canSubmit) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onConfirm(
        _enteredAmount,
        _selectedAction,
        _selectedPaymentMethod!,
        _noteController.text.isEmpty ? null : _noteController.text,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = _buildSummaryValues();

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('debt.update_payment_title'),
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.customerName,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Customer Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('debt.customer_info'),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.customerName,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            widget.customerPhone,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Debt Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        l10n.translate('debt.total_owed'),
                        CurrencyFormatter.formatVND(summary.totalDebt),
                        AppColors.textPrimary,
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        l10n.translate('debt.paid_amount'),
                        CurrencyFormatter.formatVND(summary.totalPaid),
                        AppColors.success,
                      ),
                      const Divider(height: 16),
                      _buildSummaryRow(
                        l10n.translate('debt.remaining'),
                        CurrencyFormatter.formatVND(summary.remaining),
                        AppColors.danger,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Action Selection
                Text(
                  '${l10n.translate('debt.action')} *',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionRadio(
                        label: l10n.translate('debt.action_decrease_debt'),
                        value: 'decrease_debt',
                        groupValue: _selectedAction,
                        onChanged: (value) {
                          setState(() {
                            _selectedAction = value ?? 'decrease_debt';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildActionRadio(
                        label: l10n.translate('debt.action_increase_debt'),
                        value: 'increase_debt',
                        groupValue: _selectedAction,
                        onChanged: (value) {
                          setState(() {
                            _selectedAction = value ?? 'increase_debt';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Payment Amount
                Text(
                  '${l10n.translate('debt.payment_amount')} *',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: AppInputFormatters.withSqlInjectionGuard(
                    inputFormatters: [CurrencyInputFormatter()],
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    suffixText: 'VND',
                    suffixStyle: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Payment Method
                Text(
                  '${l10n.translate('debt.payment_method')} *',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 14,
                    ),
                  ),
                  items: widget.paymentMethods.map((method) {
                    return DropdownMenuItem<String>(
                      value: method.code,
                      child: Text(method.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Note
                Text(
                  l10n.translate('debt.note'),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.translate('debt.note_hint'),
                    hintStyle: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                        ),
                        child: Text(
                          l10n.translate('common.cancel'),
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _canSubmit ? _handleConfirm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: _isSubmitting
                              ? Row(
                                  key: const ValueKey('loading'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.translate('common.loading'),
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  l10n.translate('common.confirm'),
                                  key: const ValueKey('confirm'),
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isBold ? AppTextStyles.titleSmall : AppTextStyles.labelMedium)
              .copyWith(
                color: AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
        Text(
          value,
          style: (isBold ? AppTextStyles.titleMedium : AppTextStyles.titleSmall)
              .copyWith(color: valueColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildActionRadio({
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSummaryValues {
  final double totalDebt;
  final double totalPaid;
  final double remaining;

  const _PaymentSummaryValues({
    required this.totalDebt,
    required this.totalPaid,
    required this.remaining,
  });
}
