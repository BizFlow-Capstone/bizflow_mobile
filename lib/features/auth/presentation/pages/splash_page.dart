import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../navigation/post_auth_navigation.dart';

/// Splash / Auth-check page
/// Dispatches AppStarted, then routes to home or login
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AppStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is NeedsSetPasswordOnResume) {
          AppRouter.navigateAndClearStack(AppRoutes.setPassword);
        } else if (state is AuthAuthenticated) {
          PostAuthNavigation.route(context);
        } else if (state is AuthUnauthenticated) {
          AppRouter.navigateAndClearStack(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logos/Bizflow.png',
                width: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'BizFlow',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF23C4C1),
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: Color(0xFF23C4C1)),
            ],
          ),
        ),
      ),
    );
  }
}
