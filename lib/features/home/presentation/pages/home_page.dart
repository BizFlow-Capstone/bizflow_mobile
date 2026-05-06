import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/cache/swr_builder.dart';
import '../../../../shared/cache/sync_status_controller.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/services/permission_service.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../employee/presentation/bloc/employee_bloc.dart';
import '../../../employee/presentation/bloc/employee_event.dart';
import '../../../employee/presentation/bloc/employee_state.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_event.dart';
import '../../../location/presentation/bloc/location_state.dart';
import '../../../location/domain/entities/location_entity.dart';
import 'dart:async';
import '../../data/home_dashboard_api_service.dart';
import '../../../subscription/data/subscription_api_service.dart';
import '../../../subscription/data/subscription_repository.dart';
import '../../../subscription/data/models/subscription_models.dart';
import '../../../../shared/cache/cache_manager.dart';
import '../../data/models/dashboard_summary_dto.dart';
import '../widgets/quick_actions.dart';
import '../widgets/premium_banner.dart';
import '../widgets/management_cards.dart';
import '../widgets/stats_cards.dart';
import '../widgets/home_ai_section.dart';

enum _SummaryPeriod { today, week, month }

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
  DashboardSummaryDto? _lastVisibleSummary;
  int? _lastSummaryBusinessLocationId;
  PageRoute<dynamic>? _subscribedRoute;

  @override
  void initState() {
    super.initState();
    SyncStatusController().setManualRefreshCallback(_triggerManualRefresh);

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
      // Seed fast from local cache first (if any), then always revalidate from server.
      final existing = await cache.get('current_subscription');
      if (existing != null) {
        // Seed in-memory value from cache so CurrentSubscriptionPage reads it sync.
        try {
          repo.updateCurrentSubscription(
            CurrentSubscriptionDto.fromJson(
              Map<String, dynamic>.from(existing),
            ),
          );
        } catch (_) {}
      }

      final fresh = await apiService.getCurrentSubscription();
      repo.updateCurrentSubscription(fresh);
      if (fresh == null) {
        await cache.remove('current_subscription');
        await cache.remove('current_subscription_for_plans');
        return;
      }

      final json = fresh.toJson();
      await cache.set('current_subscription', json);
      await cache.set('current_subscription_for_plans', json);
    } catch (_) {
      // Best-effort: silently ignore if prefetch fails.
    }
  }

  bool _isCurrentBusinessLocationActive({
    required List<LocationEntity> locations,
    required String? currentBusinessId,
  }) {
    if (currentBusinessId == null) return false;
    for (final location in locations) {
      if (location.id == currentBusinessId) {
        return location.isActive;
      }
    }
    return false;
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
    SyncStatusController().setManualRefreshCallback(null);
    if (_subscribedRoute != null) {
      AppRouter.routeObserver.unsubscribe(this);
      _subscribedRoute = null;
    }
    super.dispose();
  }

  void _triggerManualRefresh() {
    unawaited(_refreshHomeManually());
  }

  Future<void> _refreshHomeManually() async {
    if (!mounted) return;

    SyncStatusController().startSync();
    try {
      final businessContext = context.read<BusinessContext>();
      final businessLocationId = _asIntId(businessContext.currentBusinessId);

      // Force SWR to perform a true network revalidate instead of serving/throttling cache.
      await CacheManager().removeByPrefix('home_dashboard_summary_');
      if (businessLocationId != null) {
        await CacheManager().remove(_aiCacheKey(businessLocationId));
      } else {
        await CacheManager().removeByPrefix('home_ai_bundle_');
      }

      if (!mounted) return;

      context.read<LocationBloc>().add(
        const LoadLocationsRequested(useCache: false),
      );

      if (businessContext.isOwner &&
          businessContext.currentBusinessId != null) {
        context.read<EmployeeBloc>().add(
          LoadEmployeesRequested(
            businessId: businessContext.currentBusinessId!,
          ),
        );
      }

      await _prefetchSubscription();

      if (!mounted) return;

      setState(() {
        _summaryRefreshTick++;
      });

      SyncStatusController().endSync(updatedAt: DateTime.now());
    } catch (e) {
      SyncStatusController().endSync(hasError: true);
    }
  }

  @override
  void didPopNext() {
    SyncStatusController().setManualRefreshCallback(_triggerManualRefresh);
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

    if (_lastSummaryBusinessLocationId != businessLocationId) {
      _lastSummaryBusinessLocationId = businessLocationId;
      _lastVisibleSummary = null;
    }

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
          final allLocations = state.locations;

          if (allLocations.isEmpty) {
            // Only route to no-location when user truly has zero locations.
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
            final hasAnyActive = allLocations.any(
              (location) => location.isActive,
            );
            LocationEntity? selectedLocation;
            if (selectedId != null) {
              for (final location in allLocations) {
                if (location.id == selectedId) {
                  selectedLocation = location;
                  break;
                }
              }
            }
            final isSelectedValid =
                selectedLocation != null &&
                (!hasAnyActive || selectedLocation.isActive);
            if (!isSelectedValid) {
              final firstLocation = allLocations.firstWhere(
                (location) => location.isActive,
                orElse: () => allLocations.first,
              );
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
          child: RefreshIndicator(
            onRefresh: _refreshHomeManually,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const AlwaysScrollableScrollPhysics(),
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

                    if (data != null) {
                      _lastVisibleSummary = data;
                    }
                    final summary = data ?? _lastVisibleSummary;
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
                        summary?.outstandingDebtNetChangeInPeriod ?? 0,
                      ),
                      isRefreshing: isFetching,
                    );
                  },
                ),
                SizedBox(height: AppSpacing.md),

                if (businessLocationId != null)
                  HomeAiSection(
                    key: ValueKey(
                      'home_ai_bundle_${businessLocationId}_$_summaryRefreshTick',
                    ),
                    businessLocationId: businessLocationId,
                    businessLocationRawId: businessContext.currentBusinessId,
                  ),

                // Quick Actions
                BlocBuilder<LocationBloc, LocationState>(
                  builder: (context, locationState) {
                    final allLocations = locationState is LocationsLoaded
                        ? locationState.locations
                        : context.read<LocationBloc>().currentLocations;
                    final isCurrentLocationActive =
                        _isCurrentBusinessLocationActive(
                          locations: allLocations,
                          currentBusinessId: businessContext.currentBusinessId,
                        );

                    void showInactiveWarning() {
                      AppSnackBar.show(
                        context,
                        message: l10n.translate('home.location_inactive_block'),
                        type: AppSnackBarType.warning,
                      );
                    }

                    return QuickActions(
                      onCreateOrder: () {
                        if (!isCurrentLocationActive) {
                          showInactiveWarning();
                          return;
                        }
                        AppRouter.navigateTo(AppRoutes.orderCreateSelection);
                      },
                      onOrders: () {
                        if (!isCurrentLocationActive) {
                          showInactiveWarning();
                          return;
                        }
                        AppRouter.navigateTo(AppRoutes.orderList);
                      },
                      onDebt: () {
                        if (!isCurrentLocationActive) {
                          showInactiveWarning();
                          return;
                        }
                        AppRouter.navigateTo(AppRoutes.debtList);
                      },
                      onReport: () {
                        if (!isCurrentLocationActive) {
                          showInactiveWarning();
                          return;
                        }
                        AppRouter.navigateTo(AppRoutes.accounting);
                      },
                      showReport: PermissionService.canViewReports(isOwner),
                      showDebt: PermissionService.canViewDebtors(isOwner),
                    );
                  },
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
                            final isCurrentLocationActive =
                                _isCurrentBusinessLocationActive(
                                  locations: locationState is LocationsLoaded
                                      ? locationState.locations
                                      : context
                                            .read<LocationBloc>()
                                            .currentLocations,
                                  currentBusinessId:
                                      contextData.currentBusinessId,
                                );
                            if (!isCurrentLocationActive) {
                              AppSnackBar.show(
                                context,
                                message: l10n.translate(
                                  'home.location_inactive_block',
                                ),
                                type: AppSnackBarType.warning,
                              );
                              return;
                            }

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
                            final isCurrentLocationActive =
                                _isCurrentBusinessLocationActive(
                                  locations: locationState is LocationsLoaded
                                      ? locationState.locations
                                      : context
                                            .read<LocationBloc>()
                                            .currentLocations,
                                  currentBusinessId:
                                      contextData.currentBusinessId,
                                );
                            if (!isCurrentLocationActive) {
                              AppSnackBar.show(
                                context,
                                message: l10n.translate(
                                  'home.location_inactive_block',
                                ),
                                type: AppSnackBarType.warning,
                              );
                              return;
                            }

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
        final startOfWeek = today.subtract(
          Duration(days: today.weekday - DateTime.monday),
        );
        return _DateRange(
          from: startOfWeek,
          to: startOfWeek.add(const Duration(days: 6)),
        );
      case _SummaryPeriod.month:
        final startOfMonth = DateTime(today.year, today.month, 1);
        final endOfMonth = DateTime(today.year, today.month + 1, 0);
        return _DateRange(from: startOfMonth, to: endOfMonth);
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
