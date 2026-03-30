import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'core/config/app_config.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/notification_realtime_service.dart';
import 'core/network/api_client.dart';
import 'core/network/api_endpoints.dart';
import 'core/providers/localization_provider.dart';
import 'core/routing/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/data/auth_api_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/push_token_api_service.dart';
import 'features/notification/data/notification_api_service.dart';
import 'features/notification/data/notification_repository.dart';
import 'features/employee/data/employee_api_service.dart';
import 'features/employee/data/employee_repository.dart';
import 'features/employee/data/employee_management_repository.dart';
import 'features/employee/presentation/bloc/employee_bloc.dart';
import 'features/location/presentation/bloc/location_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/product/presentation/bloc/product_event.dart';
import 'features/debt/presentation/bloc/debtor_event.dart';
import 'features/location/data/location_api_service.dart';
import 'features/invoice_template/data/invoice_template_repository.dart';
import 'features/invoice_template/presentation/bloc/invoice_template_bloc.dart';
import 'features/invoice_template/presentation/bloc/invoice_template_event.dart';
import 'features/location/data/location_repository.dart';
import 'features/location/presentation/bloc/location_bloc.dart';
import 'features/subscription/data/subscription_api_service.dart';
import 'features/subscription/data/subscription_repository.dart';
import 'features/order/data/order_api_service.dart';
import 'features/order/data/order_repository.dart';
import 'features/order/presentation/bloc/order_bloc.dart';
import 'features/product/data/product_api_service.dart';
import 'features/product/data/product_repository.dart';
import 'features/product/presentation/bloc/product_bloc.dart';
import 'features/product/data/import_api_service.dart';
import 'features/product/data/import_repository.dart';
import 'features/debt/data/debtor_api_service.dart';
import 'features/debt/data/debtor_repository.dart';
import 'features/debt/presentation/bloc/debtor_bloc.dart';
import 'features/accounting/data/services/accounting_api_service.dart';
import 'features/accounting/data/repositories/accounting_repository.dart';
import 'features/accounting/presentation/bloc/accounting_period_bloc.dart';
import 'features/accounting/data/services/gl_api_service.dart';
import 'features/accounting/data/repositories/gl_repository.dart';
import 'features/accounting/presentation/bloc/gl_bloc/gl_bloc.dart';
import 'core/reference/data/reference_api_service.dart';
import 'core/reference/data/reference_repository.dart';
import 'core/reference/presentation/bloc/reference_bloc.dart';
import 'core/reference/presentation/bloc/reference_event.dart';
import 'features/revenue/data/revenue_api_service.dart';
import 'features/revenue/data/revenue_repository.dart';
import 'features/revenue/presentation/bloc/revenue_bloc.dart';
import 'features/cost/data/cost_api_service.dart';
import 'features/cost/data/cost_repository.dart';
import 'features/cost/presentation/bloc/cost_bloc.dart';

