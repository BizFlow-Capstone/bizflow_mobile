import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import 'order_debt_screen.dart';
import 'order_pay_now_screen.dart';

class OrderPaymentOptionScreen extends StatelessWidget {
  final double totalAmount;

  const OrderPaymentOptionScreen({Key? key, required this.totalAmount})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order_create.payment_method_title')),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              l10n.translate('order_create.total'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '${totalAmount.toInt()}đ',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 48),

            // Debt option
            _buildOptionCard(
              context: context,
              icon: Icons.account_balance_wallet_outlined,
              title: l10n.translate('order_create.debt'),
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDebtScreen(totalAmount: totalAmount),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Pay Now option
            _buildOptionCard(
              context: context,
              icon: Icons.payments_outlined,
              title: l10n.translate('order_create.pay_now'),
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderPayNowScreen(totalAmount: totalAmount),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
