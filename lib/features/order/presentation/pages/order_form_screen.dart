import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import 'order_payment_option_screen.dart';

class OrderFormScreen extends StatefulWidget {
  final String inputType; // 'audio', 'voice', or 'manual'

  const OrderFormScreen({Key? key, required this.inputType}) : super(key: key);

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  // Mock data for the form
  final String _currentLocationName = "Shinkiri Tech Store - HCM";

  // Example dummy products obtained from voice/audio processing
  final List<Map<String, dynamic>> _mockProducts = [
    {"name": "iPhone 15 Pro Max", "price": 30000000.0, "quantity": 1},
    {"name": "Ốp lưng iPhone", "price": 150000.0, "quantity": 1},
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    double subTotal = _mockProducts.fold(
      0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );
    double tax = subTotal * 0.1;
    double total = subTotal + tax;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order_create.form_title')),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: Colors.black,
          ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () {
              // Save as draft and pop to home
              Navigator.popUntil(context, ModalRoute.withName('/home'));
              // In real app, we'd trigger Bloc action here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.translate('order_create.save_draft')),
                ),
              );
            },
            child: Text(
              l10n.translate('order_create.save_draft'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Business Location
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.store, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.translate('order_create.business_location'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[800],
                              ),
                            ),
                            Text(
                              _currentLocationName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Customer Info Section
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: l10n.translate(
                              'order_create.customer_name',
                            ),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          initialValue: "Tạp hóa chị Nga",
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: l10n.translate(
                              'order_create.customer_phone',
                            ),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          initialValue: "0901234567",
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Product Info Section
                Text(
                  l10n.translate('order_create.form_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                ..._mockProducts.map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(p['name']),
                    subtitle: Text('${p['price'].toInt()}đ x ${p['quantity']}'),
                    trailing: Text(
                      '${(p['price'] * p['quantity']).toInt()}đ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: Text(l10n.translate('order_create.add_product')),
                ),

                const SizedBox(height: 24),

                // Summary Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.translate('order_create.sub_total')),
                    Text('${subTotal.toInt()}đ'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.translate('order_create.tax')),
                    Text('${tax.toInt()}đ'),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.translate('order_create.total'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${total.toInt()}đ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderPaymentOptionScreen(totalAmount: total),
                ),
              );
            },
            child: Text(
              l10n.translate('order_create.proceed_payment'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
