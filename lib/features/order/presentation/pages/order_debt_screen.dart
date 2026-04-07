import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../../debt/presentation/bloc/debtor_bloc.dart';
import '../../domain/entities/order_item_entity.dart';
import '../bloc/order_bloc.dart';
import 'order_completion_confirmation_screen.dart';
import 'order_debt_confirmation_screen.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';

class OrderDebtScreen extends StatefulWidget {
  final double totalAmount;
  final int? debtorId;
  final String? debtorName;
  final String customerName;
  final String customerPhone;
  final int? locationId;
  final String? locationName;
  final List<OrderItemEntity> items;
  final String? pendingOrderId;

  const OrderDebtScreen({
    super.key,
    required this.totalAmount,
    this.debtorId,
    this.debtorName,
    required this.customerName,
    required this.customerPhone,
    this.locationId,
    this.locationName,
    required this.items,
    this.pendingOrderId,
  });

  @override
  State<OrderDebtScreen> createState() => _OrderDebtScreenState();
}

class _OrderDebtScreenState extends State<OrderDebtScreen> {
  String _selectedDebtType = 'full'; // 'full' or 'partial'
  String _selectedPaymentMethod = 'cash';
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountPaidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    double amountPaid = 0;
    if (_selectedDebtType == 'partial' &&
        _amountPaidController.text.isNotEmpty) {
      amountPaid = (CurrencyFormatter.parse(_amountPaidController.text) ?? 0)
          .toDouble();
    }

