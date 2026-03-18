import 'package:bizflow_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../debt/presentation/pages/debt_detail_page.dart';
import '../../../debt/presentation/pages/debt_list_page.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';

class OrderDebtConfirmationScreen extends StatelessWidget {
  final double totalAmount;
  final double paidAmount;
  final double debtAmount;
  final String customerName;
  final String customerPhone;
  final String? locationName;
  final int? debtorId;

  const OrderDebtConfirmationScreen({
    super.key,
    required this.totalAmount,
    required this.paidAmount,
    required this.debtAmount,
    required this.customerName,
    required this.customerPhone,
    this.locationName,
    this.debtorId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order_create.debt_confirm')),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        bottom: const AppSyncStatusText(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.black,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.translate('order_create.payment_success'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildRow(
                              l10n.translate('order_create.customer_name'),
                              customerName.isEmpty
                                  ? l10n.translate('common.no_data')
                                  : customerName,
                            ),
                            if (customerPhone.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildRow(
                                l10n.translate('order_create.customer_phone'),
                                customerPhone,
                              ),
                            ],
                            if ((locationName ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildRow(
                                l10n.translate(
                                  'order_create.business_location',
                                ),
                                locationName!,
                              ),
                            ],
                            const Divider(height: 24),
                            _buildRow(
                              l10n.translate('order_create.total'),
                              CurrencyFormatter.formatVND(totalAmount),
                            ),
                            const SizedBox(height: 8),
                            _buildRow(
                              l10n.translate('order_create.amount_paid'),
                              CurrencyFormatter.formatVND(paidAmount),
                            ),
                            const Divider(height: 24),
                            _buildRow(
                              l10n.translate('order_create.amount_debt'),
                              CurrencyFormatter.formatVND(debtAmount),
                              isHighlight: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if ((debtorId ?? 0) > 0) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DebtDetailPage(debtorId: debtorId!),
                              ),
                            );
                          },
                          child: Text(l10n.translate('debt.view_detail')),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DebtListPage(),
                            ),
                            ModalRoute.withName('/home'),
                          );
                        },
                        child: Text(
                          l10n.translate('order_create.back_to_list'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 18 : 16,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            color: isHighlight ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }
}
