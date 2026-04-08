/// API Endpoints - Tập trung quản lý endpoints
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String googleAuth = '/api/auth/google';
  static const String registerPhone = '/api/auth/register/phone';
  static const String loginPhone = '/api/auth/login/phone';
  static const String loginEmail = '/api/auth/login/email';
  static const String setPassword = '/api/auth/set-password';
  static const String refreshTokenEndpoint = '/api/auth/refresh';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String credentials = '/api/auth/credentials';
  static const String linkPhone = '/api/auth/link/phone';
  static const String linkEmail = '/api/auth/link/email';
  static const String linkGoogle = '/api/auth/link/google';
  static const String firebaseCustomToken = '/api/auth/firebase/custom-token';
  static const String forgotPasswordSendOtp =
      '/api/auth/forgot-password/send-otp';
  static const String forgotPasswordVerifyOtp =
      '/api/auth/forgot-password/verify-otp';
  static const String forgotPasswordReset = '/api/auth/forgot-password/reset';
  static const String authProfile = '/api/auth/profile';
  static const String authProfileAvatar = '/api/auth/profile/avatar';
  static const String authChangePassword = '/api/auth/change-password';
  static const String authDeleteAccount = '/api/auth/delete-account';

  // Legacy aliases (kept for compatibility if any file references them)
  static const String login = '/api/auth/login/email';
  static const String register = '/auth/register';
  static const String logout = '/api/auth/logout';
  static const String refreshToken = '/api/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // User
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String changePassword = '/user/change-password';
  static const String uploadAvatar = '/user/avatar';

  // Home
  static const String dashboard = '/dashboard';
  static const String dashboardSummary = '/api/my-business/dashboard/summary';
  static const String notifications = '/notifications';

  // Location
  static const String myOwnedLocations = '/api/location/me/owned';
  static const String workAtLocations = '/api/location/work-at-locations';
  static const String createLocation = '/api/location/create';
  static const String myEmployees = '/api/my-employee/employees';
  static const String myEmployeesDetails = '/api/my-employee/employees/details';
  static const String searchEmployees = '/api/my-employee/search';
  static const String inviteEmployee = '/api/my-employee/invite';
  static const String employeeInvitations = '/api/my-employee/invitations';
  static String acceptEmployeeInvitation(int hireId) =>
      '/api/my-employee/invitations/$hireId/accept';
  static String rejectEmployeeInvitation(int hireId) =>
      '/api/my-employee/invitations/$hireId/reject';
  static String deleteEmployee(String employeeId) =>
      '/api/my-employee/$employeeId';
  static const String registerDeviceToken =
      '/api/notifications/register-device-token';
  static const String unregisterDeviceToken =
      '/api/notifications/unregister-device-token';
  static const String invitationReplyNotification =
      '/api/my-employee/invitations/reply-notification';

  // Location with ID - use with String interpolation
  static String updateLocationStatus(String id) =>
      '/api/location/me/owned/$id/status';
  static String updateLocation(String id) => '/api/location/me/owned/$id';
  static String addEmployeesToLocation(String id) =>
      '/api/location/$id/employees';
  static String getLocationEmployees(String id) =>
      '/api/location/me/owned/$id/employees';
  static String deleteLocation(String id) => '/api/location/me/owned/$id';
  static String removeEmployeeFromLocation(
    String locationId,
    String employeeId,
  ) => '/api/location/$locationId/employees/$employeeId';

  // Order/Invoice
  static const String orders = '/api/my-business/accounting/orders';
  static const String createOrder = '/api/my-business/accounting/orders';

  // Order with ID - use with String interpolation
  static String getOrder(String id) => '/api/my-business/accounting/orders/$id';
  static String updateOrder(String id) =>
      '/api/my-business/accounting/orders/$id';
  static String completeOrder(String id) =>
      '/api/my-business/accounting/orders/$id/complete';
  static String cancelOrder(String id) =>
      '/api/my-business/accounting/orders/$id/cancel';

  // Revenue
  static const String revenues = '/api/my-business/accounting/revenues';
  static const String createManualRevenue =
      '/api/my-business/accounting/revenues/manual';
  static String updateManualRevenue(String id) =>
      '/api/my-business/accounting/revenues/$id';
  static String deleteManualRevenue(String id) =>
      '/api/my-business/accounting/revenues/$id';

  // Cost
  static const String costs = '/api/my-business/accounting/costs';
  static const String createManualCost =
      '/api/my-business/accounting/costs/manual';
  static String updateManualCost(String id) =>
      '/api/my-business/accounting/costs/$id';
  static String deleteManualCost(String id) =>
      '/api/my-business/accounting/costs/$id';

  // Product
  static const String products = '/api/my-business/products';
  static const String createProduct = '/api/my-business/product';

  // Product with ID - use with String interpolation
  static String getProductDetail(String productId) =>
      '/api/my-business/product/$productId';
  static String updateProduct(String productId) =>
      '/api/my-business/product/$productId';
  static String deleteProduct(String productId) =>
      '/api/my-business/product/$productId';
  static String updateProductStatus(String productId) =>
      '/api/my-business/product/$productId/status';
  static String getProductSaleItems(String productId) =>
      '/api/my-business/product/$productId/sale-items';
  static String getProductCostPriceHistory(String productId) =>
      '/api/my-business/product/$productId/cost-price-history';
  static String adjustProductStock(String productId) =>
      '/api/my-business/product/$productId/stock';
  static const String bulkAdjustSellingPrice =
      '/api/my-business/products/sale-items/selling-price';

  // Business Types
  static const String businessTypes = '/api/business-types';

  // Add more endpoints here...
  // Import
  static const String imports = '/api/my-business/accounting/imports';
  static const String createImport = '/api/my-business/accounting/import';
  static const String importTemplate =
      '/api/my-business/accounting/import-template';

  // Import with ID - use with String interpolation
  static String getImportDetail(String id) =>
      '/api/my-business/accounting/import/$id';
  static String updateImport(String id) =>
      '/api/my-business/accounting/import/$id';
  static String confirmImport(String id) =>
      '/api/my-business/accounting/import/$id';
  static String deleteImport(String id) =>
      '/api/my-business/accounting/import/$id';

  // Debtor
  static const String debtors = '/api/my-business/debtors';
  static String debtorDetail(String debtorId) =>
      '/api/my-business/debtors/$debtorId';
  static String debtorPayments(String debtorId) =>
      '/api/my-business/debtors/$debtorId/payments';
  static String debtorStatus(String debtorId) =>
      '/api/my-business/debtors/$debtorId/status';
  static String activeDebtorsByLocation(String locationId) =>
      '/api/my-business/debtors/locations/$locationId';

  // Accounting Period
  static String accountingPeriods(String locationId) =>
      '/api/locations/$locationId/accounting/periods';
  static String accountingPeriodsCustom(String locationId) =>
      '/api/locations/$locationId/accounting/periods/custom';
  static String accountingPeriodsOpeningBalanceSuggestion(String locationId) =>
      '/api/locations/$locationId/accounting/periods/opening-balance-suggestion';
  static String accountingPeriodDetail(String locationId, String periodId) =>
      '/api/locations/$locationId/accounting/periods/$periodId';
  static String accountingPeriodFinalize(String locationId, String periodId) =>
      '/api/locations/$locationId/accounting/periods/$periodId/finalize';
  static String accountingPeriodReopen(String locationId, String periodId) =>
      '/api/locations/$locationId/accounting/periods/$periodId/reopen';
  static String accountingPeriodAuditLogs(String locationId, String periodId) =>
      '/api/locations/$locationId/accounting/periods/$periodId/audit-logs';

  // Accounting Books
  static String accountingBooks(String locationId) =>
      '/api/locations/$locationId/accounting/books';
  static String createAccountingBooks(String locationId) =>
      '/api/locations/$locationId/accounting/books';
  static String accountingBooksDetail(String locationId, String bookId) =>
      '/api/locations/$locationId/accounting/books/$bookId';
  static String accountingBookRows(String locationId, String bookId) =>
      '/api/locations/$locationId/accounting/books/$bookId/rows';
  static String accountingBookSections(String locationId, String bookId) =>
      '/api/locations/$locationId/accounting/books/$bookId/sections';

  // AI (via Backend API)
  static const String aiDraftRevenue = '/api/my-business/ai/draft-revenue';
  static const String aiDraftCost = '/api/my-business/ai/draft-cost';
  static const String aiDraftOrder = '/api/my-business/ai/draft-order';
  static const String aiOcrPurchaseInvoice =
      '/api/my-business/ai/ocr/purchase-invoice';

  // GL Entries
  static const String glEntries = '/api/my-business/accounting/gl-entries';

  // Subscription & Settings
  static const String adminFeatures = '/api/admin/features';
  static const String subscriptionPlans = '/api/subscription-plans';
  static const String currentSubscription = '/api/subscriptions/current';
  static const String checkoutSubscription = '/api/subscriptions/checkout';
  static const String subscriptionTransactions =
      '/api/subscriptions/transactions';
}
