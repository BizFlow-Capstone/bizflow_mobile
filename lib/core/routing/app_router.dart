import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizflow_mobile/core/localization/app_localizations.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verify_otp_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/location/presentation/pages/location_management_page.dart';
import '../../features/location/presentation/pages/add_edit_location_page.dart';
import '../../features/product/presentation/pages/product_management_page.dart';
import '../../features/order/presentation/pages/order_list_screen.dart';
import '../../features/order/presentation/pages/order_status_screen.dart';
import '../../features/subscription/presentation/pages/subscription_plans_page.dart';
import '../../features/subscription/presentation/pages/premium_payment_page.dart';
import '../../features/location/presentation/bloc/location_bloc.dart';
import '../../features/location/presentation/bloc/location_state.dart';
import '../../shared/widgets/app_bar_custom.dart';
import '../../shared/widgets/sidebar_widget.dart';
import '../../shared/dialogs/app_snackbar.dart';

/// Route names - Tập trung khai báo tất cả route
class AppRoutes {
  AppRoutes._();

  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';

  // Main
  static const String home = '/home';
  static const String locationManagement = '/location-management';
  static const String addEditLocation = '/add-edit-location';
  static const String productManagement = '/product-management';
  static const String orderList = '/order-list';
  static const String orderStatus = '/order-status';
  static const String subscriptionPlans = '/subscription-plans';
  static const String premiumPayment = '/premium-payment';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

/// Global AppBar State - Quản lý tập trung cho toàn hệ thống
class GlobalAppBarState extends ChangeNotifier {
  String _userName = 'User';
  Locale _currentLocale = const Locale('vi');

  String get userName => _userName;
  Locale get currentLocale => _currentLocale;

  void updateUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _currentLocale = locale;
    notifyListeners();
  }

  void reset() {
    _userName = 'User';
    _currentLocale = const Locale('vi');
    notifyListeners();
  }
}

/// App Router - Điều hướng tập trung
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalAppBarState globalAppBarState = GlobalAppBarState();

  /// Lấy context hiện tại
  static BuildContext? get context => navigatorKey.currentContext;

  /// Generate route
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth Routes - No AppBar
      case AppRoutes.splash:
      case AppRoutes.login:
        return _buildRoute(settings, const LoginPage());

      case AppRoutes.register:
        return _buildRoute(settings, const RegisterPage());

      case AppRoutes.verifyOtp:
        return _buildRoute(settings, const VerifyOtpPage(phoneNumber: '095555555',));

      case AppRoutes.forgotPassword:
        return _buildRoute(settings, const _PlaceholderPage(title: 'Forgot Password'));

      // Main Routes - With Global AppBar
      case AppRoutes.home:
        return _buildRoute(
          settings,
          _GlobalAppBarShell(child: const HomePage()),
        );
      case AppRoutes.locationManagement:
        return _buildRoute(
          settings,
          _GlobalAppBarShell(
            child: const LocationManagementPage(),
            showAddLocationFab: true,
          ),
        );

      case AppRoutes.addEditLocation:
        return _buildRoute(
          settings,
          _GlobalAppBarShell(child: const AddEditLocationPage()),
        );

      case AppRoutes.productManagement:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          settings,
          _GlobalAppBarShell(
            child: ProductManagementPage(
              locationId: args?['locationId'] ?? '',
              locationName: args?['locationName'] ?? 'Location',
              locationAddress: args?['locationAddress'] ?? 'Address',
            ),
          ),
        );

      case AppRoutes.orderList:
        return _buildRoute(
          settings,
          _GlobalAppBarShell(child: const OrderListScreen()),
        );

      case AppRoutes.orderStatus:
        return _buildRoute(
          settings,
          _GlobalAppBarShell(child: const OrderStatusScreen()),
        );

      case AppRoutes.subscriptionPlans:
        return _buildRoute(settings, const SubscriptionPlansPage());

      case AppRoutes.premiumPayment:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          settings,
          PremiumPaymentPage(
            planName: args?['planName'] ?? 'Premium',
            price: args?['price'] ?? 299000,
            period: args?['period'] ?? '/tháng',
            vatPercent: args?['vatPercent'] ?? 10,
            total: args?['total'] ?? 328900,
          ),
        );

      case AppRoutes.profile:
        return _buildRoute(
          settings,
          _GlobalAppBarShell(child: const _PlaceholderPage(title: 'Profile')),
        );

      case AppRoutes.settings:
        return _buildRoute(
          settings,
          _GlobalAppBarShell(child: const _PlaceholderPage(title: 'Settings')),
        );

      default:
        return _buildRoute(settings, const _NotFoundPage());
    }
  }

  /// Build MaterialPageRoute
  static MaterialPageRoute<T> _buildRoute<T>(
    RouteSettings settings,
    Widget page,
  ) {
    return MaterialPageRoute<T>(
      settings: settings,
      builder: (_) => page,
    );
  }

  /// Navigate to route
  static Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Replace current route
  static Future<T?> replaceTo<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed<T, dynamic>(
      routeName,
      arguments: arguments,
    );
  }

  /// Clear stack and navigate
  static Future<T?> navigateAndClearStack<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Pop current route
  static void pop<T>([T? result]) {
    navigatorKey.currentState!.pop<T>(result);
  }

  /// Pop until route
  static void popUntil(String routeName) {
    navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }

  /// Can pop
  static bool canPop() {
    return navigatorKey.currentState!.canPop();
  }
}

