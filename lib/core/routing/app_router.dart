import 'package:flutter/material.dart';

/// Route names - Tập trung khai báo tất cả route
class AppRoutes {
  AppRoutes._();

  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Add more routes here...
}

/// App Router - Điều hướng tập trung
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Lấy context hiện tại
  static BuildContext? get context => navigatorKey.currentContext;

  /// Generate route
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(
          settings,
          const _PlaceholderPage(title: 'Splash'),
        );

      case AppRoutes.login:
        return _buildRoute(
          settings,
          const _PlaceholderPage(title: 'Login'),
        );

      case AppRoutes.register:
        return _buildRoute(
          settings,
          const _PlaceholderPage(title: 'Register'),
        );

      case AppRoutes.forgotPassword:
        return _buildRoute(
          settings,
          const _PlaceholderPage(title: 'Forgot Password'),
        );

      case AppRoutes.home:
        return _buildRoute(
          settings,
          const _PlaceholderPage(title: 'Home'),
        );

      case AppRoutes.profile:
        return _buildRoute(
          settings,
          const _PlaceholderPage(title: 'Profile'),
        );

      case AppRoutes.settings:
        return _buildRoute(
          settings,
          const _PlaceholderPage(title: 'Settings'),
        );

      default:
        return _buildRoute(
          settings,
          const _NotFoundPage(),
        );
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

/// Placeholder page - Dùng tạm khi chưa có page thật
class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title Page\n(Placeholder)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
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
