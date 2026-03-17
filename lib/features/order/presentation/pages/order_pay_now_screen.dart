import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';

class OrderPayNowScreen extends StatefulWidget {
  final double totalAmount;

  const OrderPayNowScreen({Key? key, required this.totalAmount})
    : super(key: key);

  @override
  State<OrderPayNowScreen> createState() => _OrderPayNowScreenState();
}

class _OrderPayNowScreenState extends State<OrderPayNowScreen> {
  String _selectedMethod = 'cash'; // 'cash' or 'transfer'

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order_create.pay_now')),
        elevation: 0,
        bottom: const AppSyncStatusText(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.translate('order_create.total'),
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.totalAmount.toInt()}đ',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Payment Methods
            Row(
              children: [
                Expanded(
                  child: _buildMethodButton(
                    icon: Icons.money,
                    title: l10n.translate('order_create.pay_method_cash'),
                    isSelected: _selectedMethod == 'cash',
                    onTap: () {
                      setState(() {
                        _selectedMethod = 'cash';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMethodButton(
                    icon: Icons.qr_code,
                    title: l10n.translate('order_create.pay_method_transfer'),
                    isSelected: _selectedMethod == 'transfer',
                    onTap: () {
                      setState(() {
                        _selectedMethod = 'transfer';
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_selectedMethod == 'transfer')
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2, size: 150),
                    const SizedBox(height: 16),
                    const Text(
                      "Ngân hàng Vietcombank\nSTK: 0123456789\nNGUYEN VAN A",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                onPressed: () {
                  // Show success dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Thành công"),
                      content: const Text(
                        "Đã thanh toán và tạo đơn hàng thành công!",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // close dialog
                            Navigator.popUntil(
                              context,
                              ModalRoute.withName('/home'),
                            );
                          },
                          child: const Text("Về trang chủ"),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  l10n.translate('order_create.proceed_payment'),
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodButton({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.green : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
