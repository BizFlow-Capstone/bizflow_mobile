import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:bizflow_mobile/core/localization/app_localizations.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verify_otp_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/set_password_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../core/services/firebase_messaging_service.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/location/presentation/pages/location_management_page.dart';
import '../../features/location/presentation/pages/add_edit_location_page.dart';
import '../../features/location/presentation/pages/no_location_page.dart';
import '../../features/product/presentation/pages/product_management_page.dart';
import '../../features/product/presentation/pages/import_history_page.dart';
import '../../features/order/presentation/pages/order_list_screen.dart';
import '../../features/order/presentation/pages/order_status_screen.dart';
import '../../features/order/presentation/pages/order_creation_selection_screen.dart';
import '../../features/subscription/presentation/pages/subscription_plans_page.dart';
import '../../features/subscription/presentation/pages/premium_payment_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/notification/presentation/pages/notification_list_page.dart';
import '../../features/notification/presentation/pages/notification_detail_page.dart';
import '../../features/debt/presentation/pages/debt_list_page.dart';
import '../../features/accounting/presentation/pages/accounting_hub_page.dart';
import '../../features/accounting/presentation/pages/general_ledger_page.dart';
import '../../features/invoice_template/presentation/pages/invoice_template_page.dart';
import '../../features/invoice_template/presentation/pages/advanced_invoice_template_page.dart';
import '../../features/employee/presentation/pages/employee_list_page.dart';
import '../../features/employee/presentation/pages/add_employee_page.dart';
import '../../features/employee/presentation/pages/edit_employee_page.dart';
import '../../features/employee/presentation/pages/employee_invitations_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/location/presentation/bloc/location_bloc.dart';
import '../../features/location/presentation/bloc/location_state.dart';

import '../../shared/widgets/app_bar_custom.dart';
import '../../shared/widgets/sidebar_widget.dart';
import '../../shared/dialogs/app_snackbar.dart';
import '../../shared/context/business_context.dart';
import '../../shared/context/notification_context.dart';

/// Route names - Tập trung khai báo tất cả route
class AppRoutes {
  AppRoutes._();

  static const String setPassword = '/set-password';

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
  static const String noLocation = '/no-location';
  static const String productManagement = '/product-management';
  static const String orderList = '/order-list';
  static const String orderStatus = '/order-status';
  static const String orderCreateSelection = '/order-create-selection';
  static const String subscriptionPlans = '/subscription-plans';
  static const String premiumPayment = '/premium-payment';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String importHistory = '/import-history';
  static const String notifications = '/notifications';
  static const String notificationDetail = '/notification-detail';
  static const String debtList = '/debt-list';
  static const String accounting = '/accounting';
  static const String generalLedger = '/general-ledger';
  static const String invoiceTemplate = '/invoice-template';
  static const String advancedInvoiceTemplate = '/advanced-invoice-template';
  static const String employeeList = '/employee-list';
  static const String addEmployee = '/add-employee';
  static const String editEmployee = '/edit-employee';
  static const String employeeDetail = '/employee-detail';
  static const String employeeAssign = '/employee-assign';
  static const String employeeUnassign = '/employee-unassign';
  static const String employeeInvitations = '/employee-invitations';
}

/// Global AppBar State - Quản lý tập trung cho toàn hệ thống
class GlobalAppBarState extends ChangeNotifier {
  String _userName = 'User';
  String? _avatarUrl;
  Locale _currentLocale = const Locale('vi');

  String get userName => _userName;
  String? get avatarUrl => _avatarUrl;
  Locale get currentLocale => _currentLocale;

  void updateUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void updateAvatarUrl(String? url) {
    _avatarUrl = (url == null || url.trim().isEmpty) ? null : url.trim();
    notifyListeners();
  }

  void updateProfile({String? name, String? avatarUrl}) {
    if (name != null && name.trim().isNotEmpty) {
      _userName = name.trim();
    }
    _avatarUrl = (avatarUrl == null || avatarUrl.trim().isEmpty)
        ? null
        : avatarUrl.trim();
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _currentLocale = locale;
    notifyListeners();
  }

  void reset() {
    _userName = 'User';
    _avatarUrl = null;
    _currentLocale = const Locale('vi');
    notifyListeners();
  }
}

