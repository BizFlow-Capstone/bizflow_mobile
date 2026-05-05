import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class AccountingPeriodTaxGuidePage extends StatelessWidget {
  const AccountingPeriodTaxGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('accounting.period_guide_title')),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuideHeader(
                title: l10n.translate('accounting.period_guide_title'),
                subtitle: l10n.translate('accounting.period_guide_subtitle'),
              ),
              const SizedBox(height: AppSpacing.md),
              _GuideCard(
                title: l10n.translate('accounting.period_guide_intro'),
                child: Text(
                  l10n.translate('accounting.period_guide_intro'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _GuideSection(
                title: l10n.translate('accounting.period_guide_books_title'),
                child: Text(
                  l10n.translate('accounting.period_guide_books_body'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.55,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _GuideSection(
                title: l10n.translate('accounting.period_guide_vat_title'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('accounting.period_guide_vat_body'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.55,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FormulaBlock(
                      title: l10n.translate('accounting.period_guide_vat_title'),
                      color: Colors.blue,
                      formula: l10n.translate('accounting.period_guide_vat_formula'),
                      body: '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _GuideSection(
                title: l10n.translate('accounting.period_guide_tncn_title'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormulaBlock(
                      title: l10n.translate('accounting.period_guide_method_1_label'),
                      color: Colors.blue,
                      formula: l10n.translate('accounting.period_guide_tncn_method_1_formula'),
                      body: l10n.translate('accounting.period_guide_tncn_method_1_body'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FormulaBlock(
                      title: l10n.translate('accounting.period_guide_method_2_label'),
                      color: Colors.deepOrange,
                      formula: l10n.translate('accounting.period_guide_tncn_method_2_formula'),
                      body: l10n.translate('accounting.period_guide_tncn_method_2_body'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _GuideSection(
                title: l10n.translate('accounting.period_guide_rate_table_title'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('accounting.period_guide_rate_table_subtitle'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.28)),
                      ),
                      child: Text(
                        l10n.translate('accounting.period_guide_rate_table_note'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _RateTable(
                      sttLabel: '',
                      industryLabel: l10n.translate('accounting.period_guide_col_industry'),
                      vatLabel: l10n.translate('accounting.period_guide_col_vat'),
                      tncnLabel: l10n.translate('accounting.period_guide_col_tncn'),
                      rows: [
                        _RateTableRowData(
                          stt: '',
                          title: l10n.translate('accounting.period_guide_row_1_title'),
                          vat: l10n.translate('accounting.period_guide_row_1_vat'),
                          tncn: l10n.translate('accounting.period_guide_row_1_tncn'),
                          details: const [],
                        ),
                        _RateTableRowData(
                          stt: '',
                          title: l10n.translate('accounting.period_guide_row_1b_title'),
                          vat: l10n.translate('accounting.period_guide_row_1b_vat'),
                          tncn: l10n.translate('accounting.period_guide_row_1b_tncn'),
                          details: const [],
                        ),
                        _RateTableRowData(
                          stt: '',
                          title: l10n.translate('accounting.period_guide_row_2_title'),
                          vat: l10n.translate('accounting.period_guide_row_2_vat'),
                          tncn: l10n.translate('accounting.period_guide_row_2_tncn'),
                          details: const [],
                        ),
                        _RateTableRowData(
                          stt: '',
                          title: l10n.translate('accounting.period_guide_row_2b_title'),
                          vat: l10n.translate('accounting.period_guide_row_2b_vat'),
                          tncn: l10n.translate('accounting.period_guide_row_2b_tncn'),
                          details: const [],
                        ),
                        _RateTableRowData(
                          stt: '',
                          title: l10n.translate('accounting.period_guide_row_2c_title'),
                          vat: l10n.translate('accounting.period_guide_row_2c_vat'),
                          tncn: l10n.translate('accounting.period_guide_row_2c_tncn'),
                          details: const [],
                        ),
                        _RateTableRowData(
                          stt: '',
                          title: l10n.translate('accounting.period_guide_row_2d_title'),
                          vat: l10n.translate('accounting.period_guide_row_2d_vat'),
                          tncn: l10n.translate('accounting.period_guide_row_2d_tncn'),
                          details: const [],
                        ),
                        _RateTableRowData(
                          stt: '',
                          title: l10n.translate('accounting.period_guide_row_2e_title'),
                          vat: l10n.translate('accounting.period_guide_row_2e_vat'),
                          tncn: l10n.translate('accounting.period_guide_row_2e_tncn'),
                          details: const [],
                        ),
                        _RateTableRowData(
                          stt: '',
                          title: l10n.translate('accounting.period_guide_row_3_title'),
                          vat: l10n.translate('accounting.period_guide_row_3_vat'),
                          tncn: l10n.translate('accounting.period_guide_row_3_tncn'),
                          details: const [],
                        ),
                        _RateTableRowData(
                          stt: '',
                          title: l10n.translate('accounting.period_guide_row_3b_title'),
                          vat: l10n.translate('accounting.period_guide_row_3b_vat'),
                          tncn: l10n.translate('accounting.period_guide_row_3b_tncn'),
                          details: const [],
                        ),
                        _RateTableRowData(
                          stt: '',
                          title: l10n.translate('accounting.period_guide_row_4_title'),
                          vat: l10n.translate('accounting.period_guide_row_4_vat'),
                          tncn: l10n.translate('accounting.period_guide_row_4_tncn'),
                          details: const [],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _GuideSection(
                title: l10n.translate('accounting.period_guide_legal_title'),
                child: _LabeledParagraphList(
                  rawText: l10n.translate('accounting.period_guide_legal_body'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

}

class _FormulaBlock extends StatelessWidget {
  final String title;
  final String formula;
  final String body;
  final Color color;

  const _FormulaBlock({
    required this.title,
    required this.formula,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.55,
                fontSize: 15,
              ),
              children: [
                TextSpan(
                  text: formula,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (body.isNotEmpty) ...[
                  const TextSpan(text: '\n'),
                  TextSpan(text: body),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledParagraphList extends StatelessWidget {
  final String rawText;

  const _LabeledParagraphList({required this.rawText});

  @override
  Widget build(BuildContext context) {
    final lines = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LabeledParagraph(line: line),
            ),
          )
          .toList(),
    );
  }
}

class _LabeledParagraph extends StatelessWidget {
  final String line;

  const _LabeledParagraph({required this.line});

  @override
  Widget build(BuildContext context) {
    final splitIndex = line.indexOf(':');

    if (splitIndex <= 0) {
      return Text(
        line,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          height: 1.6,
          fontSize: 15,
        ),
      );
    }

    final label = line.substring(0, splitIndex + 1);
    final content = line.substring(splitIndex + 1).trimLeft();

    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          height: 1.6,
          fontSize: 15,
        ),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(text: content),
        ],
      ),
    );
  }
}

List<String> _splitBulletText(String raw) {
  return raw
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) => line.replaceFirst(RegExp(r'^-\s*'), ''))
      .toList();
}

class _RateTableRowData {
  final String stt;
  final String title;
  final String vat;
  final String tncn;
  final List<String> details;

  const _RateTableRowData({
    required this.stt,
    required this.title,
    required this.vat,
    required this.tncn,
    required this.details,
  });
}

class _RateTable extends StatelessWidget {
  final String sttLabel;
  final String industryLabel;
  final String vatLabel;
  final String tncnLabel;
  final List<_RateTableRowData> rows;

  const _RateTable({
    required this.sttLabel,
    required this.industryLabel,
    required this.vatLabel,
    required this.tncnLabel,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTextStyles.bodySmall.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      fontSize: 13,
    );

    final cellStyle = AppTextStyles.bodySmall.copyWith(
      color: AppColors.textPrimary,
      height: 1.45,
      fontSize: 13,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 920),
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: AppColors.divider),
              verticalInside: BorderSide(color: AppColors.divider),
            ),
            columnWidths: const {
              0: FixedColumnWidth(64),
              1: FixedColumnWidth(620),
              2: FixedColumnWidth(118),
              3: FixedColumnWidth(118),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                ),
                children: [
                  _TableCell(
                    child: Text(sttLabel, style: headerStyle, textAlign: TextAlign.center),
                  ),
                  _TableCell(
                    child: Text(industryLabel, style: headerStyle),
                  ),
                  _TableCell(
                    child: Text(vatLabel, style: headerStyle, textAlign: TextAlign.center),
                  ),
                  _TableCell(
                    child: Text(tncnLabel, style: headerStyle, textAlign: TextAlign.center),
                  ),
                ],
              ),
              ...rows.map(
                (row) => TableRow(
                  children: [
                    _TableCell(
                      child: Text(row.stt, style: cellStyle, textAlign: TextAlign.center),
                    ),
                    _TableCell(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...row.details.map(
                            (detail) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• $detail', style: cellStyle),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TableCell(
                      child: Text(row.vat, style: cellStyle, textAlign: TextAlign.center),
                    ),
                    _TableCell(
                      child: Text(row.tncn, style: cellStyle, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final Widget child;

  const _TableCell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: child,
    );
  }
}

class _GuideHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _GuideHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _GuideSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return _GuideCard(title: title, child: child);
  }
}

class _GuideCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _GuideCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
