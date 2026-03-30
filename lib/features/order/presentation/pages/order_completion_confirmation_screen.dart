import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order_bloc.dart';
import 'order_invoice_preview_screen.dart';

class OrderCompletionConfirmationScreen extends StatefulWidget {
  final OrderEntity order;

  const OrderCompletionConfirmationScreen({super.key, required this.order});

  @override
  State<OrderCompletionConfirmationScreen> createState() =>
      _OrderCompletionConfirmationScreenState();
}

class _OrderCompletionConfirmationScreenState
    extends State<OrderCompletionConfirmationScreen> {
  bool _isSubmitting = false;

  Future<void> _completeOrder() async {
    setState(() => _isSubmitting = true);
    final l10n = AppLocalizations.of(context);
    final repository = context.read<OrderBloc>().repository;

    try {
      final completedOrder = await repository.completeOrder(widget.order.id);
      if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.translate('order_create.payment_success'),
          type: AppSnackBarType.success,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderInvoicePreviewScreen(order: completedOrder),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: e.toString(),
          type: AppSnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(l10n.translate('order_payment.pending_confirmation')),
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
                Icons.pending_actions,
                color: AppColors.primary,
                size: 82,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.translate('order_payment.order_summary'),
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
                      label: l10n.translate('order_payment.order_total'),
                      value: CurrencyFormatter.formatVND(
                        widget.order.totalAmount,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow(
                      label: l10n.translate('order.detail_order_id'),
                      value: widget.order.id,
                    ),
                    if (widget.order.orderCode.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoRow(
                        label: l10n.translate('order.detail_order_code'),
                        value: widget.order.orderCode,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow(
                      label: l10n.translate('order.detail_location'),
                      value: widget.order.locationName,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow(
                      label: l10n.translate('order.detail_customer_name'),
                      value: widget.order.customerName?.isNotEmpty == true
                          ? '${widget.order.customerName} (${l10n.translate("order_create.customer_loyal")})'
                          : l10n.translate('order_create.customer_walkin'),
                    ),
                    if (widget.order.customerPhone?.isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoRow(
                        label: l10n.translate('order.detail_customer_phone'),
                        value: widget.order.customerPhone!,
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: _isSubmitting ? null : _completeOrder,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n.translate('order_payment.complete_order'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderInvoicePreviewScreen(order: widget.order),
                      ),
                    );
                  },
                  child: Text(l10n.translate('order_payment.invoice_preview')),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                  },
                  child: Text(l10n.translate('order_payment.view_order_list')),
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
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
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