/// Global AppBar Shell - Wraps pages để cung cấp AppBar global
/// Global AppBar Shell - Wraps pages để cung cấp AppBar global + Drawer
class _GlobalAppBarShell extends StatefulWidget {
  final Widget child;
  final bool showAddLocationFab;

  const _GlobalAppBarShell({
    required this.child,
    this.showAddLocationFab = false,
  });

  @override
  State<_GlobalAppBarShell> createState() => _GlobalAppBarShellState();
}

class _GlobalAppBarShellState extends State<_GlobalAppBarShell> {
  LocationItem? _selectedLocation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppRouter.globalAppBarState,
      builder: (context, _) {
        return Scaffold(
          key: _scaffoldKey,
          // Global AppBar
          appBar: CustomAppBar(
            userName: AppRouter.globalAppBarState.userName,
            scaffoldKey: _scaffoldKey,
            onLocaleChange: (locale) {
              AppRouter.globalAppBarState.setLocale(locale);
            },
            onNotificationTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications')),
              );
            },
            onSettingsTap: () {
              AppRouter.navigateTo(AppRoutes.settings);
            },
          ),
          // Drawer
          drawer: BlocBuilder<LocationBloc, LocationState>(
            builder: (context, state) {
              // Get locations for sidebar
              final l10n = AppLocalizations.of(context);
              List<LocationItem> locations = [];
              if (state is LocationsLoaded) {
                locations = state.locations
                    .map((loc) => LocationItem(
                          id: loc.id,
                          name: loc.name,
                          isActive: loc.isActive,
                        ))
                    .toList();
              }

              return SidebarWidget(
                locations: locations,
                selectedLocation: _selectedLocation,
                onAddLocation: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditLocationPage(),
                    ),
                  );
                },
                onLogout: () {
                  AppSnackBar.show(
                    context,
                    message: l10n.translate('sidebar.logout'),
                    type: AppSnackBarType.info,
                  );
                },
                onGuide: () {
                  AppSnackBar.show(
                    context,
                    message: l10n.translate('sidebar.guide'),
                    type: AppSnackBarType.info,
                  );
                },
                onAccountSettings: () {
                  AppSnackBar.show(
                    context,
                    message: l10n.translate('sidebar.account_settings'),
                    type: AppSnackBarType.info,
                  );
                },
                onLocationSelected: (location) {
                  setState(() {
                    _selectedLocation = location;
                  });
                },
              );
            },
          ),
          // Body
          body: widget.child,
          // FAB - positioned at bottom-right
          floatingActionButton: widget.showAddLocationFab
              ? FloatingActionButton(
                  backgroundColor: const Color(0xFF23C4C1),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddEditLocationPage(),
                      ),
                    );
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}

/// Placeholder page - Dùng tạm khi chưa có page thật
class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title Page\n(Placeholder)',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

/// Not Found page
class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '404\nPage Not Found',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
