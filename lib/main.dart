import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/providers/localization_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/location/presentation/bloc/location_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late LocalizationProvider _localizationProvider;

  @override
  void initState() {
    super.initState();
    _localizationProvider = LocalizationProvider();
  }

  @override
  void dispose() {
    _localizationProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _localizationProvider),
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(create: (context) => LocationBloc()),
      ],
      child: Consumer<LocalizationProvider>(
        builder: (context, localizationProvider, _) {
          return ListenableBuilder(
            listenable: AppRouter.globalAppBarState,
            builder: (context, _) {
              return MaterialApp(
                title: 'BizFlow',
                theme: AppTheme.light,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                locale: localizationProvider.currentLocale,
                navigatorKey: AppRouter.navigatorKey,
                onGenerateRoute: AppRouter.generateRoute,
                initialRoute: AppRoutes.locationManagement,
              );
            },
          );
        },
      ),
    );
  }
}
