import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

class ProductFilterSortDialog extends StatefulWidget {
  final String? initialStatus;
  final String? initialBusinessTypeId;
  final String? initialSort;
  final List<Map<String, String>> businessTypeOptions;

  const ProductFilterSortDialog({
    super.key,
    this.initialStatus,
    this.initialBusinessTypeId,
    this.initialSort,
    required this.businessTypeOptions,
  });

  @override
  State<ProductFilterSortDialog> createState() =>
      _ProductFilterSortDialogState();
}

class _ProductFilterSortDialogState extends State<ProductFilterSortDialog> {
  String? _selectedStatus;
  String? _selectedBusinessTypeId;
  String? _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _selectedBusinessTypeId = widget.initialBusinessTypeId;
    _selectedSort = widget.initialSort;
  }

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

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
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
                      // Instantly clear and apply
                      Navigator.pop(context, {
                        'status': null,
                        'businessTypeId': null,
                        'sort': null,
                      });
                    },
                    child: Text(l10n.translate('product.reset_filters')),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.translate('product.sort_title'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: sortOptions.map((option) {
                  return ChoiceChip(
                    label: Text(option['label']!),
                    selected: _selectedSort == option['value'],
                    onSelected: (selected) {
                      setState(
                        () => _selectedSort = selected ? option['value'] : null,
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.translate('product.status'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
                      setState(
                        () => _selectedStatus = selected ? 'active' : null,
                      );
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
              if (widget.businessTypeOptions.isNotEmpty) ...[
                Text(
                  l10n.translate('product.business_type'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(l10n.translate('product.filter_all')),
                      selected: _selectedBusinessTypeId == null,
                      onSelected: (selected) {
                        setState(() => _selectedBusinessTypeId = null);
                      },
                    ),
                    ...widget.businessTypeOptions.map((businessType) {
                      final businessTypeId = businessType['id'];
                      final businessTypeName = businessType['name'] ?? '';
                      return FilterChip(
                        label: Text(businessTypeName),
                        selected: _selectedBusinessTypeId == businessTypeId,
                        onSelected: (selected) {
                          setState(
                            () => _selectedBusinessTypeId = selected
                                ? businessTypeId
                                : null,
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
                      'businessTypeId': _selectedBusinessTypeId,
                      'sort': _selectedSort,
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
        ),
      ),
    );
  }
}
