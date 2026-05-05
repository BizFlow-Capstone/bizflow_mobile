import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// FAB Menu Widget for Product Management
/// Hiển thị menu với 2 option: Thêm sản phẩm và Nhập kho
class ProductFabMenuWidget extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onAddProduct;
  final VoidCallback onImportInventory;
  final bool canAddProduct;
  final bool canImportInventory;
  final String? addProductWarning;
  final String? importWarning;

  const ProductFabMenuWidget({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.onAddProduct,
    required this.onImportInventory,
    this.canAddProduct = true,
    this.canImportInventory = true,
    this.addProductWarning,
    this.importWarning,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isOpen)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 220),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  alignment: Alignment.bottomRight,
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                constraints: const BoxConstraints(maxWidth: 250),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: canAddProduct ? onAddProduct : null,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add,
                                color: canAddProduct
                                    ? AppColors.secondary
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.translate('product.add_product'),
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: canAddProduct
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: AppSpacing.xs),
                                    Text(
                                      l10n.translate(
                                        'product.create_product_option',
                                      ),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (!canAddProduct && addProductWarning != null) ...[
                                      SizedBox(height: AppSpacing.xs),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF3CD),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          addProductWarning!,
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: const Color(0xFF8A6100),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      color: AppColors.divider,
                      height: 1,
                      indent: AppSpacing.lg,
                      endIndent: AppSpacing.lg,
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: canImportInventory ? onImportInventory : null,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.file_download_outlined,
                                color: canImportInventory
                                    ? AppColors.secondary
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.translate('product.import_inventory'),
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: canImportInventory
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: AppSpacing.xs),
                                    Text(
                                      l10n.translate('stock_import.title'),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (!canImportInventory && importWarning != null) ...[
                                      SizedBox(height: AppSpacing.xs),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF3CD),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          importWarning!,
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: const Color(0xFF8A6100),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          FloatingActionButton(
            onPressed: onToggle,
            backgroundColor: AppColors.secondary,
            elevation: 6,
            child: Icon(
              isOpen ? Icons.close : Icons.add,
              color: AppColors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
