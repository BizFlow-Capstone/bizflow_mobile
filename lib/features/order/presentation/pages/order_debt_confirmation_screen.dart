import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';

class OrderDebtConfirmationScreen extends StatelessWidget {
  final double totalAmount;
  final double paidAmount;
  final double debtAmount;

  const OrderDebtConfirmationScreen({
    Key? key,
    required this.totalAmount,
    required this.paidAmount,
    required this.debtAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order_create.debt_confirm')),
        elevation: 0,
        bottom: const AppSyncStatusText(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              "Tạo đơn hàng thành công",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      "Tạp hóa chị Nga",
                    ),
                    const Divider(height: 24),
                    _buildRow(
                      l10n.translate('order_create.total'),
                      '${totalAmount.toInt()}đ',
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      l10n.translate('order_create.amount_paid'),
                      '${paidAmount.toInt()}đ',
                    ),
                    const Divider(height: 24),
                    _buildRow(
                      l10n.translate('order_create.amount_debt'),
                      '${debtAmount.toInt()}đ',
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.popUntil(context, ModalRoute.withName('/home'));
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
