import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';

class OrderDebtConfirmationScreen extends StatelessWidget {
  final double totalAmount;
  final double paidAmount;
  final double debtAmount;
  final String customerName;
  final String? customerPhone;
  final String? locationName;
  final int? debtorId;

  const OrderDebtConfirmationScreen({
    super.key,
    required this.totalAmount,
    required this.paidAmount,
    required this.debtAmount,
    required this.customerName,
    this.customerPhone,
    this.locationName,
    this.debtorId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order_create.debt_confirm')),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 80,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                l10n.translate('order_create.debt_confirm_success'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildInfoRow(l10n.translate('order.detail_customer_name'), customerName),
            _buildInfoRow(
              l10n.translate('order_payment.order_total'),
              CurrencyFormatter.formatVND(totalAmount),
            ),
            _buildInfoRow(
              l10n.translate('order_payment.paid_amount'),
              CurrencyFormatter.formatVND(paidAmount),
            ),
            _buildInfoRow(
              l10n.translate('order_create.amount_debt'),
              CurrencyFormatter.formatVND(debtAmount),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text(l10n.translate('common.back_home')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
