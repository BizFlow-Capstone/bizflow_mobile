import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../domain/entities/order_item_entity.dart';
import '../bloc/order_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderPayNowScreen extends StatefulWidget {
  final double totalAmount;
  final List<OrderItemEntity> items;
  final String? locationId;
  final String? note;

  const OrderPayNowScreen({
    super.key,
    required this.totalAmount,
    required this.items,
    this.locationId,
    this.note,
  });

  @override
  State<OrderPayNowScreen> createState() => _OrderPayNowScreenState();
}

class _OrderPayNowScreenState extends State<OrderPayNowScreen> {
  String _selectedMethod = 'cash'; // 'cash' or 'transfer'

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
          if (state is OrderCreated) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.translate('common.success')),
                content: Text(
                  l10n.translate('order_create.payment_success'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Dialog
                      Navigator.popUntil(
                        context,
                        ModalRoute.withName('/home'),
                      );
                    },
                    child: Text(l10n.translate('common.ok')),
                  ),
                ],
              ),
            );
          } else if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
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
                    const SizedBox(height: AppSpacing.xxl),

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
                        onPressed: () {
                          if (widget.locationId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Location ID is required'),
                              ),
                            );
                            return;
                          }

                          context.read<OrderBloc>().add(
                                CreateOrderRequested(
                                  locationId: widget.locationId!,
                                  items: widget.items,
                                  note: widget.note,
                                ),
                              );
                        },
                        child: Text(
                          l10n.translate('order_create.proceed_payment'),
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
