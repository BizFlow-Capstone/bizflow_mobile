import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../widgets/payment_update_sheet.dart';

/// Mock data models
class _MockDebtOrder {
  final String code;
  final DateTime date;
  final double totalAmount;
  final double paidAmount;

  const _MockDebtOrder({
    required this.code,
    required this.date,
    required this.totalAmount,
    required this.paidAmount,
  });

  double get remaining => totalAmount - paidAmount;
  double get progressPercent =>
      totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;
}

class _MockDebtCustomer {
  final String name;
  final String phone;
  final double totalDebt;
  final double totalPaid;
  final List<_MockDebtOrder> orders;

  const _MockDebtCustomer({
    required this.name,
    required this.phone,
    required this.totalDebt,
    required this.totalPaid,
    required this.orders,
  });

  int get orderCount => orders.length;
  double get remaining => totalDebt - totalPaid;
}

/// Debt List Page - Quản lý công nợ / Khách quen
/// Theo thiết kế SC-ORD-03, SC-ORD-03.1, SC-ORD-03.2
class DebtListPage extends StatefulWidget {
  const DebtListPage({super.key});

  @override
  State<DebtListPage> createState() => _DebtListPageState();
}

class _DebtListPageState extends State<DebtListPage> {
  // Track expanded customer cards
  final Set<int> _expandedCards = {};

  // Mock data
  final List<_MockDebtCustomer> _customers = [
    _MockDebtCustomer(
      name: 'Nguyễn Văn An',
      phone: '0912345678',
      totalDebt: 10800000,
      totalPaid: 5000000,
      orders: [
        _MockDebtOrder(
          code: 'DH-2024-001',
          date: DateTime(2024, 1, 15),
          totalAmount: 5800000,
          paidAmount: 2000000,
        ),
        _MockDebtOrder(
          code: 'DH-2024-005',
          date: DateTime(2024, 1, 10),
          totalAmount: 10000000,
          paidAmount: 3000000,
        ),
      ],
    ),
    _MockDebtCustomer(
      name: 'Trần Thị Bình',
      phone: '0987654321',
      totalDebt: 1700000,
      totalPaid: 1500000,
      orders: [
        _MockDebtOrder(
          code: 'DH-2024-003',
          date: DateTime(2024, 1, 12),
          totalAmount: 1700000,
          paidAmount: 1500000,
        ),
      ],
    ),
    _MockDebtCustomer(
      name: 'Lê Hoàng Cường',
      phone: '0909123456',
      totalDebt: 12500000,
      totalPaid: 0,
      orders: [
        _MockDebtOrder(
          code: 'DH-2024-002',
          date: DateTime(2024, 1, 14),
          totalAmount: 7500000,
          paidAmount: 0,
        ),
        _MockDebtOrder(
          code: 'DH-2024-006',
          date: DateTime(2024, 1, 8),
          totalAmount: 5000000,
          paidAmount: 0,
        ),
      ],
    ),
  ];

  double get _totalDebt => _customers.fold(0.0, (sum, c) => sum + c.remaining);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        title: Text(
          isVietnamese
              ? l10n.translate('debt.title_vi')
              : l10n.translate('debt.title'),
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.black,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Summary Cards
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Total Debt Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.translate('debt.total_debt'),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatVND(_totalDebt),
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Customer Count Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.translate('debt.customer_count'),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_customers.length} ${l10n.translate('debt.customers')}',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Customer List
            Expanded(
              child: _customers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.translate('debt.no_debt'),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.translate('debt.no_debt_sub'),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        bottom: 40,
                      ),
                      itemCount: _customers.length,
                      itemBuilder: (context, index) {
                        return _buildCustomerCard(context, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context);
    final customer = _customers[index];
    final isExpanded = _expandedCards.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Customer Header (always visible)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCards.remove(index);
                } else {
                  _expandedCards.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Name + Expand icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        customer.name,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Phone
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customer.phone,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Debt summary row
                  Row(
                    children: [
                      _buildDebtColumn(
                        l10n.translate('debt.total_owed'),
                        CurrencyFormatter.formatVND(customer.totalDebt),
                        AppColors.danger,
                      ),
                      _buildDebtColumn(
                        l10n.translate('debt.total_paid'),
                        CurrencyFormatter.formatVND(customer.totalPaid),
                        AppColors.success,
                      ),
                      _buildDebtColumn(
                        l10n.translate('debt.order_count'),
                        customer.orderCount.toString(),
                        AppColors.textPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Detail
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('debt.order_details'),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Orders list
                  ...customer.orders.map(
                    (order) => _buildOrderCard(context, order),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Update payment button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaymentSheet(context, customer),
                      icon: const Icon(Icons.payment, size: 18),
                      label: Text(l10n.translate('debt.update_payment')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebtColumn(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, _MockDebtOrder order) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Order code + Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.code,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.translate('debt.total_amount'),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatVND(order.totalAmount),
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Date
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                '${order.date.day.toString().padLeft(2, '0')}/${order.date.month.toString().padLeft(2, '0')}/${order.date.year}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('debt.payment_progress'),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: order.progressPercent / 100,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          order.progressPercent >= 100
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${order.progressPercent.round()}',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Paid + Remaining row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('debt.paid_amount'),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatVND(order.paidAmount),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('debt.remaining'),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatVND(order.remaining),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, _MockDebtCustomer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentUpdateSheet(
        customerName: customer.name,
        customerPhone: customer.phone,
        totalDebt: customer.totalDebt,
        totalPaid: customer.totalPaid,
        remaining: customer.remaining,
        onConfirm: (amount, note) {
          Navigator.pop(context);
          // Mock confirm - update UI
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Thanh toán ${CurrencyFormatter.formatVND(amount)} thành công',
              ),
            ),
          );
        },
      ),
    );
  }
}
