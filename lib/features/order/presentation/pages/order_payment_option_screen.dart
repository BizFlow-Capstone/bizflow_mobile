import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../domain/entities/order_item_entity.dart';
import 'order_debt_screen.dart';
import 'order_pay_now_screen.dart';

class OrderPaymentOptionScreen extends StatelessWidget {
  final double totalAmount;
  final int? debtorId;
  final String? debtorName;
  final String customerName;
  final String customerPhone;
  final int? locationId;
  final String? locationName;
  final List<OrderItemEntity> items;

  const OrderPaymentOptionScreen({
    super.key,
    required this.totalAmount,
    this.debtorId,
    this.debtorName,
    required this.customerName,
    required this.customerPhone,
    this.locationId,
    this.locationName,
    required this.items,
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
        title: Text(l10n.translate('order_create.payment_method_title')),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.black,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const AppSyncStatusText(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.translate('order_create.total'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                CurrencyFormatter.formatVND(totalAmount),
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              _buildOptionCard(
                context: context,
                icon: Icons.account_balance_wallet_outlined,
                title: l10n.translate('order_create.debt'),
                color: AppColors.warning,
                onTap: () {
                  if ((debtorId ?? 0) <= 0) {
                    AppSnackBar.show(
                      context,
                      message: l10n.translate(
                        'order_create.debt_requires_profile',
                      ),
                      type: AppSnackBarType.warning,
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDebtScreen(
                        totalAmount: totalAmount,
                        debtorId: debtorId,
                        debtorName: debtorName,
                        customerName: customerName,
                        customerPhone: customerPhone,
                        locationId: locationId,
                        locationName: locationName,
                        items: items,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _buildOptionCard(
                context: context,
                icon: Icons.payments_outlined,
                title: l10n.translate('order_create.pay_now'),
                color: AppColors.success,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OrderPayNowScreen(
                            totalAmount: totalAmount,
                            items: items,
                            locationId: locationId?.toString(),
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
