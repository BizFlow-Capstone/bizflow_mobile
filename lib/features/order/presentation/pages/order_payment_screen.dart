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
import '../../../debt/domain/entities/debtor_entity.dart';
import '../../../debt/presentation/bloc/debtor_bloc.dart';
import '../../../debt/presentation/bloc/debtor_event.dart';
import '../../../debt/presentation/bloc/debtor_state.dart';
import '../../data/order_api_service.dart';
import '../../domain/entities/order_item_entity.dart';
import '../bloc/order_bloc.dart';

class OrderPaymentScreen extends StatefulWidget {
  final double totalAmount;
  final List<OrderItemEntity> items;
  final String? locationId;
  final String? locationName;
  final String? pendingOrderId;
  final int? initialDebtorId;
  final String? initialDebtorName;
  final String? customerName;
  final String? customerPhone;
  final String? note;

  const OrderPaymentScreen({
    super.key,
    required this.totalAmount,
    required this.items,
    this.locationId,
    this.locationName,
    this.pendingOrderId,
    this.initialDebtorId,
    this.initialDebtorName,
    this.customerName,
    this.customerPhone,
    this.note,
  });

  @override
  State<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends State<OrderPaymentScreen> {
  final TextEditingController _cashController = TextEditingController(text: '0');
  final TextEditingController _bankController = TextEditingController(text: '0');
  final TextEditingController _debtController = TextEditingController(text: '0');
  
  DebtorEntity? _selectedDebtor;
  bool _isSubmitting = false;

  double get _cashAmount => CurrencyFormatter.parse(_cashController.text)?.toDouble() ?? 0;
  double get _bankAmount => CurrencyFormatter.parse(_bankController.text)?.toDouble() ?? 0;
  double get _debtAmount => CurrencyFormatter.parse(_debtController.text)?.toDouble() ?? 0;
  double get _totalPaid => _cashAmount + _bankAmount + _debtAmount;
  double get _remaining => widget.totalAmount - _totalPaid;

  @override
  void initState() {
    super.initState();
    _cashController.text = CurrencyFormatter.formatNumber(widget.totalAmount.round());
    
    if (widget.initialDebtorId != null && widget.initialDebtorId! > 0) {
      _selectedDebtor = DebtorEntity(
        debtorId: widget.initialDebtorId!,
        name: widget.initialDebtorName ?? widget.customerName ?? '',
        phone: widget.customerPhone ?? '',
        businessLocationId: int.tryParse(widget.locationId ?? '0') ?? 0,
        businessLocationName: widget.locationName ?? '',
        creditLimit: 0.0,
        currentBalance: 0.0,
        isActive: true,
      );
    }

    final locId = int.tryParse(widget.locationId ?? '');
    if (locId != null) {
      context.read<DebtorBloc>().add(LoadActiveDebtorsByLocationRequested(
        locationId: locId,
      ));
    } else {
      context.read<DebtorBloc>().add(const LoadDebtorsRequested());
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _bankController.dispose();
    _debtController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    setState(() {});
  }

  Future<void> _submitPayment({bool confirmLowStock = false, bool confirmCreditLimit = false}) async {
    final l10n = AppLocalizations.of(context);
    if (_remaining.abs() > 10) { 
      AppSnackBar.show(
          context,
          message: l10n.translate('order_payment.error_total_mismatch'),
          type: AppSnackBarType.error
      );
      return;
    }

    if (_debtAmount > 0 && _selectedDebtor == null) {
      AppSnackBar.show(
        context,
        message: l10n.translate('order_payment.error_select_debtor'),
        type: AppSnackBarType.error
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final repository = context.read<OrderBloc>().repository;
    
    final body = {
      'businessLocationId': int.tryParse(widget.locationId ?? '0'),
      'items': widget.items.map((e) => {
        if (e.saleItemId != null && e.saleItemId! > 0) 'saleItemId': e.saleItemId,
        if (e.productId.isNotEmpty) 'productId': e.productId,
        'quantity': e.quantity,
        'discount': e.discount,
      }).toList(),
      'cashAmount': _cashAmount,
      'bankAmount': _bankAmount,
      'debtAmount': _debtAmount,
      if (_debtAmount > 0 && _selectedDebtor != null) 'debtorId': _selectedDebtor!.debtorId,
      if (widget.note != null) 'note': widget.note,
      'confirmLowStock': confirmLowStock,
      'confirmCreditLimitExceeded': confirmCreditLimit,
    };

    try {
      if (widget.pendingOrderId != null) {
        await repository.updateOrder(
            orderId: widget.pendingOrderId!,
            requestBody: body
        );
        
        // Record debt adjustment if needed
        if (_debtAmount > 0 && _selectedDebtor != null) {
          final debtorRepo = context.read<DebtorBloc>().repository;
          await debtorRepo.recordDebtAdjustment(
            debtorId: _selectedDebtor!.debtorId,
            amount: _debtAmount,
            paymentMethod: _cashAmount > 0 ? 'cash' : (_bankAmount > 0 ? 'bank' : 'cash'),
            notes: widget.note,
          );
        }

        if (mounted) {
          AppSnackBar.show(
            context,
            message: l10n.translate('order_payment.success_update_pending'),
            type: AppSnackBarType.success,
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        await repository.createOrder(body);

        // Record debt adjustment if needed
        if (_debtAmount > 0 && _selectedDebtor != null) {
          final debtorRepo = context.read<DebtorBloc>().repository;
          await debtorRepo.recordDebtAdjustment(
            debtorId: _selectedDebtor!.debtorId,
            amount: _debtAmount,
            paymentMethod: _cashAmount > 0 ? 'cash' : (_bankAmount > 0 ? 'bank' : 'cash'),
            notes: widget.note,
          );
        }

        if (mounted) {
          AppSnackBar.show(
            context,
            message: l10n.translate('order_create.payment_success'),
            type: AppSnackBarType.success,
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (e is OrderConfirmationRequiredException) {
        final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.translate('order_create.confirm_continue_title')),
              content: Text('${e.toString()}\n\n${l10n.translate('order_create.confirm_continue_message')}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.translate('common.cancel')),
                ),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.translate('common.confirm')),
                ),
              ],
            )
        );

        if (confirm == true) {
          setState(() => _isSubmitting = false);
          await _submitPayment(
              confirmLowStock: e.warnings.contains('LOW_STOCK_CONFIRM_REQUIRED') || confirmLowStock,
              confirmCreditLimit: e.warnings.contains('CREDIT_LIMIT_CONFIRM_REQUIRED') || confirmCreditLimit
          );
        }
        return;
      }

      AppSnackBar.show(
        context,
        message: e.toString(),
        type: AppSnackBarType.error,
      );
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
        title: Text(l10n.translate('order_payment.title')),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.black,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const AppSyncStatusText(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTotalSection(l10n),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPaymentInputs(l10n),
                    const SizedBox(height: AppSpacing.lg),
                    if (_debtAmount > 0) _buildDebtorSection(l10n),
                  ],
                ),
              ),
            ),
            _buildBottomAction(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Text(l10n.translate('order_payment.order_total'), style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.formatVND(widget.totalAmount),
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          if (_remaining.abs() > 0.01) ...[
            const Divider(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.translate('order_payment.remaining')),
                Text(
                  CurrencyFormatter.formatVND(_remaining),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: _remaining > 0 ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentInputs(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.translate('order_payment.payment_methods'), style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        _buildAmountInput(
          controller: _cashController,
          label: l10n.translate('order_create.pay_method_cash'),
          icon: Icons.money,
          onChanged: _onAmountChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildAmountInput(
          controller: _bankController,
          label: l10n.translate('order_create.pay_method_transfer'),
          icon: Icons.account_balance,
          onChanged: _onAmountChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildAmountInput(
          controller: _debtController,
          label: l10n.translate('order_create.debt'),
          icon: Icons.history_edu,
          onChanged: _onAmountChanged,
        ),
      ],
    );
  }

  Widget _buildAmountInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        suffixText: 'VND',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [CurrencyInputFormatter()],
      onChanged: onChanged,
    );
  }

  Widget _buildDebtorSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.translate('order_create.customer_loyal'), style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        BlocBuilder<DebtorBloc, DebtorState>(
          builder: (context, state) {
            final debtors = state.activeDebtorsByLocation;
            
            return DropdownButtonFormField<int>(
              value: _selectedDebtor?.debtorId,
              decoration: InputDecoration(
                hintText: l10n.translate('debt.select_debtor'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
              items: debtors.map((debtor) {
                return DropdownMenuItem<int>(
                  value: debtor.debtorId,
                  child: Text('${debtor.name} (${debtor.phone})'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDebtor = debtors.firstWhere((d) => d.debtorId == value);
                  });
                }
              },
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () {
            // Future: Show create debtor sheet
          },
          icon: const Icon(Icons.person_add),
          label: Text(l10n.translate('order_payment.select_debtor_list')),
        ),
      ],
    );
  }

  Widget _buildBottomAction(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () => _submitPayment(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
              )
            : Text(
                l10n.translate('order_payment.confirm_and_complete'),
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
