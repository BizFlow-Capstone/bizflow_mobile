import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../domain/entities/order_entity.dart';
import 'order_invoice_preview_screen.dart';

class OrderCompletionConfirmationScreen extends StatelessWidget {
  final OrderEntity order;

  const OrderCompletionConfirmationScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(l10n.translate('common.done')),
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: const AppSyncStatusText(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 82,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.translate('order_create.payment_success'),
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      label: l10n.translate('order_create.total'),
                      value: CurrencyFormatter.formatVND(order.totalAmount),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow(
                      label: l10n.translate('order.detail_order_id'),
                      value: order.id,
                    ),
                    if (order.orderCode.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoRow(
                        label: l10n.translate('order.detail_order_code'),
                        value: order.orderCode,
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderInvoicePreviewScreen(order: order),
                      ),
                    );
                  },
                  child: Text(l10n.translate('order.invoice_preview')),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                  },
                  child: Text(l10n.translate('order_create.back_to_list')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
