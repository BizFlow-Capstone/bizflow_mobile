import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';

class PremiumPaymentPage extends StatefulWidget {
  final String planName;
  final int price;
  final int vatPercent;
  final int total;
  final String period;

  const PremiumPaymentPage({
    super.key,
    required this.planName,
    required this.price,
    required this.vatPercent,
    required this.total,
    required this.period,
  });

  @override
  State<PremiumPaymentPage> createState() => _PremiumPaymentPageState();
}

enum _PaymentMethod { vietQr, card }

class _PremiumPaymentPageState extends State<PremiumPaymentPage> {
  _PaymentMethod _method = _PaymentMethod.vietQr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: AppColors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => AppRouter.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('payment.appbar_title'),
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              l10n.translate('payment.appbar_subtitle'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _SectionCard(
                title: l10n.translate('payment.details_title'),
                child: Column(
                  children: [
                    _RowLine(
                      label:
                          '${widget.planName} (1 ${l10n.translate('payment.month')})',
                      value: _formatCurrency(widget.price),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _RowLine(
                      label:
                          '${l10n.translate('payment.vat')} (${widget.vatPercent}%)',
                      value: _formatCurrency(_vatAmount),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Divider(color: AppColors.divider, height: 1),
                    SizedBox(height: AppSpacing.md),
                    _RowLine(
                      label: l10n.translate('payment.total'),
                      value: _formatCurrency(widget.total),
                      valueStyle: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: l10n.translate('payment.methods_title'),
                child: Column(
                  children: [
                    _MethodTile(
                      selected: _method == _PaymentMethod.vietQr,
                      title: l10n.translate('payment.method_qr_title'),
                      subtitle: l10n.translate('payment.method_qr_subtitle'),
                      onTap: () =>
                          setState(() => _method = _PaymentMethod.vietQr),
                    ),
                    SizedBox(height: AppSpacing.md),
                    _MethodTile(
                      selected: _method == _PaymentMethod.card,
                      title: l10n.translate('payment.method_card_title'),
                      subtitle: l10n.translate('payment.method_card_subtitle'),
                      onTap: () =>
                          setState(() => _method = _PaymentMethod.card),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              _QrCard(l10n: l10n, amount: widget.total),
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: l10n.translate('common.back'),
                      onPressed: () => AppRouter.pop(),
                      type: AppButtonType.outlined,
                      size: AppButtonSize.large,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: l10n.translate('payment.confirm'),
                      onPressed: () {},
                      type: AppButtonType.secondary,
                      size: AppButtonSize.large,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              _SecurityNote(l10n: l10n),
              const SafeArea(
                top: false,
                child: SizedBox(height: AppSpacing.md),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int get _vatAmount => widget.total - widget.price;

  String _formatCurrency(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buffer.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return '${buffer.toString()}đ';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _RowLine extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _RowLine({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style:
              valueStyle ??
              AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.info.withOpacity(0.08) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.info : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.info : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final AppLocalizations l10n;
  final int amount;

  const _QrCard({required this.l10n, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_2,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            l10n.translate('payment.qr_hint'),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          _InfoLine(
            label: l10n.translate('payment.amount'),
            value: _formatCurrency(amount),
          ),
          SizedBox(height: AppSpacing.xs),
          _InfoLine(
            label: l10n.translate('payment.content'),
            value: l10n.translate('payment.content_value'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buffer.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return '${buffer.toString()}đ';
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label:',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SecurityNote extends StatelessWidget {
  final AppLocalizations l10n;

  const _SecurityNote({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: AppColors.info, size: 18),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.translate('payment.security_note'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
