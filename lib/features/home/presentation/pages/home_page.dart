import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/cache/swr_builder.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/services/permission_service.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../employee/presentation/bloc/employee_bloc.dart';
import '../../../employee/presentation/bloc/employee_event.dart';
import '../../../employee/presentation/bloc/employee_state.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_event.dart';
import '../../../location/presentation/bloc/location_state.dart';
import 'dart:async';
import '../../data/home_dashboard_api_service.dart';
import '../../../subscription/data/subscription_api_service.dart';
import '../../../subscription/data/subscription_repository.dart';
import '../../../subscription/data/models/subscription_models.dart';
import '../../../../shared/cache/cache_manager.dart';
import '../../data/models/dashboard_summary_dto.dart';
import '../../data/models/home_ai_dto.dart';
import '../widgets/quick_actions.dart';
import '../widgets/premium_banner.dart';
import '../widgets/management_cards.dart';
import '../widgets/stats_cards.dart';

enum _SummaryPeriod { today, week, month }

enum _InsightTypeFilter { topSeller, growthTrend, promoteCandidate }

/// Home Page - Trang chủ của ứng dụng
/// Hiển thị:
/// - Lời chào & thông tin người dùng
/// - Thống kê: Đơn hàng & doanh thu hôm nay
/// - Quick actions: Tạo đơn, Đơn hàng, Công nợ, Báo cáo
/// - Premium upgrade banner
/// - Quản lý: Địa điểm & Nhân viên
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  String? _lastEmployeeLoadedBusinessId;
  _SummaryPeriod _selectedPeriod = _SummaryPeriod.today;
  int _summaryRefreshTick = 0;
  bool _isForecastExpanded = false;
  bool _isReorderExpanded = false;
  bool _isInsightsExpanded = false;
  bool _isAnomaliesExpanded = false;
  _InsightTypeFilter _insightTypeFilter = _InsightTypeFilter.topSeller;
  final Set<String> _acknowledgingAnomalyIds = <String>{};
  final Set<String> _locallyAcknowledgedAnomalyIds = <String>{};
  PageRoute<dynamic>? _subscribedRoute;

  @override
  void initState() {
    super.initState();

    // Đảm bảo danh sách địa điểm được tải khi ở HomePage để hiển thị trên Sidebar
    final locationBloc = context.read<LocationBloc>();
    if (locationBloc.state is LocationInitial) {
      locationBloc.add(const LoadLocationsRequested());
    }

    // Prefetch subscription data so CurrentSubscriptionPage renders instantly
    // (fire-and-forget — does not block Home rendering).
    unawaited(_prefetchSubscription());
  }

  Future<void> _prefetchSubscription() async {
    if (!mounted) return;
    try {
      final apiService = context.read<SubscriptionApiService>();
      final repo = context.read<SubscriptionRepository>();
      final cache = CacheManager();
      // Always update in-memory snapshot; skip network only if cache is warm.
      final existing = await cache.get('current_subscription');
      if (existing != null) {
        // Seed in-memory value from cache so CurrentSubscriptionPage reads it sync.
        try {
          repo.updateCurrentSubscription(
            CurrentSubscriptionDto.fromJson(Map<String, dynamic>.from(existing)),
          );
        } catch (_) {}
        return;
      }
      final fresh = await apiService.getCurrentSubscription();
      if (fresh == null) return;
      repo.updateCurrentSubscription(fresh);
      final json = fresh.toJson();
      await cache.set('current_subscription', json);
      await cache.set('current_subscription_for_plans', json);
    } catch (_) {
      // Best-effort: silently ignore if prefetch fails.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _subscribedRoute) {
      if (_subscribedRoute != null) {
        AppRouter.routeObserver.unsubscribe(this);
      }
      _subscribedRoute = route;
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    if (_subscribedRoute != null) {
      AppRouter.routeObserver.unsubscribe(this);
      _subscribedRoute = null;
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    setState(() {
      _summaryRefreshTick++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final businessContext = context.watch<BusinessContext>();
    final businessLocationId = _asIntId(businessContext.currentBusinessId);
    final isOwner = businessContext.isOwner;

    if (isOwner && businessContext.currentBusinessId != null) {
      final businessId = businessContext.currentBusinessId!;
      if (_lastEmployeeLoadedBusinessId != businessId) {
        _lastEmployeeLoadedBusinessId = businessId;
        context.read<EmployeeBloc>().add(
          LoadEmployeesRequested(businessId: businessId),
        );
      }
    }

    return BlocListener<LocationBloc, LocationState>(
      listener: (context, state) {
        if (state is LocationsLoaded) {
          final activeLocations = state.locations
              .where((location) => location.isActive)
              .toList();

          if (activeLocations.isEmpty) {
            // If the user has 0 locations, send them to the no locations screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppRouter.navigateAndClearStack(AppRoutes.noLocation);
            });
          } else {
            // Keep BusinessContext aligned with the latest location list.
            // This also fixes account-switch flows where previous location id
            // no longer exists in the current account.
            final businessContext = Provider.of<BusinessContext>(
              context,
              listen: false,
            );
            final selectedId = businessContext.currentBusinessId;
            final isSelectedValid =
                selectedId != null &&
                activeLocations.any((location) => location.id == selectedId);
            if (!isSelectedValid) {
              final firstLocation = activeLocations.first;
              businessContext.switchBusinessLocation(
                firstLocation.id,
                firstLocation.name,
                isOwner: firstLocation.isOwner,
                ownerProfileId: firstLocation.ownerProfileId,
              );
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business Context Section
                Consumer<BusinessContext>(
                  builder: (context, businessContext, _) {
                    final isContextReady =
                        businessContext.currentBusinessId != null;
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
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
                          Text(
                            l10n.translate('home.managing'),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.storefront,
                                color: AppColors.secondary,
                                size: 24,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  isContextReady
                                      ? (businessContext.currentBusinessName ??
                                            l10n.translate('common.loading'))
                                      : l10n.translate('common.loading'),
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                _buildPeriodSelector(),
                SizedBox(height: AppSpacing.sm),
                SwrBuilder<DashboardSummaryDto>(
                  key: ValueKey('home_summary_refresh_$_summaryRefreshTick'),
                  cacheKey: _summaryCacheKey(
                    businessLocationId,
                    _selectedPeriod,
                  ),
                  fetcher: ({cancelToken}) {
                    final service = context.read<HomeDashboardApiService>();
                    final range = _rangeFromTodayBack(_selectedPeriod);
                    return service.getDashboardSummary(
                      period: 'custom',
                      businessLocationId: businessLocationId,
                      fromDate: range.from,
                      toDate: range.to,
                    );
                  },
                  fromJson: DashboardSummaryDto.fromJson,
                  toJson: (data) => data.toJson(),
                  builder: (context, data, isFetching, error) {
                    if (data == null && error != null) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error, width: 1),
                        ),
                        child: Text(
                          l10n.translate('common.error_occurred'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      );
                    }

                    final summary = data;
                    return StatsCards(
                      ordersTitle: _ordersTitle(l10n),
                      revenueTitle: _revenueTitle(l10n),
                      costTitle: _costTitle(l10n),
                      debtTitle: _debtTitle(l10n),
                      todaysOrders: summary?.totalCompletedOrders ?? 0,
                      todaysRevenue: CurrencyFormatter.formatVND(
                        summary?.totalRevenue ?? 0,
                      ),
                      todaysCost: CurrencyFormatter.formatVND(
                        summary?.totalCost ?? 0,
                      ),
                      todaysDebt: CurrencyFormatter.formatVND(
                        summary?.totalOutstandingDebt ?? 0,
                      ),
                      isRefreshing: isFetching,
                    );
                  },
                ),
                SizedBox(height: AppSpacing.md),

                if (businessLocationId != null)
                  SwrBuilder<HomeAiBundleDto>(
                    key: ValueKey('home_ai_bundle_$businessLocationId'),
                    cacheKey: _aiCacheKey(businessLocationId),
                    fetcher: ({cancelToken}) {
                      final service = context.read<HomeDashboardApiService>();
                      return service.getAiBundle(
                        locationId: businessLocationId,
                      );
                    },
                    fromJson: HomeAiBundleDto.fromJson,
                    toJson: (data) => data.toJson(),
                    builder: (context, data, isFetching, error) {
                      if (data == null && error != null) {
                        return const SizedBox.shrink();
                      }

                      final bundle = data;
                      if ((bundle == null || !bundle.hasAnyData) &&
                          !isFetching) {
                        return const SizedBox.shrink();
                      }

                      final forecasts =
                          bundle?.forecasts ?? const <HomeAiForecastItemDto>[];
                      final visibleForecasts = forecasts
                          .where((item) => item.predictedRevenue > 0)
                          .toList();
                      final reorders =
                          bundle?.reorders ?? const <HomeAiReorderItemDto>[];
                      final insights =
                          bundle?.insights ?? const <HomeAiInsightItemDto>[];
                      final selectedInsightTypeCode = _insightTypeCode(
                        _insightTypeFilter,
                      );
                      final selectedInsights = insights
                          .where(
                            (item) =>
                                item.insightType.trim().toUpperCase() ==
                                selectedInsightTypeCode,
                          )
                          .toList();

                      final periodFilteredInsights =
                          selectedInsightTypeCode == 'TOP_SELLER'
                          ? () {
                              final hasThirtyDayTopSeller = selectedInsights
                                  .any((item) => item.periodDays == 30);
                              return selectedInsights
                                  .where(
                                    (item) => hasThirtyDayTopSeller
                                        ? item.periodDays == 30
                                        : item.periodDays == 7,
                                  )
                                  .toList();
                            }()
                          : selectedInsights;

                      periodFilteredInsights.sort(
                        (a, b) => a.rank.compareTo(b.rank),
                      );

                      final seenInsightProductIds = <String>{};
                      final visibleInsights = periodFilteredInsights.where((
                        item,
                      ) {
                        final key = item.productId.trim();
                        if (key.isEmpty ||
                            seenInsightProductIds.contains(key)) {
                          return false;
                        }
                        seenInsightProductIds.add(key);
                        return true;
                      }).toList();
                      final insightAccentColor = _insightAccentColor(
                        _insightTypeFilter,
                      );
                      final insightBackgroundColor = insightAccentColor
                          .withValues(alpha: 0.08);
                      final anomalies =
                          bundle?.anomalies ?? const <HomeAiAnomalyItemDto>[];
                      final visibleAnomalies = anomalies
                          .where(
                            (item) =>
                                !item.isAcknowledged &&
                                !_locallyAcknowledgedAnomalyIds.contains(
                                  item.id,
                                ),
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
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (visibleForecasts.isNotEmpty)
                              _buildAiDropdown(
                                title: l10n.translate('home.ai_forecast_title'),
                                expanded: _isForecastExpanded,
                                accentColor: AppColors.info,
                                backgroundColor: AppColors.info.withValues(
                                  alpha: 0.08,
                                ),
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
                                                  style:
                                                      AppTextStyles.bodySmall,
                                                ),
                                              ),
                                              Text(
                                                CurrencyFormatter.formatVND(
                                                  item.predictedRevenue,
                                                ),
                                                style: AppTextStyles.labelMedium
                                                    .copyWith(
                                                      color:
                                                          AppColors.textPrimary,
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
                                        'Bộ lọc insight',
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
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
                                            selectedColor: AppColors.success
                                                .withValues(alpha: 0.2),
                                            side: BorderSide(
                                              color: AppColors.success
                                                  .withValues(alpha: 0.4),
                                            ),
                                            labelStyle: AppTextStyles.labelSmall
                                                .copyWith(
                                                  color:
                                                      _insightTypeFilter ==
                                                          _InsightTypeFilter
                                                              .topSeller
                                                      ? AppColors.success
                                                      : AppColors.textSecondary,
                                                ),
                                            onSelected: (_) {
                                              setState(() {
                                                _insightTypeFilter =
                                                    _InsightTypeFilter
                                                        .topSeller;
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
                                                  _InsightTypeFilter
                                                      .growthTrend,
                                                ),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            selected:
                                                _insightTypeFilter ==
                                                _InsightTypeFilter.growthTrend,
                                            selectedColor: AppColors.info
                                                .withValues(alpha: 0.2),
                                            side: BorderSide(
                                              color: AppColors.info.withValues(
                                                alpha: 0.4,
                                              ),
                                            ),
                                            labelStyle: AppTextStyles.labelSmall
                                                .copyWith(
                                                  color:
                                                      _insightTypeFilter ==
                                                          _InsightTypeFilter
                                                              .growthTrend
                                                      ? AppColors.info
                                                      : AppColors.textSecondary,
                                                ),
                                            onSelected: (_) {
                                              setState(() {
                                                _insightTypeFilter =
                                                    _InsightTypeFilter
                                                        .growthTrend;
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
                                                  _InsightTypeFilter
                                                      .promoteCandidate,
                                                ),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            selected:
                                                _insightTypeFilter ==
                                                _InsightTypeFilter
                                                    .promoteCandidate,
                                            selectedColor: AppColors.warning
                                                .withValues(alpha: 0.22),
                                            side: BorderSide(
                                              color: AppColors.warning
                                                  .withValues(alpha: 0.45),
                                            ),
                                            labelStyle: AppTextStyles.labelSmall
                                                .copyWith(
                                                  color:
                                                      _insightTypeFilter ==
                                                          _InsightTypeFilter
                                                              .promoteCandidate
                                                      ? AppColors.warning
                                                      : AppColors.textSecondary,
                                                ),
                                            onSelected: (_) {
                                              setState(() {
                                                _insightTypeFilter =
                                                    _InsightTypeFilter
                                                        .promoteCandidate;
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
                                          'Chưa có dữ liệu cho bộ lọc này.',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
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
                                                    style: AppTextStyles
                                                        .labelSmall,
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.sm,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      (item.productName !=
                                                                  null &&
                                                              item.productName!
                                                                  .trim()
                                                                  .isNotEmpty)
                                                          ? item.productName!
                                                          : item.productId,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: AppTextStyles
                                                          .bodyMedium,
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
                                backgroundColor: AppColors.warning.withValues(
                                  alpha: 0.1,
                                ),
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      AppTextStyles.bodyMedium,
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
                                title: l10n.translate(
                                  'home.ai_anomalies_title',
                                ),
                                expanded: _isAnomaliesExpanded,
                                accentColor: AppColors.danger,
                                backgroundColor: AppColors.danger.withValues(
                                  alpha: 0.08,
                                ),
                                onToggle: () {
                                  setState(() {
                                    _isAnomaliesExpanded =
                                        !_isAnomaliesExpanded;
                                  });
                                },
                                child: Column(
                                  children: visibleAnomalies
                                      .take(5)
                                      .map(
                                        (item) => Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(
                                            bottom: AppSpacing.sm,
                                          ),
                                          padding: const EdgeInsets.all(
                                            AppSpacing.sm,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusMd,
                                            ),
                                            border: Border.all(
                                              color: AppColors.divider,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.description,
                                                style: AppTextStyles.bodyMedium,
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.xs,
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    item.severity,
                                                    style: AppTextStyles
                                                        .labelSmall
                                                        .copyWith(
                                                          color:
                                                              AppColors.warning,
                                                        ),
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.sm,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      DateFormatter.formatDate(
                                                        DateTime.tryParse(
                                                          item.referenceDate,
                                                        ),
                                                      ),
                                                      style: AppTextStyles
                                                          .bodySmall,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        _acknowledgingAnomalyIds
                                                            .contains(item.id)
                                                        ? null
                                                        : () => _acknowledgeAnomaly(
                                                            locationId:
                                                                businessLocationId,
                                                            anomalyId: item.id,
                                                          ),
                                                    style: TextButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal:
                                                                AppSpacing.sm,
                                                            vertical: 4,
                                                          ),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                    child: Text(
                                                      l10n.translate(
                                                        'home.ai_mark_read',
                                                      ),
                                                      style: AppTextStyles
                                                          .labelSmall
                                                          .copyWith(
                                                            color: AppColors
                                                                .primary,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                // Quick Actions
                QuickActions(
                  onCreateOrder: () =>
                      AppRouter.navigateTo(AppRoutes.orderCreateSelection),
                  onOrders: () => AppRouter.navigateTo(AppRoutes.orderList),
                  onDebt: () => AppRouter.navigateTo(AppRoutes.debtList),
                  onReport: () => AppRouter.navigateTo(AppRoutes.accounting),
                  showReport: PermissionService.canViewReports(isOwner),
                ),
                SizedBox(height: AppSpacing.lg),

                // Premium Upgrade Banner
                PremiumBanner(
                  onTap: () =>
                      AppRouter.navigateTo(AppRoutes.subscriptionPlans),
                ),
                SizedBox(height: AppSpacing.lg),

                // Management Cards (Locations & Employees)
                BlocBuilder<LocationBloc, LocationState>(
                  builder: (context, locationState) {
                    final locationsCount = locationState is LocationsLoaded
                        ? locationState.locations
                              .where((location) => location.isActive)
                              .length
                        : 0;
                    return BlocBuilder<EmployeeBloc, EmployeeState>(
                      builder: (context, employeeState) {
                        final employeesCount = employeeState is EmployeeLoaded
                            ? employeeState.totalCount
                            : 0;
                        return ManagementCards(
                          locationsCount: locationsCount,
                          employeesCount: employeesCount,
                          showEmployeesCard:
                              PermissionService.canManageEmployees(isOwner),
                          onProductsTab: () {
                            final contextData = Provider.of<BusinessContext>(
                              context,
                              listen: false,
                            );
                            if (contextData.currentBusinessId != null) {
                              String address = '';
                              if (locationState is LocationsLoaded) {
                                try {
                                  final currentLoc = locationState.locations
                                      .firstWhere(
                                        (loc) =>
                                            loc.id ==
                                            contextData.currentBusinessId,
                                      );
                                  address = currentLoc.address;
                                } catch (_) {}
                              }

                              AppRouter.navigateTo(
                                AppRoutes.productManagement,
                                arguments: {
                                  'locationId': contextData.currentBusinessId,
                                  'locationName':
                                      contextData.currentBusinessName,
                                  'locationAddress': address,
                                },
                              );
                            } else {
                              AppSnackBar.show(
                                context,
                                message: l10n.translate(
                                  'home.please_select_location',
                                ),
                                type: AppSnackBarType.warning,
                              );
                            }
                          },
                          onLocationsTab: () => AppRouter.navigateTo(
                            AppRoutes.locationManagement,
                          ),
                          onEmployeesTab: () {
                            final contextData = Provider.of<BusinessContext>(
                              context,
                              listen: false,
                            );
                            if (contextData.currentBusinessId != null) {
                              AppRouter.navigateTo(AppRoutes.employeeList);
                            } else {
                              AppSnackBar.show(
                                context,
                                message: l10n.translate(
                                  'home.please_select_location',
                                ),
                                type: AppSnackBarType.warning,
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: AppSpacing.xl),
                const SafeArea(top: false, child: SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _summaryCacheKey(int? businessLocationId, _SummaryPeriod period) {
    final range = _rangeFromTodayBack(period);
    final fromDate = _isoDate(range.from);
    final toDate = _isoDate(range.to);
    final locationPart = businessLocationId?.toString() ?? 'all';
    return 'home_dashboard_summary_${locationPart}_${period.name}_${fromDate}_$toDate';
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
    switch (filter) {
      case _InsightTypeFilter.topSeller:
        return 'Top sản phẩm bán chạy';
      case _InsightTypeFilter.growthTrend:
        return 'Sản phẩm xu hướng tăng trưởng';
      case _InsightTypeFilter.promoteCandidate:
        return 'Sản phẩm nên đẩy bán';
    }
  }

  String _insightFilterLabel(_InsightTypeFilter filter) {
    switch (filter) {
      case _InsightTypeFilter.topSeller:
        return 'Bán chạy';
      case _InsightTypeFilter.growthTrend:
        return 'Tăng trưởng';
      case _InsightTypeFilter.promoteCandidate:
        return 'Đề xuất đẩy';
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
      if (!mounted) return;
      setState(() {
        _acknowledgingAnomalyIds.remove(anomalyId);
      });
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

  int? _asIntId(String? rawId) {
    if (rawId == null) {
      return null;
    }
    return int.tryParse(rawId);
  }

  _DateRange _rangeFromTodayBack(_SummaryPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case _SummaryPeriod.today:
        return _DateRange(from: today, to: today);
      case _SummaryPeriod.week:
        return _DateRange(
          from: today.subtract(const Duration(days: 6)),
          to: today,
        );
      case _SummaryPeriod.month:
        return _DateRange(
          from: today.subtract(const Duration(days: 29)),
          to: today,
        );
    }
  }

  String _isoDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }

  Widget _buildPeriodSelector() {
    final l10n = AppLocalizations.of(context);

    Widget buildPeriodButton(_SummaryPeriod period, String text) {
      final isSelected = _selectedPeriod == period;
      return GestureDetector(
        onTap: () {
          if (isSelected) return;
          setState(() {
            _selectedPeriod = period;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildPeriodButton(
          _SummaryPeriod.today,
          l10n.translate('home.period_today'),
        ),
        SizedBox(width: AppSpacing.sm),
        buildPeriodButton(
          _SummaryPeriod.week,
          l10n.translate('home.period_week'),
        ),
        SizedBox(width: AppSpacing.sm),
        buildPeriodButton(
          _SummaryPeriod.month,
          l10n.translate('home.period_month'),
        ),
      ],
    );
  }

  String _periodLabel(AppLocalizations l10n) {
    switch (_selectedPeriod) {
      case _SummaryPeriod.today:
        return l10n.translate('home.period_today').toLowerCase();
      case _SummaryPeriod.week:
        return l10n.translate('home.period_week').toLowerCase();
      case _SummaryPeriod.month:
        return l10n.translate('home.period_month').toLowerCase();
    }
  }

  String _ordersTitle(AppLocalizations l10n) {
    return l10n.translate(
      'home.orders_in_period',
      params: {'period': _periodLabel(l10n)},
    );
  }

  String _revenueTitle(AppLocalizations l10n) {
    return l10n.translate(
      'home.revenue_in_period',
      params: {'period': _periodLabel(l10n)},
    );
  }

  String _costTitle(AppLocalizations l10n) {
    return l10n.translate(
      'home.cost_in_period',
      params: {'period': _periodLabel(l10n)},
    );
  }

  String _debtTitle(AppLocalizations l10n) {
    return l10n.translate(
      'home.debt_in_period',
      params: {'period': _periodLabel(l10n)},
    );
  }
}

class _DateRange {
  final DateTime from;
  final DateTime to;

  const _DateRange({required this.from, required this.to});
}
