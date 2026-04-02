import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/services/permission_service.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../employee/presentation/bloc/employee_bloc.dart';
import '../../../employee/presentation/bloc/employee_event.dart';
import '../../../employee/presentation/bloc/employee_state.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_event.dart';
import '../../../location/presentation/bloc/location_state.dart';
import '../widgets/quick_actions.dart';
import '../widgets/premium_banner.dart';
import '../widgets/management_cards.dart';
import '../widgets/stats_cards.dart';

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
    final isOwner = businessContext.isOwner;
    final todaysRevenueMock = CurrencyFormatter.formatVND(18500000);
    final todaysCostMock = CurrencyFormatter.formatVND(7350000);
    final todaysDebtMock = CurrencyFormatter.formatVND(4200000);

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
          if (state.locations.isEmpty) {
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
                state.locations.any((location) => location.id == selectedId);
            if (!isSelectedValid) {
              final firstLocation = state.locations.first;
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

                // Daily Summary (mock data for now)
                StatsCards(
                  todaysOrders: 16,
                  todaysRevenue: todaysRevenueMock,
                  todaysCost: todaysCostMock,
                  todaysDebt: todaysDebtMock,
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
                        ? locationState.locations.length
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
}
