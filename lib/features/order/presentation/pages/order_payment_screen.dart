import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../../debt/domain/entities/debtor_entity.dart';
import '../../../debt/presentation/bloc/debtor_bloc.dart';
import '../../../debt/presentation/bloc/debtor_event.dart';
import '../../../debt/presentation/bloc/debtor_state.dart';
import '../../data/order_api_service.dart';
import '../../domain/entities/order_item_entity.dart';
import '../bloc/order_bloc.dart';
import 'order_completion_confirmation_screen.dart';

/// Payment method enum for selectable toggles
enum PaymentMethod { cash, bank, debt }

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
  final DateTime? documentDate;
  final String? documentNumber;

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
    this.documentDate,
    this.documentNumber,
  });

  @override
  State<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends State<OrderPaymentScreen> {
  final TextEditingController _cashController = TextEditingController(
    text: '0',
  );
  final TextEditingController _bankController = TextEditingController(
    text: '0',
  );
  final TextEditingController _debtController = TextEditingController(
    text: '0',
  );

  /// Currently selected payment methods
  final Set<PaymentMethod> _selectedMethods = {};

  DebtorEntity? _selectedDebtor;
  bool _isSubmitting = false;

  /// Track which controller the user is currently editing to avoid
  /// overwriting their input during auto-fill.
  PaymentMethod? _currentlyEditing;

  double get _cashAmount =>
      CurrencyFormatter.parse(_cashController.text)?.toDouble() ?? 0;
  double get _bankAmount =>
      CurrencyFormatter.parse(_bankController.text)?.toDouble() ?? 0;
  double get _debtAmount =>
      CurrencyFormatter.parse(_debtController.text)?.toDouble() ?? 0;
  double get _totalPaid => _cashAmount + _bankAmount + _debtAmount;
  double get _remaining => widget.totalAmount - _totalPaid;

  @override
  void initState() {
    super.initState();

    // Pre-select cash and auto-fill total
    _selectedMethods.add(PaymentMethod.cash);
    _cashController.text = CurrencyFormatter.formatNumber(
      widget.totalAmount.round(),
    );

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
      // Also enable debt method if debtor was passed in
      // _selectedMethods.add(PaymentMethod.debt);
      // NOTE: Removed as per user request to manual choice
    }

    final locId = int.tryParse(widget.locationId ?? '');
    if (locId != null) {
      context.read<DebtorBloc>().add(
        LoadActiveDebtorsByLocationRequested(locationId: locId),
      );
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

  // ──────────────────────── Toggle logic ────────────────────────

  void _onMethodToggled(PaymentMethod method) {
    setState(() {
      if (_selectedMethods.contains(method)) {
        // Don't allow deselecting the last method
        if (_selectedMethods.length <= 1) return;
        _selectedMethods.remove(method);
        // Zero out the deselected method
        _controllerFor(method).text = CurrencyFormatter.formatNumber(0);
        if (method == PaymentMethod.debt) {
          _selectedDebtor = null;
        }
      } else {
        _selectedMethods.add(method);
      }
      _recalculateAmounts();
    });
  }

  /// Auto-fill amounts for the selected methods.
  ///
  /// Rule: the *last* selected method (in display order: cash → bank → debt)
  /// that the user is NOT currently editing receives the remainder.
  void _recalculateAmounts() {
    final methods = _orderedSelectedMethods;
    if (methods.isEmpty) return;

    if (methods.length == 1) {
      // Single method → fill total
      _controllerFor(methods.first).text = CurrencyFormatter.formatNumber(
        widget.totalAmount.round(),
      );
      return;
    }

    // Find the method to auto-fill (the "last" one that user is NOT editing)
    PaymentMethod autoFillTarget = methods.last;
    if (_currentlyEditing != null && methods.contains(_currentlyEditing)) {
      // Pick another method to auto-fill (the last one that isn't the one being edited)
      for (int i = methods.length - 1; i >= 0; i--) {
        if (methods[i] != _currentlyEditing) {
          autoFillTarget = methods[i];
          break;
        }
      }
    }

    // Sum all methods except autoFillTarget
    double otherSum = 0;
    for (final m in methods) {
      if (m != autoFillTarget) {
        otherSum += _amountFor(m);
      }
    }

    final remaining = widget.totalAmount - otherSum;
    _controllerFor(autoFillTarget).text = CurrencyFormatter.formatNumber(
      remaining.round().clamp(0, 999999999999),
    );
  }

  /// Get ordered list of selected methods in display order
  List<PaymentMethod> get _orderedSelectedMethods {
    return PaymentMethod.values.where(_selectedMethods.contains).toList();
  }

  TextEditingController _controllerFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return _cashController;
      case PaymentMethod.bank:
        return _bankController;
      case PaymentMethod.debt:
        return _debtController;
    }
  }

  double _amountFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return _cashAmount;
      case PaymentMethod.bank:
        return _bankAmount;
      case PaymentMethod.debt:
        return _debtAmount;
    }
  }

  void _onAmountChanged(PaymentMethod method, String value) {
    _currentlyEditing = method;
    setState(() {
      _recalculateAmounts();
    });
    // Reset after frame so subsequent taps work
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentlyEditing = null;
    });
  }

  // ──────────────────────── Submit logic ────────────────────────

  Future<void> _submitPayment({
    bool confirmLowStock = false,
    bool confirmCreditLimit = false,
  }) async {
    final l10n = AppLocalizations.of(context);

    if (_selectedMethods.isEmpty) {
      AppSnackBar.show(
        context,
        message: l10n.translate('order_payment.select_at_least_one'),
        type: AppSnackBarType.error,
      );
      return;
    }

    if (_remaining.abs() > 10) {
      AppSnackBar.show(
        context,
        message: l10n.translate('order_payment.error_total_mismatch'),
        type: AppSnackBarType.error,
      );
      return;
    }

    if (_debtAmount > 0 && _selectedDebtor == null) {
      AppSnackBar.show(
        context,
        message: l10n.translate('order_payment.error_select_debtor'),
        type: AppSnackBarType.error,
      );
      return;
    }

    // Client-side credit limit exceeded warning
    if (_debtAmount > 0 &&
        _selectedDebtor != null &&
        _selectedDebtor!.creditLimit > 0 &&
        (_selectedDebtor!.currentBalance + _debtAmount) >
            _selectedDebtor!.creditLimit) {
      final confirmExceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.translate('debt.credit_limit_warning_title')),
          content: Text(l10n.translate('debt.credit_limit_warning_message')),
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
        ),
      );
      if (confirmExceed != true || !mounted) return;
    }

    setState(() => _isSubmitting = true);

    final repository = context.read<OrderBloc>().repository;

    final body = {
      'businessLocationId': int.tryParse(widget.locationId ?? '0'),
      'items': widget.items
          .map(
            (e) => {
              if (e.saleItemId != null && e.saleItemId! > 0)
                'saleItemId': e.saleItemId,
              if (e.productId.isNotEmpty) 'productId': e.productId,
              'quantity': e.quantity,
              'discount': e.discount,
            },
          )
          .toList(),
      'cashAmount': _cashAmount,
      'bankAmount': _bankAmount,
      'debtAmount': _debtAmount,
      if (_selectedDebtor != null) 'debtorId': _selectedDebtor!.debtorId,
      'customerName': _selectedDebtor?.name ?? widget.customerName,
      'customerPhone': _selectedDebtor?.phone ?? widget.customerPhone,
      if (widget.note != null) 'note': widget.note,
      if (widget.documentDate != null)
        'documentDate': widget.documentDate!.toIso8601String().split('T')[0],
      if (widget.documentNumber != null && widget.documentNumber!.isNotEmpty)
        'documentNumber': widget.documentNumber,
      'confirmLowStock': confirmLowStock,
      'confirmCreditLimitExceeded': confirmCreditLimit,
    };

    try {
      if (widget.pendingOrderId != null) {
        final order = await repository.updateOrder(
          orderId: widget.pendingOrderId!,
          requestBody: body,
        );

        if (_debtAmount > 0 && _selectedDebtor != null) {
          final debtorRepo = context.read<DebtorBloc>().repository;
          await debtorRepo.recordDebtAdjustment(
            debtorId: _selectedDebtor!.debtorId,
            amount: _debtAmount,
            paymentMethod: _cashAmount > 0
                ? 'cash'
                : (_bankAmount > 0 ? 'bank' : 'cash'),
            notes: widget.note,
          );
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderCompletionConfirmationScreen(order: order),
            ),
          );
        }
      } else {
        final order = await repository.createOrder(body);

        if (_debtAmount > 0 && _selectedDebtor != null) {
          final debtorRepo = context.read<DebtorBloc>().repository;
          await debtorRepo.recordDebtAdjustment(
            debtorId: _selectedDebtor!.debtorId,
            amount: _debtAmount,
            paymentMethod: _cashAmount > 0
                ? 'cash'
                : (_bankAmount > 0 ? 'bank' : 'cash'),
            notes: widget.note,
          );
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderCompletionConfirmationScreen(order: order),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (e is OrderConfirmationRequiredException) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.translate('order_create.confirm_continue_title')),
            content: Text(
              '${e.toString()}\n\n${l10n.translate('order_create.confirm_continue_message')}',
            ),
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
          ),
        );

        if (confirm == true) {
          setState(() => _isSubmitting = false);
          await _submitPayment(
            confirmLowStock:
                e.warnings.contains('LOW_STOCK_CONFIRM_REQUIRED') ||
                confirmLowStock,
            confirmCreditLimit:
                e.warnings.contains('CREDIT_LIMIT_CONFIRM_REQUIRED') ||
                confirmCreditLimit,
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

  // ──────────────────────── Build UI ────────────────────────

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
                    _buildMethodSelector(l10n),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSelectedMethodInputs(l10n),
                    if (_selectedMethods.contains(PaymentMethod.debt)) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildDebtorSection(l10n),
                    ],
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
          Text(
            l10n.translate('order_payment.order_total'),
            style: AppTextStyles.bodyMedium,
          ),
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

  // ──────────── Payment method selector chips ────────────

  Widget _buildMethodSelector(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('order_payment.select_methods'),
          style: AppTextStyles.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _buildMethodChip(
              method: PaymentMethod.cash,
              label: l10n.translate('order_payment.method_cash'),
              icon: Icons.money,
            ),
            _buildMethodChip(
              method: PaymentMethod.bank,
              label: l10n.translate('order_payment.method_bank'),
              icon: Icons.account_balance,
            ),
            _buildMethodChip(
              method: PaymentMethod.debt,
              label: l10n.translate('order_payment.method_debt'),
              icon: Icons.history_edu,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodChip({
    required PaymentMethod method,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedMethods.contains(method);
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      onSelected: (_) => _onMethodToggled(method),
    );
  }

  // ──────────── Dynamic amount inputs ────────────

  Widget _buildSelectedMethodInputs(AppLocalizations l10n) {
    final methods = _orderedSelectedMethods;
    if (methods.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          l10n.translate('order_payment.select_at_least_one'),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('order_payment.payment_methods'),
          style: AppTextStyles.titleSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        ...methods.map((method) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildAmountInput(
              method: method,
              controller: _controllerFor(method),
              label: _labelFor(method, l10n),
              icon: _iconFor(method),
              onChanged: (v) => _onAmountChanged(method, v),
            ),
          );
        }),
      ],
    );
  }

  String _labelFor(PaymentMethod method, AppLocalizations l10n) {
    switch (method) {
      case PaymentMethod.cash:
        return l10n.translate('order_payment.method_cash');
      case PaymentMethod.bank:
        return l10n.translate('order_payment.method_bank');
      case PaymentMethod.debt:
        return l10n.translate('order_payment.method_debt');
    }
  }

  IconData _iconFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.bank:
        return Icons.account_balance;
      case PaymentMethod.debt:
        return Icons.history_edu;
    }
  }

  Widget _buildAmountInput({
    required PaymentMethod method,
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
      inputFormatters: AppInputFormatters.withSqlInjectionGuard(
        inputFormatters: [CurrencyInputFormatter()],
      ),
      onChanged: onChanged,
    );
  }

  // ──────────── Debtor section (only when debt selected) ────────────

  Widget _buildDebtorSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('order_create.customer_loyal'),
          style: AppTextStyles.titleSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        BlocBuilder<DebtorBloc, DebtorState>(
          builder: (context, state) {
            final debtors = state.activeDebtorsByLocation;

            return DropdownButtonFormField<int>(
              initialValue: _selectedDebtor?.debtorId,
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
                    _selectedDebtor = debtors.firstWhere(
                      (d) => d.debtorId == value,
                    );
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

  // ──────────── Bottom action button ────────────

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
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                l10n.translate('order_payment.confirm_and_complete'),
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
