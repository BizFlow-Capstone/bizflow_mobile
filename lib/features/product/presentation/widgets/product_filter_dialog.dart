import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

class ProductFilterDialog extends StatefulWidget {
  final String? initialStatus;
  final String? initialCategory;
  final List<String> categories;

  const ProductFilterDialog({
    super.key,
    this.initialStatus,
    this.initialCategory,
    required this.categories,
  });

  @override
  State<ProductFilterDialog> createState() => _ProductFilterDialogState();
}

class _ProductFilterDialogState extends State<ProductFilterDialog> {
  String? _selectedStatus;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('product.filter_title'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedStatus = null;
                    _selectedCategory = null;
                  });
                },
                child: Text(l10n.translate('product.reset_filters')),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.translate('product.status'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text(l10n.translate('product.filter_all')),
                selected: _selectedStatus == null,
                onSelected: (selected) {
                  setState(() => _selectedStatus = null);
                },
              ),
              FilterChip(
                label: Text(l10n.translate('product.active')),
                selected: _selectedStatus == 'active',
                onSelected: (selected) {
                  setState(() => _selectedStatus = selected ? 'active' : null);
                },
              ),
              FilterChip(
                label: Text(l10n.translate('product.inactive')),
                selected: _selectedStatus == 'inactive',
                onSelected: (selected) {
                  setState(
                    () => _selectedStatus = selected ? 'inactive' : null,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.categories.isNotEmpty) ...[
            Text(
              l10n.translate('product.category'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: Text(l10n.translate('product.filter_all')),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = null);
                  },
                ),
                ...widget.categories.map((category) {
                  return FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(
                        () => _selectedCategory = selected ? category : null,
                      );
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 32),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'status': _selectedStatus,
                  'category': _selectedCategory,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.translate('product.apply_filters')),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
