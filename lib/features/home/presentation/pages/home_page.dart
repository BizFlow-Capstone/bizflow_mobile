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
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/services/permission_service.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../employee/presentation/bloc/employee_bloc.dart';
import '../../../employee/presentation/bloc/employee_event.dart';
import '../../../employee/presentation/bloc/employee_state.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_event.dart';
import '../../../location/presentation/bloc/location_state.dart';
import '../../data/home_dashboard_api_service.dart';
import '../../data/models/dashboard_summary_dto.dart';
import '../widgets/quick_actions.dart';
import '../widgets/premium_banner.dart';
import '../widgets/management_cards.dart';
import '../widgets/stats_cards.dart';

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

class _HomePageState extends State<HomePage> {
  String? _lastEmployeeLoadedBusinessId;
  _SummaryPeriod _selectedPeriod = _SummaryPeriod.today;

  @override
  void initState() {
    super.initState();

    // Đảm bảo danh sách địa điểm được tải khi ở HomePage để hiển thị trên Sidebar
    final locationBloc = context.read<LocationBloc>();
    if (locationBloc.state is LocationInitial) {
      locationBloc.add(const LoadLocationsRequested());
    }
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
