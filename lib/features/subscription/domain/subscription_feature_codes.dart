class SubscriptionFeatureCodes {
  SubscriptionFeatureCodes._();

  // Legacy codes – keep for backward compatibility with existing usages.
  static const String reportExport = 'REPORT_EXPORT';
  static const String manualRevenue = 'MANUAL_REVENUE';
  static const String orderManagement = 'ORDER_MANAGEMENT';
  static const String productManagement = 'PRODUCT_MANAGEMENT';
  static const String inventoryImport = 'INVENTORY_IMPORT';
  static const String debtorManagement = 'DEBTOR_MANAGEMENT';
  static const String employeeManagement = 'EMPLOYEE_MANAGEMENT';

  // Codes aligned with backend feature-code configuration (Task 39).
  static const String locations = 'LOCATIONS';
  static const String employees = 'EMPLOYEES';
  static const String products = 'PRODUCTS';
  static const String orders = 'ORDERS';
  static const String imports = 'IMPORTS';
  static const String reports = 'REPORTS';
  static const String debtManagement = 'DEBT_MGMT';
  static const String export = 'EXPORT';
  static const String ai = 'AI';
}
