import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../pages/edit_product_page.dart';
import '../pages/product_detail_page.dart';

/// Product Card Widget
/// Hiển thị thông tin sản phẩm dưới dạng card
class ProductCardWidget extends StatelessWidget {
  final ProductEntity product;
  final String locationId;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.locationId,
  });

  String _getStatusBadgeText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (product.isActive) {
      return l10n.translate('product.status_active_label');
    }
    return l10n.translate('product.status_inactive_label');
  }

  Color _getStatusBadgeColor() {
    if (product.isActive) {
      return AppColors.success;
    }
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.white,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Image, Name, and Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.background,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: product.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.background,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        )
                      : Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.textSecondary,
                          size: 40,
                        ),
                ),
                SizedBox(width: AppSpacing.md),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        product.name,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppSpacing.xs),
                      // Barcode
                      if (product.barcode != null)
                        Text(
                          '${l10n.translate('product.barcode_label')}: ${product.barcode}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      SizedBox(height: AppSpacing.sm),
                      // Status Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusBadgeColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusBadgeText(context),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _getStatusBadgeColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),

            // Price and Quantity Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('product.sale_price_label'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      product.salePrice != null
                          ? CurrencyFormatter.formatVND(product.salePrice)
                          : 'N/A',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.translate('product.inventory_label'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      '${product.quantity} ${product.unit ?? 'cái'}',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),

            // Action Buttons
            Column(
              children: [
                // Detail Button - Full Width
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailPage(
                            product: product,
                            locationId: locationId,
                          ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        context.read<ProductBloc>().add(
                          LoadProductsByLocationRequested(
                            locationId: locationId,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: Text(l10n.translate('product.detail_title')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                // Edit and Delete Buttons - Side by Side
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
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
                            context.read<ProductBloc>().add(
                              LoadProductsByLocationRequested(
                                locationId: locationId,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(
                          l10n.translate('product.edit_button_label'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Show confirmation dialog for delete
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                l10n.translate('product.confirm_delete_title'),
                              ),
                              content: Text(
                                l10n.translate(
                                  'product.confirm_delete_message',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(l10n.translate('common.cancel')),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.read<ProductBloc>().add(
                                      DeleteProductRequested(
                                        locationId: locationId,
                                        productId: product.id,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    l10n.translate(
                                      'product.delete_button_label',
                                    ),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(
                          l10n.translate('product.delete_button_label'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
