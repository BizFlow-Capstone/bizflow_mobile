import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

class ProductSortDialog extends StatelessWidget {
  final String? currentSort;

  const ProductSortDialog({super.key, this.currentSort});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final sortOptions = [
      {'label': l10n.translate('product.sort_name_asc'), 'value': 'name'},
      {'label': l10n.translate('product.sort_price_asc'), 'value': 'price'},
      {'label': l10n.translate('product.sort_stock_asc'), 'value': 'stock'},
      {'label': l10n.translate('product.sort_name_desc'), 'value': 'name_desc'},
      {
        'label': l10n.translate('product.sort_price_desc'),
        'value': 'price_desc',
      },
      {
        'label': l10n.translate('product.sort_stock_desc'),
        'value': 'stock_desc',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.translate('product.sort_title'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          ...sortOptions.map((option) {
            final isSelected = currentSort == option['value'];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Text(
                option['label']!,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                Navigator.pop(context, option['value']);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