    double debtAmount = widget.totalAmount - amountPaid;
    if (debtAmount < 0) debtAmount = 0;
    final hasPartialAmountError =
        _selectedDebtType == 'partial' &&
        (_amountPaidController.text.trim().isEmpty ||
            amountPaid <= 0 ||
            amountPaid > widget.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        title: Text(l10n.translate('order_create.debt')),
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
          if (state is OrderCreated || state is OrderUpdated) {
            if (!mounted) return;
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(
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
          } else if (state is OrderPublished) {
            if (!mounted) return;
            setState(() => _isSubmitting = false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    OrderCompletionConfirmationScreen(order: state.order),
              ),
            );
          } else if (state is OrderError) {
            if (!mounted) return;
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.translate('order_create.total'),
                              style: AppTextStyles.bodyMedium,
                            ),
                            Text(
                              CurrencyFormatter.formatVND(widget.totalAmount),
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDebtTypeButton(
                              title: l10n.translate(
                                'order_create.debt_type_full',
                              ),
                              isSelected: _selectedDebtType == 'full',
                              onTap: () {
                                setState(() {
                                  _selectedDebtType = 'full';
                                  _amountPaidController.clear();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildDebtTypeButton(
                              title: l10n.translate(
                                'order_create.debt_type_partial',
                              ),
                              isSelected: _selectedDebtType == 'partial',
                              onTap: () {
                                setState(() {
                                  _selectedDebtType = 'partial';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      if (_selectedDebtType == 'partial') ...[
                        TextField(
                          controller: _amountPaidController,
                          keyboardType: TextInputType.number,
                          inputFormatters:
                              AppInputFormatters.withSqlInjectionGuard(
                                inputFormatters: [CurrencyInputFormatter()],
                              ),
                          decoration: InputDecoration(
                            labelText: l10n.translate(
                              'order_create.amount_paid',
                            ),
                            helperText: l10n.translate(
                              'order_create.amount_paid_helper',
                            ),
                            errorText: hasPartialAmountError
                                ? l10n.translate(
                                    'order_create.amount_paid_invalid',
                                  )
                                : null,
                            suffixText: 'đ',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      if (_selectedDebtType == 'partial') ...[
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPaymentMethod,
                          decoration: InputDecoration(
                            labelText: l10n.translate('debt.payment_method'),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'cash',
                              child: Text(
                                l10n.translate('order_create.pay_method_cash'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'bank',
                              child: Text(
                                l10n.translate(
                                  'order_create.pay_method_transfer',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedPaymentMethod = value);
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: l10n.translate('debt.note'),
                          border: const OutlineInputBorder(),
                          hintText: l10n.translate('debt.note_hint'),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.translate('order_create.amount_debt'),
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatVND(debtAmount),
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () => _submitDebt(
                                  amountPaid: amountPaid,
                                  debtAmount: debtAmount,
                                ),
                          child: _isSubmitting
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      l10n.translate('common.loading'),
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ],
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

  Future<void> _submitDebt({
    required double amountPaid,
    required double debtAmount,
  }) async {
    final l10n = AppLocalizations.of(context);

    if (_selectedDebtType == 'partial') {
      if (_amountPaidController.text.trim().isEmpty ||
          amountPaid <= 0 ||
          amountPaid > widget.totalAmount) {
        AppSnackBar.show(
          context,
          message: l10n.translate('order_create.amount_paid_invalid'),
          type: AppSnackBarType.warning,
        );
        return;
      }
    }

    if (debtAmount <= 0) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDebtConfirmationScreen(
            totalAmount: widget.totalAmount,
            paidAmount: amountPaid,
            debtAmount: debtAmount,
            customerName: widget.customerName,
            customerPhone: widget.customerPhone,
            locationName: widget.locationName,
            debtorId: widget.debtorId,
          ),
        ),
      );
      return;
    }

    final confirmed = await _showConfirmDialog(
      amountPaid: amountPaid,
      debtAmount: debtAmount,
    );
    if (confirmed != true) return;

    if ((widget.customerName).trim().isEmpty) {
      AppSnackBar.show(
        context,
        message: l10n.translate('debt.customer_required'),
        type: AppSnackBarType.warning,
      );
      return;
    }

    if ((widget.locationId ?? 0) <= 0) {
      AppSnackBar.show(
        context,
        message: l10n.translate('debt.location_required'),
        type: AppSnackBarType.warning,
      );
      return;
    }

    final canManageOrder = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.orderManagement,
    );
    if (!canManageOrder) return;

    final canManageDebtor = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.debtorManagement,
    );
    if (!canManageDebtor) return;

    setState(() => _isSubmitting = true);
    try {
      final repository = context.read<DebtorBloc>().repository;
      int debtorId = widget.debtorId ?? 0;

      if (debtorId <= 0) {
        final createdDebtor = await repository.createDebtor(
          businessLocationId: widget.locationId!,
          name: widget.customerName.trim(),
          phone: widget.customerPhone.trim().isEmpty
              ? null
              : widget.customerPhone.trim(),
        );

        if (createdDebtor == null || createdDebtor.debtorId <= 0) {
          throw Exception(l10n.translate('debt.create_failed'));
        }
        debtorId = createdDebtor.debtorId;
      }

      final roundedPaid = amountPaid.roundToDouble();
      final roundedDebt = debtAmount.roundToDouble();

      final cashAmount = _selectedDebtType == 'full'
          ? 0.0
          : (_selectedPaymentMethod == 'cash' ? roundedPaid : 0.0);
      final bankAmount = _selectedDebtType == 'full'
          ? 0.0
          : (_selectedPaymentMethod == 'bank' ? roundedPaid : 0.0);

      final pendingOrderId = widget.pendingOrderId?.trim();
      if (pendingOrderId != null && pendingOrderId.isNotEmpty) {
        context.read<OrderBloc>().add(
          UpdateOrderRequested(
            orderId: pendingOrderId,
            businessLocationId: widget.locationId!.toString(),
            items: widget.items,
            cashAmount: cashAmount,
            bankAmount: bankAmount,
            debtAmount: roundedDebt,
            debtorId: debtorId,
            note: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          ),
        );
      } else {
        context.read<OrderBloc>().add(
          CreateOrderRequested(
            locationId: widget.locationId!.toString(),
            items: widget.items,
            cashAmount: cashAmount,
            bankAmount: bankAmount,
            debtAmount: roundedDebt,
            note: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          ),
        );
      }

      // 2. Record Debt Adjustment (already existing logic)
      await repository.recordDebtAdjustment(
        debtorId: debtorId,
        amount: roundedDebt,
        paymentMethod: _selectedDebtType == 'full'
            ? 'CASH'
            : _selectedPaymentMethod.toUpperCase(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDebtConfirmationScreen(
            totalAmount: widget.totalAmount,
            paidAmount: amountPaid,
            debtAmount: debtAmount,
            customerName: widget.customerName,
            customerPhone: widget.customerPhone,
            locationName: widget.locationName,
            debtorId: debtorId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool?> _showConfirmDialog({
    required double amountPaid,
    required double debtAmount,
  }) {
    final l10n = AppLocalizations.of(context);

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.translate('order_create.confirm_submit_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.translate('order_create.customer_name')}: ${widget.customerName}',
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.translate('order_create.total')}: ${CurrencyFormatter.formatVND(widget.totalAmount)}',
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.translate('order_create.amount_paid')}: ${CurrencyFormatter.formatVND(amountPaid)}',
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.translate('order_create.amount_debt')}: ${CurrencyFormatter.formatVND(debtAmount)}',
              ),
              if (_selectedDebtType == 'partial') ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${l10n.translate('debt.payment_method')}: ${_selectedPaymentMethod == 'cash' ? l10n.translate('order_create.pay_method_cash') : l10n.translate('order_create.pay_method_transfer')}',
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.translate('common.confirm')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDebtTypeButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(
            color: isSelected ? AppColors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
