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

  const ProductFabMenuWidget({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.onAddProduct,
    required this.onImportInventory,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Overlay when menu is open
        if (isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: onToggle,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        
        // Menu items container
        if (isOpen)
          Positioned(
            bottom: 70,
            right: 16,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: isOpen ? 1 : 0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  alignment: Alignment.bottomRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Add Product Option
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              onAddProduct();
                            },
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: AppColors.secondary,
                                    size: 24,
                                  ),
                                  SizedBox(width: AppSpacing.lg),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.translate('product.add_product') ?? 'Thêm sản phẩm',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Tạo sản phẩm mới',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: AppSpacing.md),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Divider
                        Divider(
                          color: AppColors.divider,
                          height: 1,
                          indent: AppSpacing.lg,
                          endIndent: AppSpacing.lg,
                        ),
                        
                        // Import Inventory Option
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              onImportInventory();
                            },
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.file_download_outlined,
                                    color: AppColors.secondary,
                                    size: 24,
                                  ),
                                  SizedBox(width: AppSpacing.lg),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.translate('product.import_inventory') ?? 'Nhập kho',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Tạo phiếu nhập kho',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: AppSpacing.md),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        
        // Main FAB Button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: onToggle,
            backgroundColor: AppColors.secondary,
            elevation: 6,
            child: Icon(
              isOpen ? Icons.close : Icons.add,
              color: AppColors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}
