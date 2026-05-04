import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../../domain/entities/debtor_entity.dart';
import '../../presentation/bloc/debtor_bloc.dart';
import '../../presentation/bloc/debtor_event.dart';
import '../../presentation/bloc/debtor_state.dart';
import '../../../../core/reference/presentation/bloc/reference_bloc.dart';
import '../../../../core/reference/presentation/bloc/reference_state.dart';
import '../../../../shared/services/permission_service.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../widgets/payment_update_sheet.dart';

class DebtDetailPage extends StatefulWidget {
  final int debtorId;

  const DebtDetailPage({super.key, required this.debtorId});

  @override
  State<DebtDetailPage> createState() => _DebtDetailPageState();
}

class _DebtDetailPageState extends State<DebtDetailPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final bloc = context.read<DebtorBloc>();
    bloc.add(LoadDebtorDetailRequested(debtorId: widget.debtorId));
    bloc.add(LoadDebtPaymentHistoryRequested(debtorId: widget.debtorId));
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.translate('debt.detail_title')),
      ),
      body: SafeArea(
        child: BlocConsumer<DebtorBloc, DebtorState>(
          listener: (context, state) {
            if (state.successMessage != null) {
              AppSnackBar.show(
                context,
                message: state.successMessage!,
                type: AppSnackBarType.success,
              );
            }
            if (state.errorMessage != null && state.debtorDetail != null) {
              AppSnackBar.show(
                context,
                message: state.errorMessage!,
                type: AppSnackBarType.error,
              );
            }
          },
          builder: (context, state) {
            final detail = state.debtorDetail;
            final history = state.paymentHistory;

            if (detail == null && state.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(state.errorMessage!),
                ),
              );
            }

            if (detail == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () async => _load(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _buildInfoCard(detail, l10n),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.translate('debt.payment_history'),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (history.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Text(
                        l10n.translate('debt.no_payment_history'),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    ...history.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  (item.action == 'decrease_debt' ||
                                          item.amount < 0)
                                      ? l10n.translate(
                                          'debt.action_decrease_debt',
                                        )
                                      : l10n.translate(
                                          'debt.action_increase_debt',
                                        ),
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color:
                                        (item.action == 'decrease_debt' ||
                                            item.amount < 0)
                                        ? AppColors.success
                                        : AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatVND(
                                    item.amount.abs(),
                                  ),
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color:
                                        (item.action == 'decrease_debt' ||
                                            item.amount < 0)
                                        ? AppColors.success
                                        : AppColors.danger,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            BlocBuilder<ReferenceBloc, ReferenceState>(
                              builder: (context, refState) {
                                String methodLabel =
                                    item.paymentMethodLabel ??
                                    item.paymentMethod;
                                if (refState is ReferenceLoaded) {
                                  final methods =
                                      refState.references['paymentMethods'] ??
                                      [];
                                  try {
                                    final match = methods.firstWhere(
                                      (m) => m.code == item.paymentMethod,
                                    );
                                    methodLabel = match.label;
                                  } catch (_) {}
                                }
                                return Text(
                                  '${l10n.translate('debt.payment_method')}: $methodLabel',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                );
                              },
                            ),
                            if ((item.notes ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${l10n.translate('debt.note')}: ${item.notes}',
                                  style: AppTextStyles.labelSmall,
                                ),
                              ),
                            if (item.createdAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _formatDateTime(item.createdAt!),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BlocBuilder<DebtorBloc, DebtorState>(
        builder: (context, state) {
          final detail = state.debtorDetail;
          if (detail == null) return const SizedBox.shrink();

          return Consumer<BusinessContext>(
            builder: (context, bizContext, child) {
              final isOwner = bizContext.isOwner;
              if (!PermissionService.canWriteAccounting(isOwner)) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: () => _showPaymentUpdateSheet(detail),
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
                    child: Text(
                      l10n.translate('debt.update_payment_title'),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<ReferenceItem> _paymentMethodsFromReference() {
    final refState = context.read<ReferenceBloc>().state;
    if (refState is ReferenceLoaded) {
      final methods =
          (refState.references['paymentMethods'] ?? const <ReferenceItem>[])
              .where((method) => method.code.trim().isNotEmpty)
              .toList();
      if (methods.isNotEmpty) {
        return methods;
      }
    }

    return const [
      ReferenceItem(code: 'CASH', label: 'CASH'),
      ReferenceItem(code: 'BANK_TRANSFER', label: 'BANK_TRANSFER'),
    ];
  }

  void _showPaymentUpdateSheet(DebtorEntity detail) {
    final state = context.read<DebtorBloc>().state;
    final history = state.paymentHistory;
    final paidTotal = history.fold<double>(
      0,
      (sum, item) =>
          sum +
          ((item.action == 'decrease_debt' || item.amount < 0)
              ? item.amount.abs()
              : 0),
    );
    final currentDebt = detail.currentBalance > 0 ? detail.currentBalance : 0.0;
    final paymentMethods = _paymentMethodsFromReference();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentUpdateSheet(
        customerName: detail.name,
        customerPhone: detail.phone,
        totalDebt: currentDebt + paidTotal,
        totalPaid: paidTotal,
        remaining: currentDebt,
        paymentMethods: paymentMethods,
        onConfirm: (amount, action, paymentMethod, note) {
          Navigator.pop(ctx);
          context.read<DebtorBloc>().add(
            RecordDebtAdjustmentRequested(
              debtorId: widget.debtorId,
              amount: amount,
              action: action,
              paymentMethod: paymentMethod,
              notes: note,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(DebtorEntity detail, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.name,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail.phone,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _infoItem(
                  l10n.translate('debt.total_owed'),
                  CurrencyFormatter.formatVND(detail.currentBalance.abs()),
                  _getBalanceStatusColor(detail.currentBalance),
                ),
              ),
              Expanded(
                child: _infoItem(
                  l10n.translate('debt.status'),
                  _getBalanceStatusText(detail.currentBalance, l10n),
                  _getBalanceStatusColor(detail.currentBalance),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime value) {
    return DateFormatter.formatDateTime(value);
  }

  Color _getBalanceStatusColor(double currentBalance) {
    if (currentBalance > 0) {
      return AppColors.danger; // Khách đang nợ
    } else if (currentBalance < 0) {
      return AppColors.success; // Khách có credit
    }
    return AppColors.textSecondary; // Bằng 0
  }

  String _getBalanceStatusText(double currentBalance, AppLocalizations l10n) {
    if (currentBalance > 0) {
      return l10n.translate('debt.status_owed'); // Khách đang nợ
    } else if (currentBalance < 0) {
      return l10n.translate('debt.status_credit'); // Khách có credit
    }
    return l10n.translate('debt.status_balanced'); // Bằng 0
  }
}
