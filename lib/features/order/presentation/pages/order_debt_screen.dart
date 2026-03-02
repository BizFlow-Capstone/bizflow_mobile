import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import 'order_debt_confirmation_screen.dart';

class OrderDebtScreen extends StatefulWidget {
  final double totalAmount;

  const OrderDebtScreen({Key? key, required this.totalAmount})
    : super(key: key);

  @override
  State<OrderDebtScreen> createState() => _OrderDebtScreenState();
}

class _OrderDebtScreenState extends State<OrderDebtScreen> {
  String _selectedDebtType = 'full'; // 'full' or 'partial'
  final TextEditingController _amountPaidController = TextEditingController();

  @override
  void dispose() {
    _amountPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    double amountPaid = 0;
    if (_selectedDebtType == 'partial' &&
        _amountPaidController.text.isNotEmpty) {
      amountPaid =
          double.tryParse(
            _amountPaidController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
    }

    double debtAmount = widget.totalAmount - amountPaid;
    if (debtAmount < 0) debtAmount = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order_create.debt')),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('order_create.total'),
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    '${widget.totalAmount.toInt()}đ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Debt Types
            Row(
              children: [
                Expanded(
                  child: _buildDebtTypeButton(
                    title: l10n.translate('order_create.debt_type_full'),
                    isSelected: _selectedDebtType == 'full',
                    onTap: () {
                      setState(() {
                        _selectedDebtType = 'full';
                        _amountPaidController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDebtTypeButton(
                    title: l10n.translate('order_create.debt_type_partial'),
                    isSelected: _selectedDebtType == 'partial',
                    onTap: () {
                      setState(() {
                        _selectedDebtType = 'partial';
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_selectedDebtType == 'partial') ...[
              TextField(
                controller: _amountPaidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.translate('order_create.amount_paid'),
                  suffixText: 'đ',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() {}); // trigger rebuild to update remaining debt
                },
              ),
              const SizedBox(height: 24),
            ],

            // Remaining Debt
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('order_create.amount_debt'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${debtAmount.toInt()}đ',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDebtConfirmationScreen(
                        totalAmount: widget.totalAmount,
                        paidAmount: amountPaid,
                        debtAmount: debtAmount,
                      ),
                    ),
                  );
                },
                child: Text(
                  l10n.translate('order_create.proceed_payment'),
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

  Widget _buildDebtTypeButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
