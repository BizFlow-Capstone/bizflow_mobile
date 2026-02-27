import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/product_entity.dart';
import 'edit_product_page.dart';

/// Product Detail Page
/// Displays detailed information about a product
class ProductDetailPage extends StatelessWidget {
  final ProductEntity product;
  final String locationId;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.locationId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, l10n),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SafeArea(top: false, child: SizedBox(height: AppSpacing.xl)),
          ],
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
                    builder: (context) => EditProductPage(
                      productId: product.id,
                      locationId: locationId,
                      productName: product.name,
                      barcode: product.barcode,
                      category: product.category,
                      costPrice: product.costPrice,
                      salePrice: product.salePrice,
                      quantity: product.quantity,
                      unit: product.unit,
                      description: product.description,
                      isActive: product.isActive,
                      businessTypeId: product.businessTypeId,
                      manufacturer: product.manufacturer,
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
            value: product.name,
          ),
          SizedBox(height: AppSpacing.sm),

          // SKU/Barcode
          if (product.barcode != null)
            Column(
              children: [
                _buildDetailRow(
                  label:
                      l10n?.translate('product.detail.sku') ??
                      'Mã vạch / SKU ID',
                  value: product.barcode!,
                ),
                SizedBox(height: AppSpacing.sm),
              ],
            ),

          // Unit
          if (product.unit != null)
            Column(
              children: [
                _buildDetailRow(
                  label: l10n?.translate('product.unit') ?? 'Đơn vị',
                  value: product.unit!,
                ),
                SizedBox(height: AppSpacing.sm),
              ],
            ),

          // Expiry Date (if available in data)
          _buildDetailRow(
            label:
                l10n?.translate('product.detail.expiry_date') ?? 'Ngày hết hạn',
            value: product.createdAt != null
                ? _formatDate(product.createdAt!)
                : l10n?.translate('common.no_data') ?? 'Không có',
          ),
          SizedBox(height: AppSpacing.sm),

          // Min Stock
          _buildDetailRow(
            label:
                l10n?.translate('product.detail.min_stock') ??
                'Định mức tồn kho tối thiểu',
            value: '${product.quantity ?? 0}',
          ),
          SizedBox(height: AppSpacing.sm),

          // Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.translate('product.detail.status') ?? 'Đạo hạn',
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
                  color: product.isActive ? AppColors.success : AppColors.error,
                ),
                child: Text(
                  product.isActive
                      ? (l10n?.translate('product.detail.status_in_stock') ??
                            'Đủ dùng')
                      : (l10n?.translate(
                              'product.detail.status_out_of_stock',
                            ) ??
                            'Hết hàng'),
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

          // Supplier Name
          _buildDetailRow(
            label:
                l10n?.translate('product.detail.supplier_name') ??
                'Tên nhà sản xuất',
            value: l10n?.translate('common.no_data') ?? 'Không có',
          ),
          SizedBox(height: AppSpacing.sm),

          // Contact
          _buildDetailRow(
            label:
                l10n?.translate('product.detail.supplier_contact') ??
                'Số liên lạc',
            value: l10n?.translate('common.no_data') ?? 'Không có',
          ),
          SizedBox(height: AppSpacing.sm),

          // Contact Person
          _buildDetailRow(
            label:
                l10n?.translate('product.detail.contact_person') ??
                'Người liên hệ',
            value: l10n?.translate('common.no_data') ?? 'Không có',
          ),
          SizedBox(height: AppSpacing.sm),

          // Address
          _buildDetailRow(
            label: l10n?.translate('product.detail.address') ?? 'Địa chỉ',
            value: l10n?.translate('common.no_data') ?? 'Không có',
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

          // Table Row (Sample)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.translate('product.detail.default_warehouse') ??
                      'Kho Quận 1',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 60,
                child: Text(
                  '${product.quantity ?? 0}',
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
                  l10n?.translate('product.detail.conversion_unit') ??
                      'Tên kho bán đầu',
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
                  l10n?.translate('product.detail.conversion_qty') ?? 'Tồn kho',
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

          // Sample Row
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.translate('product.detail.default_unit') ?? 'Lốc',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 60,
                child: Text(
                  '${(product.quantity ?? 0) ~/ 10}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // Sample Row 2
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.translate('product.detail.default_unit2') ?? 'Lon',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 60,
                child: Text(
                  '${product.quantity ?? 0}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
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

  Widget _buildBarcodeSection(BuildContext context, AppLocalizations? l10n) {
    if (product.barcode == null) return SizedBox.shrink();

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
                        product.barcode ?? '',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    product.barcode ?? '',
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
    final profit = (product.salePrice ?? 0) - (product.costPrice ?? 0);

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
            value: _formatPrice(product.costPrice ?? 0),
          ),
          SizedBox(height: AppSpacing.sm),

          // Sale Price
          _buildPriceRow(
            label: l10n?.translate('product.sale_price') ?? 'Giá bán',
            value: _formatPrice(product.salePrice ?? 0),
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
    return '${price.toStringAsFixed(0)}đ';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
