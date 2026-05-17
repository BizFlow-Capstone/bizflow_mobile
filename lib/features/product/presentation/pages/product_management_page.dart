import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/services/permission_service.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../data/models/business_type_model.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/product_fab_menu_widget.dart';
import '../../../../shared/widgets/app_barcode_scanner.dart';
import '../../../../shared/cache/sync_status_controller.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/utils/action_guard.dart';
import '../../../../shared/utils/formatters.dart';

import '../../domain/entities/product_entity.dart';
import '../widgets/product_filter_dialog.dart';
import 'add_product_page.dart';
import 'bulk_adjust_selling_price_page.dart';
import 'import_history_page.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';

/// Product Management by Location Page
/// SC-INV-03.1: Quản lý sản phẩm theo địa điểm kinh doanh
class ProductManagementPage extends StatefulWidget {
  final String locationId;
  final String locationName;
  final String locationAddress;

  const ProductManagementPage({
    super.key,
    required this.locationId,
    required this.locationName,
    required this.locationAddress,
  });

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  bool _showFabMenu = false;
  List<BusinessTypeDto> _businessTypes = [];
  String? _lastApiMessage;
  Timer? _searchDebounce;
  final ActionGuard _openFabActionGuard = ActionGuard();

  @override
  void initState() {
    super.initState();
    SyncStatusController().setManualRefreshCallback(_refreshFromSyncBar);
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    context.read<ProductBloc>().add(const LoadBusinessTypesRequested());
    _loadProducts();
  }

  void _refreshFromSyncBar() {
    context.read<ProductBloc>().add(
      RefreshProductsRequested(locationId: widget.locationId),
    );
  }

