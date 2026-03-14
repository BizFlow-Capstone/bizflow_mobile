import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/entities/product_entity.dart';
import 'edit_product_page.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';

/// Product Detail Page
/// Displays detailed information about a product
class ProductDetailPage extends StatefulWidget {
  final ProductEntity product;
  final String locationId;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.locationId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late ProductEntity _currentProduct;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    // Trigger loading full details
    context.read<ProductBloc>().add(
      LoadProductDetailRequested(productId: widget.product.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen:
          (previous, current) =>
              current is ProductDetailLoaded &&
              current.product.id == widget.product.id,
      builder: (context, state) {
        if (state is ProductDetailLoaded) {
          _currentProduct = state.product;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context, l10n),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<ProductBloc>().add(
                LoadProductDetailRequested(productId: widget.product.id),
              );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  _buildImageSection(),
                  SizedBox(height: AppSpacing.md),

                  // Product Details Section
                  _buildProductDetailsSection(context, l10n),
                  SizedBox(height: AppSpacing.lg),

                  // Supplier Section (if available)
                  _buildSupplierSection(context, l10n),
                  SizedBox(height: AppSpacing.lg),

                  // Stock Location Section
                  _buildStockLocationSection(context, l10n),
                  SizedBox(height: AppSpacing.lg),

                  // Unit Conversion Section
                  _buildUnitConversionSection(context, l10n),
                  SizedBox(height: AppSpacing.lg),

                  // Barcode Section
                  _buildBarcodeSection(context, l10n),
                  SizedBox(height: AppSpacing.lg),

                  // Price Section
                  _buildPriceSection(context, l10n),
                  const SafeArea(
                    top: false,
                    child: SizedBox(height: AppSpacing.xl),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection() {
    if (_currentProduct.imageUrl == null || _currentProduct.imageUrl!.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'No image available',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: CachedNetworkImage(
          imageUrl: _currentProduct.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: AppColors.error.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations? l10n,
  ) {
    return AppBar(
      backgroundColor: AppColors.white,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        l10n?.translate('product.detail_title') ?? 'Chi tiết sản phẩm',
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.md),
          child: Center(
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EditProductPage(
                          productId: _currentProduct.id,
                          locationId: widget.locationId,
                          productName: _currentProduct.name,
                          barcode: _currentProduct.barcode,
                          category: _currentProduct.category,
                          costPrice: _currentProduct.costPrice,
                          salePrice: _currentProduct.salePrice,
                          quantity: _currentProduct.quantity,
                          unit: _currentProduct.unit,
                          description: _currentProduct.description,
                          isActive: _currentProduct.isActive,
                          businessTypeId: _currentProduct.businessTypeId,
                          manufacturer: _currentProduct.manufacturer,
                          imageUrl: _currentProduct.imageUrl,
                        ),
                  ),
                );
                if (result == true && context.mounted) {
                  // Pop back to product management screen to reload the list
                  Navigator.pop(context, true);
                }
              },
              child: Text(
                l10n?.translate('common.edit') ?? 'Chỉnh sửa',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetailsSection(
    BuildContext context,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            l10n?.translate('product.detail.product_info') ??
                'Chi tiết sản phẩm',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Product Name
          _buildDetailRow(
            label: l10n?.translate('product.name') ?? 'Tên sản phẩm',
            value: _currentProduct.name,
          ),
          SizedBox(height: AppSpacing.sm),

          // SKU/Barcode
          if (_currentProduct.barcode != null)
            Column(
              children: [
                _buildDetailRow(
                  label:
                      l10n?.translate('product.detail.sku') ??
                      'Mã vạch / SKU ID',
                  value: _currentProduct.barcode!,
                ),
                SizedBox(height: AppSpacing.sm),
              ],
            ),

          // Unit
          if (_currentProduct.unit != null)
            Column(
              children: [
                _buildDetailRow(
                  label: l10n?.translate('product.unit') ?? 'Đơn vị',
                  value: _currentProduct.unit!,
                ),
                SizedBox(height: AppSpacing.sm),
              ],
            ),

          SizedBox(height: AppSpacing.sm),

          // Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.translate('product.detail.status') ?? 'Trạng thái',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color:
                      _currentProduct.isActive
                          ? AppColors.success
                          : AppColors.error,
                ),
                child: Text(
                   _currentProduct.isActive
                       ? (l10n?.translate('product.detail.status_active') ??
                             'Đang hoạt động')
                       : (l10n?.translate(
                               'product.detail.status_inactive',
                             ) ??
                             'Ngừng hoạt động'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierSection(BuildContext context, AppLocalizations? l10n) {
    final noData = l10n?.translate('common.no_data') ?? 'Không có';

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            l10n?.translate('product.detail.supplier') ?? 'Nhà Sản Xuất',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Manufacturer Name
          _buildDetailRow(
            label:
                l10n?.translate('product.detail.supplier_name') ??
                'Tên nhà sản xuất',
            value:
                (_currentProduct.manufacturer != null &&
                        _currentProduct.manufacturer!.isNotEmpty)
                    ? _currentProduct.manufacturer!
                    : noData,
          ),
        ],
      ),
    );
  }

  Widget _buildStockLocationSection(
    BuildContext context,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            l10n?.translate('product.detail.stock_location') ??
                'Vị trí tồn kho',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Table Header
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.translate('product.detail.location_name') ?? 'Tên kho',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 60,
                child: Text(
                  l10n?.translate('product.detail.quantity') ?? 'Tồn kho',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // Table Row
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentProduct.businessLocationName ??
                      l10n?.translate('product.detail.default_warehouse') ??
                      'Kho chính',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 60,
                child: Text(
                  '${_currentProduct.quantity}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitConversionSection(
    BuildContext context,
    AppLocalizations? l10n,
  ) {
    if (_currentProduct.saleItems.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            l10n?.translate('product.detail.unit_conversion') ??
                'Quy đổi đơn vị',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Table Header
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.translate('product.detail.conversion_unit') ?? 'Đơn vị',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 100,
                child: Text(
                  l10n?.translate('product.detail.conversion_qty') ?? 'Số lượng',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 100,
                child: Text(
                  l10n?.translate('product.sale_price') ?? 'Giá bán',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const Divider(),
          SizedBox(height: AppSpacing.sm),

          // Dynamic Rows (Skip the item that matches the base unit)
          ..._currentProduct.saleItems.where((item) {
            final itemUnit = item['unit'] ?? item['Unit'] ?? '';
            return itemUnit != _currentProduct.unit;
          }).map((item) {
            final unit = item['unit'] ?? item['Unit'] ?? '';
            final qty = item['quantity'] ?? item['Quantity'] ?? 0;
            final price = item['price'] ?? item['Price'] ?? 0;

            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      unit.toString(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 100,
                    child: Text(
                      '1 $unit = $qty ${_currentProduct.unit ?? ''}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 100,
                    child: Text(
                      _formatPrice(price.toDouble()),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBarcodeSection(BuildContext context, AppLocalizations? l10n) {
    if (_currentProduct.barcode == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            l10n?.translate('product.detail.barcode_section') ?? 'Mã vạch',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Barcode Display (placeholder for actual barcode image)
          Center(
            child: Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Barcode placeholder
                  Container(
                    height: 80,
                    width: 150,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        _currentProduct.barcode ?? '',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    _currentProduct.barcode ?? '',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context, AppLocalizations? l10n) {
    final profit = (_currentProduct.salePrice ?? 0) -
        (_currentProduct.costPrice ?? 0);

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            l10n?.translate('product.detail.pricing') ?? 'Giá cả',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Cost Price
          _buildPriceRow(
            label: l10n?.translate('product.cost_price') ?? 'Giá vốn',
            value: _formatPrice(_currentProduct.costPrice ?? 0),
          ),
          SizedBox(height: AppSpacing.sm),

          // Sale Price
          _buildPriceRow(
            label: l10n?.translate('product.sale_price') ?? 'Giá bán',
            value: _formatPrice(_currentProduct.salePrice ?? 0),
            valueColor: AppColors.primary,
          ),
          SizedBox(height: AppSpacing.sm),

          // Profit
          _buildPriceRow(
            label: l10n?.translate('product.detail.profit') ?? 'Lợi nhuận',
            value: _formatPrice(profit),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    return CurrencyFormatter.formatVND(price);
  }
}
