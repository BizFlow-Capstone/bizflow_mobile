import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../data/product_repository.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';

class BulkAdjustSellingPricePage extends StatefulWidget {
  final String locationId;

  const BulkAdjustSellingPricePage({super.key, required this.locationId});

  @override
  State<BulkAdjustSellingPricePage> createState() =>
      _BulkAdjustSellingPricePageState();
}

class _BulkAdjustSellingPricePageState
    extends State<BulkAdjustSellingPricePage> {
  late final TextEditingController _increaseController;
  late final TextEditingController _decreaseController;

  final Set<int> _selectedSaleItemIds = <int>{};
  final Map<String, bool> _productSelected = <String, bool>{};
  final Map<String, bool> _loadingSaleItems = <String, bool>{};
  final Map<String, List<_SaleItemOption>> _saleItemsByProduct =
      <String, List<_SaleItemOption>>{};

  bool _isSubmitting = false;

  ProductRepository get _repository => context.read<ProductBloc>().repository;
  AppLocalizations get l10n => AppLocalizations.of(context);

  List<ProductEntity> get _products {
    final bloc = context.read<ProductBloc>();
    return bloc.currentProducts;
  }

  @override
  void initState() {
    super.initState();
    _increaseController = TextEditingController();
    _decreaseController = TextEditingController();
  }

  @override
  void dispose() {
    _increaseController.dispose();
    _decreaseController.dispose();
    super.dispose();
  }

  Future<void> _loadSaleItems(String productId) async {
    if (_saleItemsByProduct.containsKey(productId) ||
        (_loadingSaleItems[productId] ?? false)) {
      return;
    }

    setState(() => _loadingSaleItems[productId] = true);
    try {
      final response = await _repository.getProductSaleItems(productId);
      final product = _products.firstWhere((p) => p.id == productId);
      final saleItems = _extractSaleItems(response, product);
      if (!mounted) return;
      setState(() {
        _saleItemsByProduct[productId] = saleItems;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saleItemsByProduct[productId] = [];
      });
    } finally {
      if (mounted) {
        setState(() => _loadingSaleItems[productId] = false);
      }
    }
  }

  List<_SaleItemOption> _extractSaleItems(
    dynamic response,
    ProductEntity product,
  ) {
    List<dynamic> rawItems = const [];

    if (response is List) {
      rawItems = response;
    } else if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        rawItems = data;
      } else if (data is Map<String, dynamic>) {
        if (data['saleItems'] is List) {
          rawItems = data['saleItems'] as List<dynamic>;
        } else if (data['items'] is List) {
          rawItems = data['items'] as List<dynamic>;
        }
      }
    }

    int? parseId(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    double parsePrice(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return rawItems
        .map((item) {
          if (item is! Map<String, dynamic>) return null;
          final saleItemId =
              parseId(item['saleItemId']) ??
              parseId(item['SaleItemId']) ??
              parseId(item['id']) ??
              parseId(item['Id']);
          if (saleItemId == null || saleItemId <= 0) return null;

          final unit = (item['unit'] ?? item['Unit'] ?? product.unit ?? '')
              .toString();
          final quantity = (item['quantity'] ?? item['Quantity'] ?? 1) as num;
          final currentPrice = parsePrice(
            item['price'] ??
                item['Price'] ??
                item['sellingPrice'] ??
                item['SellingPrice'],
          );

          return _SaleItemOption(
            id: saleItemId,
            productId: product.id,
            productName: product.name,
            unit: unit,
            quantity: quantity.toDouble(),
            currentPrice: currentPrice,
          );
        })
        .whereType<_SaleItemOption>()
        .toList();
  }

  void _toggleProductSelection(ProductEntity product, bool checked) async {
    if (checked) {
      await _loadSaleItems(product.id);
    }

    final saleItems =
        _saleItemsByProduct[product.id] ?? const <_SaleItemOption>[];
    setState(() {
      _productSelected[product.id] = checked;
      if (checked) {
        _selectedSaleItemIds.addAll(saleItems.map((e) => e.id));
      } else {
        _selectedSaleItemIds.removeAll(saleItems.map((e) => e.id));
      }
    });
  }

  void _toggleSaleItemSelection(
    String productId,
    int saleItemId,
    bool checked,
  ) {
    setState(() {
      _productSelected[productId] = false;
      if (checked) {
        _selectedSaleItemIds.add(saleItemId);
      } else {
        _selectedSaleItemIds.remove(saleItemId);
      }
    });
  }

  Future<void> _submit() async {
    final increase = (CurrencyFormatter.parse(_increaseController.text) ?? 0)
        .toDouble();
    final decrease = (CurrencyFormatter.parse(_decreaseController.text) ?? 0)
        .toDouble();
    final deltaAmount = increase - decrease;

    if (_selectedSaleItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('product.bulk_adjust.select_sale_items_required'),
          ),
        ),
      );
      return;
    }

    if (deltaAmount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('product.bulk_adjust.delta_required')),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final affectedProductIds = _saleItemsByProduct.entries
          .where(
            (entry) => entry.value.any(
              (saleItem) => _selectedSaleItemIds.contains(saleItem.id),
            ),
          )
          .map((entry) => entry.key)
          .toSet()
          .toList();

      await _repository.bulkAdjustSellingPrice(
        saleItemIds: _selectedSaleItemIds.toList(),
        deltaAmount: deltaAmount,
      );

      if (!mounted) return;

      context.read<ProductBloc>().add(
        ApplyLocalPriceAdjustmentRequested(
          locationId: widget.locationId,
          affectedProductIds: affectedProductIds,
          deltaAmount: deltaAmount,
        ),
      );
      context.read<ProductBloc>().add(
        RefreshProductsRequested(locationId: widget.locationId),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('product.bulk_adjust.success')),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.black,
        ),
        title: Text(
          l10n.translate('product.bulk_adjust.title'),
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('product.bulk_adjust.delta_section'),
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _increaseController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          decoration: InputDecoration(
                            labelText: l10n.translate(
                              'product.bulk_adjust.increase_label',
                            ),
                            hintText: '10,000',
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          controller: _decreaseController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          decoration: InputDecoration(
                            labelText: l10n.translate(
                              'product.bulk_adjust.decrease_label',
                            ),
                            hintText: '0',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _products.isEmpty
                ? Center(
                    child: Text(
                      l10n.translate('common.no_data'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final isLoading = _loadingSaleItems[product.id] ?? false;
                      final saleItems =
                          _saleItemsByProduct[product.id] ??
                          const <_SaleItemOption>[];
                      final parentChecked =
                          _productSelected[product.id] ?? false;

                      return Card(
                        elevation: 0,
                        margin: EdgeInsets.only(bottom: AppSpacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.divider),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide.none,
                          ),
                          collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide.none,
                          ),
                          childrenPadding: EdgeInsets.only(
                            left: AppSpacing.sm,
                            right: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                          ),
                          onExpansionChanged: (expanded) {
                            if (expanded) {
                              _loadSaleItems(product.id);
                            }
                          },
                          leading: Checkbox(
                            value: parentChecked,
                            onChanged: (value) {
                              _toggleProductSelection(product, value ?? false);
                            },
                          ),
                          title: Text(
                            product.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${l10n.translate('product.bulk_adjust.selected_count')}: ${saleItems.where((item) => _selectedSaleItemIds.contains(item.id)).length}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          children: [
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (saleItems.isEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                ),
                                child: Text(
                                  l10n.translate(
                                    'product.bulk_adjust.no_sale_items',
                                  ),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            else
                              ...saleItems.map(
                                (item) => CheckboxListTile(
                                  dense: true,
                                  value: _selectedSaleItemIds.contains(item.id),
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (checked) {
                                    _toggleSaleItemSelection(
                                      product.id,
                                      item.id,
                                      checked ?? false,
                                    );
                                  },
                                  title: Text(
                                    '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${l10n.translate('product.sale_price_label')}: ${CurrencyFormatter.formatVND(item.currentPrice)}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          l10n.translate('product.bulk_adjust.apply_button'),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleItemOption {
  final int id;
  final String productId;
  final String productName;
  final String unit;
  final double quantity;
  final double currentPrice;

  const _SaleItemOption({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.currentPrice,
  });
}
