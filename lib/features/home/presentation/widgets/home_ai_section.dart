import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/network/api_error_message_parser.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/cache/swr_builder.dart';
import '../../../../../shared/dialogs/app_snackbar.dart';
import '../../../../../shared/utils/date_formatter.dart';
import '../../../../../shared/utils/formatters.dart';
import '../../../order/presentation/pages/order_detail_screen.dart';
import '../../data/home_dashboard_api_service.dart';
import '../../data/models/home_ai_dto.dart';

enum _InsightTypeFilter { topSeller, growthTrend, promoteCandidate }

class HomeAiSection extends StatefulWidget {
  final int businessLocationId;
  final String? businessLocationRawId;

  const HomeAiSection({
    super.key,
    required this.businessLocationId,
    this.businessLocationRawId,
  });

  @override
  State<HomeAiSection> createState() => _HomeAiSectionState();
}

class _HomeAiSectionState extends State<HomeAiSection> {
  bool _isForecastExpanded = false;
  bool _isReorderExpanded = false;
  bool _isInsightsExpanded = false;
  bool _isAnomaliesExpanded = false;
  _InsightTypeFilter _insightTypeFilter = _InsightTypeFilter.topSeller;
  final Set<String> _acknowledgingAnomalyIds = <String>{};
  final Set<String> _locallyAcknowledgedAnomalyIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SwrBuilder<HomeAiBundleDto>(
      key: ValueKey('home_ai_bundle_${widget.businessLocationId}'),
      cacheKey: _aiCacheKey(widget.businessLocationId),
      fetcher: ({cancelToken}) {
        final service = context.read<HomeDashboardApiService>();
        return service.getAiBundle(locationId: widget.businessLocationId);
      },
      fromJson: HomeAiBundleDto.fromJson,
      toJson: (data) => data.toJson(),
      builder: (context, data, isFetching, error) {
        if (data == null && error != null) {
          return const SizedBox.shrink();
        }

        final bundle = data;
        if ((bundle == null || !bundle.hasAnyData) && !isFetching) {
          return const SizedBox.shrink();
        }

        final forecasts = bundle?.forecasts ?? const <HomeAiForecastItemDto>[];
        final visibleForecasts = forecasts
            .where((item) => item.predictedRevenue > 0)
            .toList();
        final reorders = bundle?.reorders ?? const <HomeAiReorderItemDto>[];
        final insights = bundle?.insights ?? const <HomeAiInsightItemDto>[];
        final selectedInsightTypeCode = _insightTypeCode(_insightTypeFilter);
        final selectedInsights = insights
            .where(
              (item) =>
                  item.insightType.trim().toUpperCase() ==
                  selectedInsightTypeCode,
            )
            .toList();

        final periodFilteredInsights = selectedInsightTypeCode == 'TOP_SELLER'
            ? () {
                final hasThirtyDayTopSeller = selectedInsights.any(
                  (item) => item.periodDays == 30,
                );
                return selectedInsights
                    .where(
                      (item) => hasThirtyDayTopSeller
                          ? item.periodDays == 30
                          : item.periodDays == 7,
                    )
                    .toList();
              }()
            : selectedInsights;

        periodFilteredInsights.sort((a, b) => a.rank.compareTo(b.rank));

        final seenInsightProductIds = <String>{};
        final visibleInsights = periodFilteredInsights.where((item) {
          final key = item.productId.trim();
          if (key.isEmpty ||
              item.productName == null ||
              item.productName!.trim().isEmpty ||
              seenInsightProductIds.contains(key)) {
            return false;
          }
          seenInsightProductIds.add(key);
          return true;
        }).toList();

        final insightAccentColor = _insightAccentColor(_insightTypeFilter);
        final insightBackgroundColor = insightAccentColor.withValues(
          alpha: 0.08,
        );
        final anomalies = bundle?.anomalies ?? const <HomeAiAnomalyItemDto>[];
        final visibleAnomalies = anomalies
            .where(
              (item) =>
                  !item.isAcknowledged &&
                  !_locallyAcknowledgedAnomalyIds.contains(item.id),
            )
            .toList();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withValues(alpha: 0.06),
                AppColors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.translate('home.ai_section_title'),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (isFetching)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (visibleForecasts.isNotEmpty)
                _buildAiDropdown(
                  title: l10n.translate('home.ai_forecast_title'),
                  expanded: _isForecastExpanded,
                  accentColor: AppColors.info,
                  backgroundColor: AppColors.info.withValues(alpha: 0.08),
                  onToggle: () {
                    setState(() {
                      _isForecastExpanded = !_isForecastExpanded;
                    });
                  },
                  child: Column(
                    children: visibleForecasts
                        .take(3)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.forecastDate,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatVND(
                                    item.predictedRevenue,
                                  ),
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (insights.isNotEmpty)
                _buildAiDropdown(
                  title: _insightSectionTitle(_insightTypeFilter),
                  expanded: _isInsightsExpanded,
                  accentColor: insightAccentColor,
                  backgroundColor: insightBackgroundColor,
                  onToggle: () {
                    setState(() {
                      _isInsightsExpanded = !_isInsightsExpanded;
                    });
                  },
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.translate('home.ai_insight_filter_title'),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  _insightFilterLabel(
                                    _InsightTypeFilter.topSeller,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              selected:
                                  _insightTypeFilter ==
                                  _InsightTypeFilter.topSeller,
                              selectedColor: AppColors.success.withValues(
                                alpha: 0.2,
                              ),
                              side: BorderSide(
                                color: AppColors.success.withValues(alpha: 0.4),
                              ),
                              labelStyle: AppTextStyles.labelSmall.copyWith(
                                color:
                                    _insightTypeFilter ==
                                        _InsightTypeFilter.topSeller
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _insightTypeFilter =
                                      _InsightTypeFilter.topSeller;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: ChoiceChip(
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  _insightFilterLabel(
                                    _InsightTypeFilter.growthTrend,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              selected:
                                  _insightTypeFilter ==
                                  _InsightTypeFilter.growthTrend,
                              selectedColor: AppColors.info.withValues(
                                alpha: 0.2,
                              ),
                              side: BorderSide(
                                color: AppColors.info.withValues(alpha: 0.4),
                              ),
                              labelStyle: AppTextStyles.labelSmall.copyWith(
                                color:
                                    _insightTypeFilter ==
                                        _InsightTypeFilter.growthTrend
                                    ? AppColors.info
                                    : AppColors.textSecondary,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _insightTypeFilter =
                                      _InsightTypeFilter.growthTrend;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: ChoiceChip(
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  _insightFilterLabel(
                                    _InsightTypeFilter.promoteCandidate,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              selected:
                                  _insightTypeFilter ==
                                  _InsightTypeFilter.promoteCandidate,
                              selectedColor: AppColors.warning.withValues(
                                alpha: 0.22,
                              ),
                              side: BorderSide(
                                color: AppColors.warning.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                              labelStyle: AppTextStyles.labelSmall.copyWith(
                                color:
                                    _insightTypeFilter ==
                                        _InsightTypeFilter.promoteCandidate
                                    ? AppColors.warning
                                    : AppColors.textSecondary,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _insightTypeFilter =
                                      _InsightTypeFilter.promoteCandidate;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (visibleInsights.isEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.translate('home.ai_insight_no_data'),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...visibleInsights
                            .take(5)
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '#${item.rank}',
                                      style: AppTextStyles.labelSmall,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        (item.productName != null &&
                                                item.productName!
                                                    .trim()
                                                    .isNotEmpty)
                                            ? item.productName!
                                            : item.productId,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              if (reorders.isNotEmpty)
                _buildAiDropdown(
                  title: l10n.translate('home.ai_reorder_title'),
                  expanded: _isReorderExpanded,
                  accentColor: AppColors.warning,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                  onToggle: () {
                    setState(() {
                      _isReorderExpanded = !_isReorderExpanded;
                    });
                  },
                  child: Column(
                    children: reorders
                        .take(5)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productId,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                                Text(
                                  '${item.urgency} • +${item.suggestedQuantity.toStringAsFixed(0)}',
                                  style: AppTextStyles.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (visibleAnomalies.isNotEmpty)
                _buildAiDropdown(
                  title: l10n.translate('home.ai_anomalies_title'),
                  expanded: _isAnomaliesExpanded,
                  accentColor: AppColors.danger,
                  backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                  onToggle: () {
                    setState(() {
                      _isAnomaliesExpanded = !_isAnomaliesExpanded;
                    });
                  },
                  child: Column(
                    children: visibleAnomalies.take(5).map((item) {
                      final isNavigable = _isAnomalyNavigable(item);
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            onTap: isNavigable
                                ? () => _handleAnomalyTap(item)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.description,
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                      ),
                                      if (isNavigable)
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      Text(
                                        item.severity,
                                        style: AppTextStyles.labelSmall
                                            .copyWith(color: AppColors.warning),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          DateFormatter.formatDate(
                                            DateTime.tryParse(
                                              item.referenceDate,
                                            ),
                                          ),
                                          style: AppTextStyles.bodySmall,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed:
                                            _acknowledgingAnomalyIds.contains(
                                              item.id,
                                            )
                                            ? null
                                            : () => _acknowledgeAnomaly(
                                                locationId:
                                                    widget.businessLocationId,
                                                anomalyId: item.id,
                                              ),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: 4,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          l10n.translate('home.ai_mark_read'),
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: AppColors.primary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _aiCacheKey(int businessLocationId) {
    return 'home_ai_bundle_$businessLocationId';
  }

  String _insightTypeCode(_InsightTypeFilter filter) {
    switch (filter) {
      case _InsightTypeFilter.topSeller:
        return 'TOP_SELLER';
      case _InsightTypeFilter.growthTrend:
        return 'GROWTH_TREND';
      case _InsightTypeFilter.promoteCandidate:
        return 'PROMOTE_CANDIDATE';
    }
  }

  Color _insightAccentColor(_InsightTypeFilter filter) {
    switch (filter) {
      case _InsightTypeFilter.topSeller:
        return AppColors.success;
      case _InsightTypeFilter.growthTrend:
        return AppColors.info;
      case _InsightTypeFilter.promoteCandidate:
        return AppColors.warning;
    }
  }

  String _insightSectionTitle(_InsightTypeFilter filter) {
    final l10n = AppLocalizations.of(context);
    switch (filter) {
      case _InsightTypeFilter.topSeller:
        return l10n.translate('home.ai_insight_top_seller');
      case _InsightTypeFilter.growthTrend:
        return l10n.translate('home.ai_insight_growth_trend');
      case _InsightTypeFilter.promoteCandidate:
        return l10n.translate('home.ai_insight_promote_candidate');
    }
  }

  String _insightFilterLabel(_InsightTypeFilter filter) {
    final l10n = AppLocalizations.of(context);
    switch (filter) {
      case _InsightTypeFilter.topSeller:
        return l10n.translate('home.ai_insight_filter_top_seller');
      case _InsightTypeFilter.growthTrend:
        return l10n.translate('home.ai_insight_filter_growth_trend');
      case _InsightTypeFilter.promoteCandidate:
        return l10n.translate('home.ai_insight_filter_promote_candidate');
    }
  }

  bool _isAnomalyNavigable(HomeAiAnomalyItemDto anomaly) {
    final type = _normalizeRecordType(anomaly.recordType);
    switch (type) {
      case 'order':
      case 'import':
        return _parsePositiveInt(anomaly.referenceId) != null;
      case 'revenue':
      case 'cost':
        return true;
      default:
        return false;
    }
  }

  String _normalizeRecordType(String? rawType) {
    return (rawType ?? '').trim().toLowerCase();
  }

  int? _parsePositiveInt(String? raw) {
    if (raw == null) {
      return null;
    }
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  Future<void> _handleAnomalyTap(HomeAiAnomalyItemDto anomaly) async {
    final recordType = _normalizeRecordType(anomaly.recordType);
    final referenceId = _parsePositiveInt(anomaly.referenceId);

    switch (recordType) {
      case 'order':
        if (referenceId == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: referenceId.toString()),
          ),
        );
        return;
      case 'import':
        if (referenceId == null) return;
        await AppRouter.navigateTo(
          AppRoutes.stockImport,
          arguments: {
            'locationId':
                widget.businessLocationRawId ??
                widget.businessLocationId.toString(),
            'importId': referenceId,
          },
        );
        return;
      case 'revenue':
        await AppRouter.navigateTo(
          AppRoutes.accounting,
          arguments: {'initialTabIndex': 2},
        );
        return;
      case 'cost':
        await AppRouter.navigateTo(
          AppRoutes.accounting,
          arguments: {'initialTabIndex': 3},
        );
        return;
      default:
        return;
    }
  }

  Future<void> _acknowledgeAnomaly({
    required int locationId,
    required String anomalyId,
  }) async {
    if (_acknowledgingAnomalyIds.contains(anomalyId)) {
      return;
    }

    setState(() {
      _acknowledgingAnomalyIds.add(anomalyId);
    });

    try {
      final service = context.read<HomeDashboardApiService>();
      await service.acknowledgeAnomaly(
        anomalyId: anomalyId,
        locationId: locationId,
      );
      if (!mounted) return;
      setState(() {
        _locallyAcknowledgedAnomalyIds.add(anomalyId);
      });
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: ApiErrorMessageParser.parse(error),
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _acknowledgingAnomalyIds.remove(anomalyId);
        });
      }
    }
  }

  Widget _buildAiDropdown({
    required String title,
    required bool expanded,
    required Color accentColor,
    required Color backgroundColor,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}
