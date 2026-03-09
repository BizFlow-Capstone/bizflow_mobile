import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/product_fab_menu_widget.dart';
import '../../../../shared/widgets/app_barcode_scanner.dart';
import '../widgets/product_filter_dialog.dart';
import 'add_product_page.dart';
import 'import_history_page.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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
    context.read<ProductBloc>().add(
      SearchProductsRequested(locationId: widget.locationId, query: query),
    );
  }

  void _openAddProductPage() {
    _toggleFabMenu();
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(locationId: widget.locationId),
      ),
    ).then((result) {
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
    final categories = state.products
        .map((p) => p.category)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductFilterSortDialog(
        initialStatus: state.filterStatus,
        initialCategory: state.filterCategory,
        initialSort: state.sortBy,
        categories: categories,
      ),
    );

    if (result != null && mounted) {
      if (result['status'] != state.filterStatus ||
          result['category'] != state.filterCategory) {
        context.read<ProductBloc>().add(
          FilterProductsRequested(
            locationId: widget.locationId,
            status: result['status'],
            category: result['category'],
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                color: AppColors.textPrimary,
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
                // Barcode Scanner Button
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      var res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppBarcodeScanner(),
                        ),
                      );
                      if (res is String &&
                          res != '-1' &&
                          res.isNotEmpty &&
                          mounted) {
                        setState(() {
                          _searchController.text = res;
                        });
                        _searchProducts(res);
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
                      state.filterCategory != null ||
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
                if (state is ProductDeleteSuccess) {
                  // Reload the product list after a successful deletion
                  context.read<ProductBloc>().add(
                    LoadProductsByLocationRequested(
                      locationId: widget.locationId,
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.translate('product.delete_success')),
                      backgroundColor: AppColors.success,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (state is ProductsLoaded &&
                    state.apiMessage != null &&
                    state.apiMessage!.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.apiMessage!),
                      backgroundColor: AppColors.primary,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
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
                  if (state.products.isEmpty) {
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
                        bottom: 80,
                      ),
                      itemCount: state.hasReachedMax
                          ? state.products.length
                          : state.products.length + 1,
                      itemBuilder: (context, index) {
                        if (index >= state.products.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final product = state.products[index];
                        return ProductCardWidget(
                          product: product,
                          locationId: widget.locationId,
                        );
                      },
                    ),
                  );
                } else if (state is ProductFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.translate('common.error'),
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          state.message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final currentProducts = context
                    .read<ProductBloc>()
                    .currentProducts;

                if (currentProducts.isNotEmpty &&
                    state is! ProductLoading &&
                    state is! ProductDeleteInProgress) {
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
                        bottom: 80,
                      ),
                      itemCount: currentProducts
                          .length, // Don't show loading indicator at bottom for fallback
                      itemBuilder: (context, index) {
                        return ProductCardWidget(
                          product: currentProducts[index],
                          locationId: widget.locationId,
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ProductFabMenuWidget(
        isOpen: _showFabMenu,
        onToggle: _toggleFabMenu,
        onAddProduct: _openAddProductPage,
        onImportInventory: () {
          _toggleFabMenu();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ImportHistoryPage()),
          ).then((result) {
            if (result == true && mounted) {
              _loadProducts();
            }
          });
        },
      ),
    );
  }
}