  @override
  void dispose() {
    SyncStatusController().setManualRefreshCallback(null);
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ProductBloc>().add(
        LoadMoreProductsRequested(locationId: widget.locationId),
      );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _loadProducts() {
    context.read<ProductBloc>().add(
      LoadProductsByLocationRequested(locationId: widget.locationId),
    );
  }

  void _searchProducts(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<ProductBloc>().add(
          SearchProductsRequested(locationId: widget.locationId, query: query),
        );
      }
    });
  }

  Future<void> _openAddProductPage() async {
    await _openFabActionGuard.run(() async {
      _toggleFabMenu();
      final allowed = await SubscriptionFeatureGuard.ensureAllowed(
        context,
        featureCode: SubscriptionFeatureCodes.products,
      );
      if (!allowed || !mounted) return;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AddProductPage(locationId: widget.locationId),
        ),
      );
      if (result == true && mounted) {
        _loadProducts();
      }
    });
  }

  Future<void> _openImportHistoryPage() async {
    await _openFabActionGuard.run(() async {
      _toggleFabMenu();
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const ImportHistoryPage()),
      );
      if (result == true && mounted) {
        _loadProducts();
      }
    });
  }

  void _toggleFabMenu() {
    setState(() {
      _showFabMenu = !_showFabMenu;
    });
  }

  void _openFilterDialog(ProductsLoaded state) async {
    final businessTypeOptions = _businessTypes
        .map((type) => {'id': type.businessTypeId, 'name': type.name})
        .toList();

    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductFilterSortDialog(
        initialStatus: state.filterStatus,
        initialBusinessTypeId: state.filterBusinessTypeId,
        initialSort: state.sortBy,
        businessTypeOptions: businessTypeOptions,
      ),
    );

    if (result != null && mounted) {
      if (result['status'] != state.filterStatus ||
          result['businessTypeId'] != state.filterBusinessTypeId) {
        context.read<ProductBloc>().add(
          FilterProductsRequested(
            locationId: widget.locationId,
            status: result['status'],
            businessTypeId: result['businessTypeId'],
          ),
        );
      }
      if (result['sort'] != state.sortBy) {
        context.read<ProductBloc>().add(
          SortProductsRequested(
            locationId: widget.locationId,
            sortBy: result['sort'] ?? '',
          ),
        );
      }
    }
  }

  Future<void> _showQuickAdjustStockDialog(ProductEntity product) async {
    final l10n = AppLocalizations.of(context);
    final productBloc = context.read<ProductBloc>();

    final formData = await showDialog<_QuickAdjustStockFormData>(
      context: context,
      builder: (dialogContext) => _QuickAdjustStockDialog(
        initialStock: product.quantity,
        initialCostPrice: product.costPrice,
      ),
    );

    if (!mounted || formData == null) return;

    try {
      await productBloc.repository.adjustProductStock(
        productId: product.id,
        stock: formData.stock,
        memo: formData.memo,
        costPrice: formData.costPrice,
      );

      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.translate('product.stock_adjust.success'),
        type: AppSnackBarType.success,
      );

      if (mounted) {
        productBloc.add(
          RefreshProductsRequested(locationId: widget.locationId),
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: ApiErrorMessageParser.parse(e),
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canManageProducts = PermissionService.canEditProduct(
      context.watch<BusinessContext>().isOwner,
    );
    final canAdjustStock = PermissionService.canAdjustStock(
      context.watch<BusinessContext>().isOwner,
    );

    return Scaffold(
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.locationName,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.locationAddress,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Consumer<BusinessContext>(
            builder: (context, bCtx, _) {
              final isOwner = PermissionService.canEditProduct(bCtx.isOwner);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOwner) ...[
                    IconButton(
                      icon: const Icon(Icons.price_change_outlined),
                      tooltip: l10n.translate('product.bulk_adjust.title'),
                      color: AppColors.textPrimary,
                      onPressed: () {
                        Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BulkAdjustSellingPricePage(
                              locationId: widget.locationId,
                            ),
                          ),
                        ).then((updated) {
                          if (updated == true && mounted) {
                            context.read<ProductBloc>().add(
                              RefreshProductsRequested(
                                locationId: widget.locationId,
                              ),
                            );
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.history),
                      tooltip: 'Lịch sử nhập kho',
                      color: AppColors.textPrimary,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ImportHistoryPage(),
                          ),
                        ).then((result) {
                          if (result == true && mounted) {
                            _loadProducts();
                          }
                        });
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ],
        bottom: const AppSyncStatusText(),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchProducts,
                    decoration: InputDecoration(
                      hintText: l10n.translate('common.search_products'),
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDisabled,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.secondary),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: AppSpacing.md,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                                _searchProducts('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                // Filter Button
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      final state = context.read<ProductBloc>().state;
                      if (state is ProductsLoaded) {
                        _openFilterDialog(state);
                      }
                    },
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                // Barcode Scanner Button
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final res = await AppBarcodeScanner.scan(context);
                      if (res != null && mounted) {
                        setState(() {
                          _searchController.text = res;
                        });
                        if (mounted) {
                          _searchProducts(res);
                        }
                      }
                    },
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Active Filters Indicator
          BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductsLoaded &&
                  (state.filterStatus != null ||
                      state.filterBusinessTypeId != null ||
                      state.sortBy != null)) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.translate('product.active_filters'),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          context.read<ProductBloc>().add(
                            ClearFiltersRequested(
                              locationId: widget.locationId,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.translate('product.clear_filters'),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Products List
          Expanded(
            child: BlocConsumer<ProductBloc, ProductState>(
              listener: (context, state) {
                if (state is BusinessTypesLoaded) {
                  setState(() {
                    _businessTypes = state.businessTypes;
                  });
                } else if (state is ProductFailure) {
                  AppSnackBar.show(
                    context,
                    message: state.message,
                    type: AppSnackBarType.error,
                  );
                } else if (state is ProductDeleteSuccess) {
                  // Reload the product list after a successful deletion
                  context.read<ProductBloc>().add(
                    LoadProductsByLocationRequested(
                      locationId: widget.locationId,
                    ),
                  );
                  AppSnackBar.show(
                    context,
                    message: l10n.translate('product.delete_success'),
                    type: AppSnackBarType.success,
                  );
                } else if (state is ProductsLoaded &&
                    state.apiMessage != null &&
                    state.apiMessage!.isNotEmpty) {
                  if (_lastApiMessage != state.apiMessage) {
                    _lastApiMessage = state.apiMessage;
                    AppSnackBar.show(
                      context,
                      message: state.apiMessage!,
                      type: AppSnackBarType.info,
                      duration: const Duration(seconds: 2),
                    );
                  }
                }
              },
              builder: (context, state) {
                if (state is ProductLoading ||
                    state is ProductDeleteInProgress) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondary,
                    ),
                  );
                } else if (state is ProductsLoaded) {
                  return _buildProductList(
                    state.products,
                    state.hasReachedMax,
                    canManageProducts,
                    canAdjustStock,
                  );
                }

                // If state is BusinessTypesLoaded or any other non-loading state,
                // fallback to the current cached list in the Bloc
                final currentProducts = context
                    .read<ProductBloc>()
                    .currentProducts;
                if (currentProducts.isNotEmpty) {
                  return _buildProductList(
                    currentProducts,
                    true,
                    canManageProducts,
                    canAdjustStock,
                  );
                }

                return _buildEmptyState(l10n);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canManageProducts
          ? Consumer<BusinessContext>(
              builder: (context, bCtx, _) {
                if (!PermissionService.canCreateProduct(bCtx.isOwner)) {
                  return const SizedBox.shrink();
                }
                return ProductFabMenuWidget(
                  isOpen: _showFabMenu,
                  onToggle: _toggleFabMenu,
                  onAddProduct: _openAddProductPage,
                  onImportInventory: _openImportHistoryPage,
                );
              },
            )
          : null,
    );
  }

  Widget _buildProductList(
    List<ProductEntity> products,
    bool hasReachedMax,
    bool canManageProducts,
    bool canAdjustStock,
  ) {
    if (products.isEmpty) {
      return _buildEmptyState(AppLocalizations.of(context));
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProductBloc>().add(
          RefreshProductsRequested(locationId: widget.locationId),
        );
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.sm,
          bottom: 120,
        ),
        itemCount: hasReachedMax ? products.length : products.length + 1,
        itemBuilder: (context, index) {
          if (index >= products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final product = products[index];
          return ProductCardWidget(
            product: product,
            locationId: widget.locationId,
            canManageActions: canManageProducts,
            onQuickAdjustStock: canAdjustStock && product.trackInventory
                ? () => _showQuickAdjustStockDialog(product)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            l10n.translate('location.manage_products'),
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            l10n.translate('common.no_data'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAdjustStockFormData {
  final double stock;
  final String memo;
  final double? costPrice;

  const _QuickAdjustStockFormData({
    required this.stock,
    required this.memo,
    required this.costPrice,
  });
}

class _QuickAdjustStockDialog extends StatefulWidget {
  final double initialStock;
  final double? initialCostPrice;

  const _QuickAdjustStockDialog({
    required this.initialStock,
    required this.initialCostPrice,
  });

  @override
  State<_QuickAdjustStockDialog> createState() =>
      _QuickAdjustStockDialogState();
}

class _QuickAdjustStockDialogState extends State<_QuickAdjustStockDialog> {
  late final TextEditingController _stockController;
  late final TextEditingController _memoController;
  late final TextEditingController _costPriceController;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(
      text: widget.initialStock.toString(),
    );
    _memoController = TextEditingController();
    _costPriceController = TextEditingController(
      text: widget.initialCostPrice != null
          ? CurrencyFormatter.formatNumber(widget.initialCostPrice!)
          : '',
    );
  }

  @override
  void dispose() {
    _stockController.dispose();
    _memoController.dispose();
    _costPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.translate('product.stock_adjust.title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _stockController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: AppInputFormatters.withSqlInjectionGuard(
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
              ),
              decoration: InputDecoration(
                labelText: l10n.translate('product.stock_adjust.stock'),
              ),
            ),
            AppSpacing.gapVerticalMd,
            TextField(
              controller: _costPriceController,
              keyboardType: TextInputType.number,
              inputFormatters: AppInputFormatters.withSqlInjectionGuard(
                inputFormatters: [CurrencyInputFormatter()],
              ),
              decoration: InputDecoration(
                labelText: l10n.translate('product.stock_adjust.cost_price'),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            TextField(
              controller: _memoController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.translate('product.stock_adjust.memo'),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: l10n.translate(
                        'product.stock_adjust.stock_note_prefix',
                      ),
                    ),
                    TextSpan(
                      text: l10n.translate(
                        'product.stock_adjust.stock_note_payment_method',
                      ),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.translate('common.cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            final stock = double.tryParse(
              _stockController.text.trim().replaceAll(',', '.'),
            );
            final parsedCostPrice = CurrencyFormatter.parse(
              _costPriceController.text,
            );

            if (stock == null || stock < 0) {
              AppSnackBar.show(
                context,
                message: l10n.translate('product.stock_adjust.invalid_stock'),
                type: AppSnackBarType.error,
              );
              return;
            }

            Navigator.pop(
              context,
              _QuickAdjustStockFormData(
                stock: stock,
                memo: _memoController.text,
                costPrice: parsedCostPrice?.toDouble(),
              ),
            );
          },
          child: Text(l10n.translate('product.stock_adjust.apply_button')),
        ),
      ],
    );
  }
}
