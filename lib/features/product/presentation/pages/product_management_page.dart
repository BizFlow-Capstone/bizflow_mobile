import 'package:flutter/material.dart';
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
import 'add_product_page.dart';
import 'stock_import_page.dart';

/// Product Management by Location Page
/// SC-INV-03.1: Quản lý sản phẩm theo địa điểm kinh doanh
class ProductManagementPage extends StatefulWidget {
  final String locationId;
  final String locationName;

  const ProductManagementPage({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  late TextEditingController _searchController;
  bool _showFabMenu = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(locationId: widget.locationId),
      ),
    );
  }

  void _toggleFabMenu() {
    setState(() {
      _showFabMenu = !_showFabMenu;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
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
              l10n.translate('location.address'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        centerTitle: false,
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
                      // TODO: Implement filter dialog
                    },
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                // Sort Button
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: () {
                      // TODO: Implement sort dialog
                    },
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Products List
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
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
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: state.products.length,
                      itemBuilder: (context, index) {
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
            MaterialPageRoute(
              builder: (context) =>
                  StockImportPage(locationId: widget.locationId),
            ),
          );
        },
      ),
    );
  }
}
