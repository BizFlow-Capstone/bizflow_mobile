import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/entities/debtor_entity.dart';
import '../../presentation/bloc/debtor_bloc.dart';
import '../../presentation/bloc/debtor_event.dart';
import '../../presentation/bloc/debtor_state.dart';

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
        child: BlocBuilder<DebtorBloc, DebtorState>(
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
                                  item.amount < 0
                                      ? l10n.translate('debt.adjust_reduce')
                                      : l10n.translate('debt.adjust_increase'),
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: item.amount < 0
                                        ? AppColors.success
                                        : AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatVND(item.amount),
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: item.amount < 0
                                        ? AppColors.success
                                        : AppColors.danger,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.translate('debt.payment_method')}: ${item.paymentMethod}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
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
                  CurrencyFormatter.formatVND(detail.currentBalance),
                  AppColors.danger,
                ),
              ),
              Expanded(
                child: _infoItem(
                  l10n.translate('debt.credit_limit'),
                  CurrencyFormatter.formatVND(detail.creditLimit),
                  AppColors.textPrimary,
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
}
