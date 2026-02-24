import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/localization/app_localizations.dart';
import 'core/network/api_client.dart';
import 'core/providers/localization_provider.dart';
import 'core/routing/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/employee/data/employee_api_service.dart';
import 'features/employee/data/employee_repository.dart';
import 'features/location/data/location_api_service.dart';
import 'features/location/data/location_repository.dart';
import 'features/location/presentation/bloc/location_bloc.dart';
import 'features/order/data/order_api_service.dart';
import 'features/order/data/order_repository.dart';
import 'features/order/presentation/bloc/order_bloc.dart';
import 'features/product/presentation/bloc/product_bloc.dart';

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
  late ApiClient _apiClient;
  late LocationApiService _locationApiService;
  late LocationRepository _locationRepository;
  late EmployeeApiService _employeeApiService;
  late EmployeeRepository _employeeRepository;
  late OrderApiService _orderApiService;
  late OrderRepository _orderRepository;

  @override
  void initState() {
    super.initState();
    _localizationProvider = LocalizationProvider();

    // Initialize API Client with interceptors
    _apiClient = ApiClient(
      baseUrl: AppConfig.baseUrl,
      timeout: AppConfig.apiTimeout,
      requestInterceptors: [
        // NOTE: Auth interceptor disabled - API backend has no permission yet
        // Uncomment below when auth is implemented
        // AuthInterceptor(
        //   getToken: () async {
        //     final token = await SecureStorage().read(key: 'access_token');
        //     return token ?? 'Bearer mock_token_for_testing';
        //   },
        // ),
        
        // Language interceptor - reads from LocalizationProvider
        LanguageInterceptor(
          getCurrentLanguage: () => _localizationProvider.currentLocale.languageCode,
        ),
      ],
      responseInterceptors: AppConfig.enableLogging
          ? [LoggingInterceptor()]
          : [],
    );

    // Initialize Services (calls ApiClient)
    _locationApiService = LocationApiService(apiClient: _apiClient);
    _employeeApiService = EmployeeApiService(apiClient: _apiClient);
    _orderApiService = OrderApiService(apiClient: _apiClient);

    // Initialize Repositories (calls Services)
    _locationRepository = LocationRepository(service: _locationApiService);
    _employeeRepository = EmployeeRepository(service: _employeeApiService);
    _orderRepository = OrderRepository(apiService: _orderApiService);
  }

  @override
  void dispose() {
    _localizationProvider.dispose();
    _apiClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _localizationProvider),
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(
          create: (context) => LocationBloc(
            repository: _locationRepository,
            employeeRepository: _employeeRepository,
          ),
        ),
        BlocProvider(
          create: (context) => OrderBloc(
            repository: _orderRepository,
          ),
        ),
        BlocProvider(
          create: (context) => ProductBloc(),
        ),
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
                initialRoute: AppRoutes.home,
              );
            },
          );
        },
      ),
    );
  }
}
