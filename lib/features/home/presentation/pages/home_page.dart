import 'package:flutter/material.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/greeting_section.dart';
import '../widgets/stats_cards.dart';
import '../widgets/quick_actions.dart';
import '../widgets/premium_banner.dart';
import '../widgets/management_cards.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Actions
              QuickActions(
                onOrders: () => AppRouter.navigateTo(AppRoutes.orderList),
              ),
              SizedBox(height: AppSpacing.lg),

              // Premium Upgrade Banner
              PremiumBanner(
                onTap: () => AppRouter.navigateTo(AppRoutes.subscriptionPlans),
              ),
              SizedBox(height: AppSpacing.lg),

              // Management Cards (Locations & Employees)
              ManagementCards(
                onLocationsTab: () =>
                    AppRouter.navigateTo(AppRoutes.locationManagement),
              ),
              SizedBox(height: AppSpacing.xl),
              const SafeArea(top: false, child: SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}
