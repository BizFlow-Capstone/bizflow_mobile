import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../domain/entities/order_item_entity.dart';
import '../bloc/order_bloc.dart';
import 'order_completion_confirmation_screen.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';

class OrderPayNowScreen extends StatefulWidget {
  final double totalAmount;
  final List<OrderItemEntity> items;
  final String? locationId;
  final String pendingOrderId;
  final int? debtorId;
  final String? note;

  const OrderPayNowScreen({
    super.key,
    required this.totalAmount,
    required this.items,
    this.locationId,
    required this.pendingOrderId,
    this.debtorId,
    this.note,
  });

  @override
  State<OrderPayNowScreen> createState() => _OrderPayNowScreenState();
}

class _OrderPayNowScreenState extends State<OrderPayNowScreen> {
  String _selectedMethod = 'cash'; // cash | transfer
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(l10n.translate('order_create.pay_now')),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.black,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const AppSyncStatusText(),
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderPublished) {
            if (!mounted) return;
            setState(() {
              _isSubmitting = false;
            });

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    OrderCompletionConfirmationScreen(order: state.order),
              ),
            );
          } else if (state is OrderUpdated) {
            if (!mounted) return;
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: const Text(
                    'Đã cập nhật đơn hàng thành công (Trạng thái: Chờ)',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            // Pop back to OrderDetailScreen or Accounting Hub
            Navigator.of(context).popUntil(
              (route) =>
                  route.isFirst || route.settings.name == '/order_detail',
            );
          } else if (state is OrderError) {
            if (!mounted) return;
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              l10n.translate('order_create.total'),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              CurrencyFormatter.formatVND(widget.totalAmount),
                              style: AppTextStyles.displaySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        children: [
                          Expanded(
                            child: _buildMethodButton(
                              icon: Icons.money,
                              title: l10n.translate(
                                'order_create.pay_method_cash',
                              ),
                              isSelected: _selectedMethod == 'cash',
                              onTap: () {
                                setState(() {
                                  _selectedMethod = 'cash';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildMethodButton(
                              icon: Icons.qr_code,
                              title: l10n.translate(
                                'order_create.pay_method_transfer',
                              ),
                              isSelected: _selectedMethod == 'transfer',
                              onTap: () {
                                setState(() {
                                  _selectedMethod = 'transfer';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      if (_selectedMethod == 'transfer')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(color: AppColors.divider),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(
                                Icons.qr_code_2,
                                size: 132,
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                '${l10n.translate('order_create.transfer_bank_name')}: Vietcombank\n'
                                '${l10n.translate('order_create.transfer_account')}: 0123456789\n'
                                '${l10n.translate('order_create.transfer_account_holder')}: NGUYEN VAN A',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          'Đơn pending: ${widget.pendingOrderId}\nẤn Thanh toán để complete đơn hàng.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),
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
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Text(
                                  l10n.translate(
                                    'order_create.proceed_payment',
                                  ),
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final l10n = AppLocalizations.of(context);
    final locationIdText = widget.locationId?.trim();
    final businessLocationId = int.tryParse(locationIdText ?? '');
    if (businessLocationId == null || businessLocationId <= 0) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.translate('debt.location_required'))),
        );
      return;
    }

    final pendingOrderId = widget.pendingOrderId.trim();
    if (pendingOrderId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.translate('order.pending_required'))),
        );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final allowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.orderManagement,
    );
    if (!allowed) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      return;
    }

    final cashAmount = _selectedMethod == 'cash'
        ? widget.totalAmount.roundToDouble()
        : 0.0;
    final bankAmount = _selectedMethod == 'transfer'
        ? widget.totalAmount.roundToDouble()
        : 0.0;

    context.read<OrderBloc>().add(
      UpdateOrderRequested(
        orderId: pendingOrderId,
        businessLocationId: businessLocationId.toString(),
        items: widget.items,
        cashAmount: cashAmount,
        bankAmount: bankAmount,
        debtAmount: 0,
        debtorId: widget.debtorId,
        note: widget.note,
      ),
    );
  }

  Widget _buildMethodButton({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.success.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.success : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? AppColors.success : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.success : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
