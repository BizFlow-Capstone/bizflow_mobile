/// API Endpoints - Tập trung quản lý endpoints
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // User
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String changePassword = '/user/change-password';
  static const String uploadAvatar = '/user/avatar';

  // Home
  static const String dashboard = '/dashboard';
  static const String notifications = '/notifications';

  // Location
  static const String myOwnedLocations = '/api/location/me/owned';
  static const String workAtLocations = '/api/location/work-at-locations';
  static const String createLocation = '/api/location/create';
  static const String myEmployees = '/api/my-employee/employees';

  // Location with ID - use with String interpolation
  static String updateLocationStatus(String id) =>
      '/api/location/me/owned/$id/status';
  static String updateLocation(String id) => '/api/location/me/owned/$id';
  static String addEmployeesToLocation(String id) =>
      '/api/location/$id/employees';
  static String getLocationEmployees(String id) =>
      '/api/location/me/owned/$id/employees';

  // Order/Invoice
  static const String orders = '/api/order/my-orders';
  static const String draftOrders = '/api/order/drafts';
  static const String createOrder = '/api/order/create';

  // Order with ID - use with String interpolation
  static String getOrder(String id) => '/api/order/$id';
  static String updateOrder(String id) => '/api/order/$id';
  static String publishOrder(String id) => '/api/order/$id/publish';
  static String cancelOrder(String id) => '/api/order/$id/cancel';

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

  // Add more endpoints here...
}