import 'shared/context/business_context.dart';
import 'shared/context/notification_context.dart';
import 'shared/context/user_profile_context.dart';
import 'shared/cache/cache_manager.dart';
import 'core/services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp();
  await ConnectivityService().initialize();
  await CacheManager().init();
  await BusinessContext().init();
  await UserProfileContext().init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSubscription;

  late LocalizationProvider _localizationProvider;
  late ApiClient _apiClient;
  late SecureStorage _secureStorage;
  late AuthApiService _authApiService;
  late AuthRepository _authRepository;
  late LocationApiService _locationApiService;
  late LocationRepository _locationRepository;
  late EmployeeApiService _employeeApiService;
  late EmployeeRepository _employeeRepository;
  late SubscriptionApiService _subscriptionApiService;
  late SubscriptionRepository _subscriptionRepository;
  late OrderApiService _orderApiService;
  late OrderRepository _orderRepository;
  late ProductApiService _productApiService;
  late ProductRepository _productRepository;
  late ImportApiService _importApiService;
  late ImportRepository _importRepository;
  late DebtorApiService _debtorApiService;
  late DebtorRepository _debtorRepository;
  late AccountingApiService _accountingApiService;
  late AccountingRepository _accountingRepository;
  late InvoiceTemplateRepository _invoiceTemplateRepository;
  late EmployeeManagementRepository _employeeManagementRepository;
  late PushTokenApiService _pushTokenApiService;
  late FirebaseMessagingService _firebaseMessagingService;
  late NotificationRealtimeService _notificationRealtimeService;
  late ReferenceApiService _referenceApiService;
  late ReferenceRepository _referenceRepository;
  late GLApiService _glApiService;
  late GLRepository _glRepository;
  late RevenueApiService _revenueApiService;
  late RevenueRepository _revenueRepository;
  late CostApiService _costApiService;
  late CostRepository _costRepository;
  late NotificationApiService _notificationApiService;
  late NotificationRepository _notificationRepository;

  @override
  void initState() {
    super.initState();
    _localizationProvider = LocalizationProvider();

    // Secure storage (token management)
    _secureStorage = SecureStorage();

    final authInterceptor = AuthInterceptor(
      getToken: () => _secureStorage.getAccessToken(),
    );

    final languageInterceptor = LanguageInterceptor(
      getCurrentLanguage: () =>
          _localizationProvider.currentLocale.languageCode,
    );

    final requestInterceptors = <RequestInterceptor>[
      authInterceptor,
      languageInterceptor,
    ];

    final responseInterceptors = <ResponseInterceptor>[
      if (AppConfig.enableLogging) LoggingInterceptor(),
      TokenRefreshInterceptor(
        getRefreshToken: () => _secureStorage.getRefreshToken(),
        onTokenRefreshed:
            ({
              required String accessToken,
              required String refreshToken,
            }) async {
              await _secureStorage.saveAuthTokens(
                accessToken: accessToken,
                refreshToken: refreshToken,
              );
            },
        onRefreshFailed: () async {
          await _secureStorage.clearAuthTokens();
          await BusinessContext().clear();
          await UserProfileContext().clear();
          await CacheManager().clearAll();
          AppRouter.globalAppBarState.reset();
          AppRouter.navigateAndClearStack(AppRoutes.login);
        },
        baseUrl: AppConfig.baseUrl,
        refreshEndpoint: ApiEndpoints.refreshTokenEndpoint,
        timeout: AppConfig.apiTimeout,
        requestInterceptors: [languageInterceptor],
      ),
    ];

    // Initialize API Client with interceptors
    _apiClient = ApiClient(
      baseUrl: AppConfig.baseUrl,
      timeout: AppConfig.apiTimeout,
      requestInterceptors: requestInterceptors,
      responseInterceptors: responseInterceptors,
    );

    // Auth service and repository
    _authApiService = AuthApiService(apiClient: _apiClient);
    _authRepository = AuthRepositoryImpl(_authApiService, _secureStorage);

    // Initialize Services (calls ApiClient)
    _locationApiService = LocationApiService(apiClient: _apiClient);
    _employeeApiService = EmployeeApiService(apiClient: _apiClient);
    _subscriptionApiService = SubscriptionApiService(_apiClient);
    _subscriptionRepository = SubscriptionRepository(_subscriptionApiService);
    _orderApiService = OrderApiService(apiClient: _apiClient);
    _productApiService = ProductApiService(apiClient: _apiClient);
    _importApiService = ImportApiService(apiClient: _apiClient);
    _debtorApiService = DebtorApiService(apiClient: _apiClient);
    _accountingApiService = AccountingApiService(apiClient: _apiClient);
    _glApiService = GLApiService(apiClient: _apiClient);
    _pushTokenApiService = PushTokenApiService(apiClient: _apiClient);
    _notificationApiService = NotificationApiService(apiClient: _apiClient);
    _referenceApiService = ReferenceApiService(apiClient: _apiClient);
    _revenueApiService = RevenueApiService(apiClient: _apiClient);
    _costApiService = CostApiService(apiClient: _apiClient);

    // Initialize Repositories (calls Services)
    _locationRepository = LocationRepository(service: _locationApiService);
    _employeeRepository = EmployeeRepository(service: _employeeApiService);
    _orderRepository = OrderRepository(apiService: _orderApiService);
    _productRepository = ProductRepository(service: _productApiService);
    _importRepository = ImportRepository(_importApiService);
    _debtorRepository = DebtorRepository(service: _debtorApiService);
    _accountingRepository = AccountingRepository(
      apiService: _accountingApiService,
    );
    _invoiceTemplateRepository = InvoiceTemplateRepositoryMock();
    _employeeManagementRepository = EmployeeManagementRepositoryApi(
      apiService: _employeeApiService,
      locationApiService: _locationApiService,
    );
    _notificationRepository = NotificationRepository(
      apiService: _notificationApiService,
    );
    NotificationContext().configure(_notificationRepository);
    _notificationRealtimeService = NotificationRealtimeService();
    NotificationRealtimeService.notificationStream.listen((_) {
      NotificationContext().refreshUnreadCount();
    });
    _referenceRepository = ReferenceRepository(
      apiService: _referenceApiService,
    );
    _glRepository = GLRepository(apiService: _glApiService);
    _revenueRepository = RevenueRepository(apiService: _revenueApiService);
    _costRepository = CostRepository(apiService: _costApiService);

    _firebaseMessagingService = FirebaseMessagingService(
      pushTokenApiService: _pushTokenApiService,
    );
    unawaited(_firebaseMessagingService.initialize());
    
    _notificationRealtimeService = NotificationRealtimeService();
    unawaited(_notificationRealtimeService.initialize());
    
    ConnectivityService().statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        // Trigger generic data refresh when network is back
        _locationRepository.getMyOwnedLocations().then((_) {
          debugPrint('Main: Triggered auto-refresh of locations after network recovery.');
        }).catchError((_) {});
      }
    });

    Future.microtask(() async {
      if (await _secureStorage.hasAccessToken()) {
        await _notificationRealtimeService.connect();
      }
    });

    final userProfile = UserProfileContext();
    AppRouter.globalAppBarState.updateProfile(
      name: userProfile.fullName,
      avatarUrl: userProfile.avatarUrl,
    );

    Future.microtask(_initializeDeepLinks);
  }

  Future<void> _initializeDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(AppRouter.handleIncomingDeepLink(initialUri));
        });
      }
    } catch (_) {}

    _deepLinkSubscription = _appLinks.uriLinkStream.listen((uri) {
      unawaited(AppRouter.handleIncomingDeepLink(uri));
    });
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    _firebaseMessagingService.dispose();
    _notificationRealtimeService.dispose();
    _localizationProvider.dispose();
    _apiClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _localizationProvider),
        ChangeNotifierProvider.value(value: BusinessContext()),
        ChangeNotifierProvider.value(value: NotificationContext()),
        BlocProvider(
          create: (context) => AuthBloc(
            locationRepository: _locationRepository,
            authRepository: _authRepository,
            secureStorage: _secureStorage,
            firebaseMessagingService: _firebaseMessagingService,
          ),
        ),
        BlocProvider(
          create: (context) => LocationBloc(
            repository: _locationRepository,
            employeeRepository: _employeeRepository,
          ),
        ),
        BlocProvider(
          create: (context) => OrderBloc(repository: _orderRepository),
        ),
        BlocProvider(
          create: (context) => ProductBloc(repository: _productRepository),
        ),
        BlocProvider(
          create: (context) => DebtorBloc(repository: _debtorRepository),
        ),
        BlocProvider(
          create: (context) =>
              AccountingPeriodBloc(repository: _accountingRepository),
        ),
        BlocProvider(
          create: (context) => ReferenceBloc(repository: _referenceRepository),
        ),
        BlocProvider(create: (context) => GLBloc(repository: _glRepository)),
        BlocProvider(
          create: (context) =>
              InvoiceTemplateBloc(repository: _invoiceTemplateRepository)
                ..add(const LoadInvoiceTemplateRequested()),
        ),
        BlocProvider(
          create: (context) =>
              EmployeeBloc(repository: _employeeManagementRepository),
        ),
        BlocProvider(
          create: (context) => RevenueBloc(repository: _revenueRepository),
        ),
        BlocProvider(
          create: (context) => CostBloc(repository: _costRepository),
        ),
        Provider<EmployeeRepository>.value(value: _employeeRepository),
        Provider<SubscriptionRepository>.value(value: _subscriptionRepository),
        Provider<SubscriptionApiService>.value(value: _subscriptionApiService),
        Provider<ImportRepository>.value(value: _importRepository),
        Provider<AccountingRepository>.value(value: _accountingRepository),
        Provider<NotificationRepository>.value(value: _notificationRepository),
      ],
      child: Consumer<LocalizationProvider>(
        builder: (context, localizationProvider, _) {
          return ListenableBuilder(
            listenable: AppRouter.globalAppBarState,
            builder: (context, _) {
              return BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthAuthenticated) {
                    context.read<ReferenceBloc>().add(
                      LoadAllReferencesRequested(),
                    );
                    NotificationContext().refreshUnreadCount();
                    _notificationRealtimeService.connect();
                  }
                  if (state is LogoutSuccess) {
                    // Reset all data-heavy Blocs to clear memory
                    context.read<LocationBloc>().add(const ResetLocations());
                    context.read<OrderBloc>().add(const ResetOrders());
                    context.read<ProductBloc>().add(const ResetProducts());
                    context.read<DebtorBloc>().add(const ResetDebtors());
                    context.read<RevenueBloc>().add(const ResetRevenues());
                    context.read<CostBloc>().add(const ResetCosts());
                    NotificationContext().clear();
                    _notificationRealtimeService.disconnect();

                    // Navigate to login
                    AppRouter.navigateAndClearStack(AppRoutes.login);
                  }
                },
                child: MaterialApp(
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
                  initialRoute: AppRoutes.splash,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