/// App Router - Điều hướng tập trung
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalAppBarState globalAppBarState = GlobalAppBarState();

  /// Lấy context hiện tại
  static BuildContext? get context => navigatorKey.currentContext;

  /// Generate route
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth Routes - No AppBar
      case AppRoutes.splash:
        return _buildRoute(settings, const SplashPage());

      case AppRoutes.login:
        return _buildRoute(settings, const LoginPage());

      case AppRoutes.register:
        return _buildRoute(settings, const RegisterPage());

      case AppRoutes.verifyOtp:
        return _buildRoute(
          settings,
          const VerifyOtpPage(phoneNumber: '095555555'),
        );

      case AppRoutes.setPassword:
        return _buildRoute(settings, const SetPasswordPage());

      case AppRoutes.forgotPassword:
        return _buildRoute(settings, const ForgotPasswordPage());

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
            showAddLocationFab: true,
            child: const LocationManagementPage(),
          ),
        );

      case AppRoutes.addEditLocation:
        return _buildRoute(settings, const AddEditLocationPage());

      case AppRoutes.noLocation:
        return _buildRoute(settings, const NoLocationPage());

      case AppRoutes.productManagement:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          settings,
          ProductManagementPage(
            locationId: args?['locationId'] ?? '',
            locationName: args?['locationName'] ?? 'Location',
            locationAddress: args?['locationAddress'] ?? 'Address',
          ),
        );

      case AppRoutes.orderList:
        return _buildRoute(settings, const OrderListScreen());

      case AppRoutes.orderCreateSelection:
        return _buildRoute(settings, const OrderCreationSelectionScreen());

      case AppRoutes.orderStatus:
        return _buildRoute(settings, const OrderStatusScreen());

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
        return _buildRoute(settings, const ProfilePage());

      case AppRoutes.settings:
        return _buildRoute(settings, const SettingsPage());

      case AppRoutes.notifications:
        return _buildRoute(settings, const NotificationListPage());

      case AppRoutes.notificationDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          settings,
          NotificationDetailPage(
            title: args?['title'] ?? '',
            body: args?['body'] ?? '',
            time: args?['time'] ?? '',
            icon: args?['icon'] ?? Icons.notifications,
            iconColor: args?['iconColor'] ?? Colors.blue,
          ),
        );

      case AppRoutes.debtList:
        return _buildRoute(settings, const DebtListPage());

      case AppRoutes.accounting:
        return _buildRoute(settings, const AccountingHubPage());

      case AppRoutes.generalLedger:
        return _buildRoute(settings, const GeneralLedgerPage());

      case AppRoutes.importHistory:
        return _buildRoute(settings, const ImportHistoryPage());

      case AppRoutes.invoiceTemplate:
        return _buildRoute(settings, const InvoiceTemplatePage());

      case AppRoutes.advancedInvoiceTemplate:
        return _buildRoute(settings, const AdvancedInvoiceTemplatePage());

      case AppRoutes.employeeList:
        return _buildRoute(settings, const EmployeeListPage());

      case AppRoutes.addEmployee:
        return _buildRoute(settings, const AddEmployeePage());

      case AppRoutes.editEmployee:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          settings,
          EditEmployeePage(
            employeeId: args?['employeeId'] ?? '',
            mode: EmployeeEditMode.assign,
          ),
        );

      case AppRoutes.employeeDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          settings,
          EditEmployeePage(
            employeeId: args?['employeeId'] ?? '',
            mode: EmployeeEditMode.detail,
          ),
        );

      case AppRoutes.employeeAssign:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          settings,
          EditEmployeePage(
            employeeId: args?['employeeId'] ?? '',
            mode: EmployeeEditMode.assign,
          ),
        );

      case AppRoutes.employeeUnassign:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          settings,
          EditEmployeePage(
            employeeId: args?['employeeId'] ?? '',
            mode: EmployeeEditMode.unassign,
          ),
        );

      case AppRoutes.employeeInvitations:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          settings,
          EmployeeInvitationsPage(
            allowBack: args?['allowBack'] as bool? ?? true,
          ),
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
    return MaterialPageRoute<T>(settings: settings, builder: (_) => page);
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
  static Future<T?> navigateAndClearStack<T>(
    String routeName, {
    Object? arguments,
  }) {
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<String>? _navigationSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for immediate navigation from notifications
    _navigationSubscription = FirebaseMessagingService.navigationStream.listen((
      route,
    ) {
      debugPrint('_GlobalAppBarShell: Immediate navigation to $route');
      AppRouter.navigateTo(route);
    });
    NotificationContext().refreshUnreadCount();
  }

  @override
  void dispose() {
    _navigationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationContext>().unreadCount;
    return ListenableBuilder(
      listenable: AppRouter.globalAppBarState,
      builder: (context, _) {
        return Scaffold(
          key: _scaffoldKey,
          // Global AppBar
          appBar: CustomAppBar(
            userName: AppRouter.globalAppBarState.userName,
            avatarUrl: AppRouter.globalAppBarState.avatarUrl,
            scaffoldKey: _scaffoldKey,
            notificationCount: unreadCount,
            onLocaleChange: (locale) {
              AppRouter.globalAppBarState.setLocale(locale);
            },
            onNotificationTap: () {
              AppRouter.navigateTo(AppRoutes.notifications);
            },
            onSettingsTap: () {
              AppRouter.navigateTo(AppRoutes.settings);
            },
          ),
          // Drawer
          drawer: Consumer<BusinessContext>(
            builder: (context, businessContext, _) {
              return BlocBuilder<LocationBloc, LocationState>(
                builder: (context, state) {
                  // Get locations for sidebar
                  final l10n = AppLocalizations.of(context);
                  List<LocationItem> locations = [];
                  LocationItem? selectedLocation;

                  if (state is LocationsLoaded) {
                    locations = state.locations
                        .map(
                          (loc) => LocationItem(
                            id: loc.id,
                            name: loc.name,
                            isActive: loc.isActive,
                          ),
                        )
                        .toList();

                    // Resolve selectedLocation from businessContext
                    if (businessContext.currentBusinessId != null) {
                      try {
                        selectedLocation = locations.firstWhere(
                          (loc) => loc.id == businessContext.currentBusinessId,
                        );
                      } catch (_) {
                        // Safe fallback
                      }
                    } else if (locations.isNotEmpty) {
                      // Fallback if no context selected
                      selectedLocation = locations.first;
                    }
                  }

                  return SidebarWidget(
                    locations: locations,
                    selectedLocation: selectedLocation,
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
                      final authBloc = context.read<AuthBloc>();
                      authBloc.add(const LogoutRequested());
                    },
                    onGuide: () {
                      AppSnackBar.show(
                        context,
                        message: l10n.translate('sidebar.guide'),
                        type: AppSnackBarType.info,
                      );
                    },
                    onAccountSettings: () {
                      AppRouter.navigateTo(AppRoutes.profile);
                    },
                    onLocationSelected: (location) {
                      businessContext.switchBusinessLocation(
                        location.id,
                        location.name,
                      );
                      // Go back to Home
                      AppRouter.navigateAndClearStack(AppRoutes.home);
                    },
                  );
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
