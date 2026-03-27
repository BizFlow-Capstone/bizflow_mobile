/// Permission Service — Centralized role-based permission checks
///
/// Usage:
///   final isOwner = context.read<BusinessContext>().isOwner;
///   if (PermissionService.canManageProducts(isOwner)) { ... }
class PermissionService {
  PermissionService._();

  // ── Business Location ──────────────────────────────────────────────
  static bool canCreateLocation(bool isOwner) => isOwner;
  static bool canEditLocation(bool isOwner) => isOwner;
  static bool canDeleteLocation(bool isOwner) => isOwner;

  // ── Employee Management ────────────────────────────────────────────
  static bool canManageEmployees(bool isOwner) => isOwner;

  // ── Product & Inventory ────────────────────────────────────────────
  static bool canCreateProduct(bool isOwner) => isOwner;
  static bool canEditProduct(bool isOwner) => isOwner;
  static bool canDeleteProduct(bool isOwner) => isOwner;
  static bool canManageSaleItems(bool isOwner) => isOwner;
  static bool canManagePrices(bool isOwner) => isOwner;
  static bool canImportStock(bool isOwner) => isOwner;
  static bool canViewStockHistory(bool isOwner) => isOwner;
  static bool canAdjustStock(bool isOwner) => isOwner;
  // Both roles can view products & stock
  static bool canViewProducts(bool isOwner) => true;
  static bool canViewStock(bool isOwner) => true;

  // ── Order Management ───────────────────────────────────────────────
  // Both roles can create orders and view all orders
  static bool canCreateOrder(bool isOwner) => true;
  static bool canViewOrders(bool isOwner) => true;
  static bool canCompleteOrder(bool isOwner) => true;
  // Employee can only edit/cancel their OWN orders (check createdByUserId at runtime)
  static bool canEditAnyOrder(bool isOwner) => isOwner;
  static bool canCancelAnyOrder(bool isOwner) => isOwner;

  // ── Debt Management (Công nợ) ──────────────────────────────────────
  static bool canCreateDebtor(bool isOwner) => isOwner;
  static bool canEditDebtor(bool isOwner) => isOwner;
  static bool canDeleteDebtor(bool isOwner) => isOwner;
  // Both roles can view debtors and record payments
  static bool canViewDebtors(bool isOwner) => true;
  static bool canRecordDebtPayment(bool isOwner) => true;

  // ── Reports & Analytics ────────────────────────────────────────────
  static bool canViewReports(bool isOwner) => isOwner;
  static bool canViewDashboard(bool isOwner) => isOwner;
  static bool canExportAccounting(bool isOwner) => isOwner;

  // ── Accounting / GL / Cost / Revenue write ops ─────────────────────
  static bool canWriteAccounting(bool isOwner) => isOwner;

  // ── Invoice Templates ──────────────────────────────────────────────
  static bool canManageInvoiceTemplates(bool isOwner) => isOwner;
}
