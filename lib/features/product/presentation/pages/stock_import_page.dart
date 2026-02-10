import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/stock_import_entity.dart';

/// Stock Import Page (Tạo phiếu nhập kho)
/// Flow có hóa đơn: Nhập -> Đã liên hệ -> Đã nhập -> Xác nhận -> Nhập kho thành công
class StockImportPage extends StatefulWidget {
  final String locationId;

  const StockImportPage({super.key, required this.locationId});

  @override
  State<StockImportPage> createState() => _StockImportPageState();
}

class _StockImportPageState extends State<StockImportPage> {
  // Current step in the progress indicator (0: Nhập, 1: Nhập kho thành công)
  int _currentStep = 0;

  // Import type: true = có hóa đơn, false = không hóa đơn
  bool _hasInvoice = true;

  // Selected products for import
  final List<StockImportItemEntity> _selectedProducts = [];

  // Note controller
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Getter for localization
  AppLocalizations get l10n => AppLocalizations.of(context);

  String _getStatusText() {
    switch (_currentStep) {
      case 0:
        return l10n.translate('stock_import.status_draft');
      case 1:
        return l10n.translate('stock_import.status_imported');
      default:
        return l10n.translate('stock_import.status_draft');
    }
  }

  void _onConfirm() {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('stock_import.add_product_required')),
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.translate('stock_import.confirm_title')),
        content: Text(
          l10n.translate(
            'stock_import.confirm_message',
            params: {'count': _selectedProducts.length.toString()},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _processImport();
            },
            child: Text(l10n.translate('common.confirm')),
          ),
        ],
      ),
    );
  }

  void _processImport() {
    // Simulate import process
    setState(() {
      _currentStep = 1;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('stock_import.success')),
        backgroundColor: AppColors.success,
      ),
    );

    // Navigate back after delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _openProductSelector() {
    // TODO: Implement product selector bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildProductSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
              l10n.translate('stock_import.title'),
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentStep == 2
                        ? AppColors.success
                        : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  _getStatusText(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Progress Steps
          _buildProgressSteps(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Import Type Selection
                    _buildImportTypeSection(),
                    SizedBox(height: AppSpacing.lg),

                    // Low Stock Suggestions
                    _buildLowStockSuggestions(),
                    SizedBox(height: AppSpacing.lg),

                    // Product List Section
                    _buildProductListSection(),
                    SizedBox(height: AppSpacing.lg),

                    // Note Section
                    _buildNoteSection(),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Buttons
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildProgressSteps() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          _buildStepItem(
            index: 0,
            label: l10n.translate('stock_import.step_input'),
            icon: Icons.edit_document,
            isActive: _currentStep >= 0,
            isCompleted: _currentStep > 0,
          ),
          _buildStepConnector(isActive: _currentStep > 0),
          _buildStepItem(
            index: 1,
            label: l10n.translate('stock_import.step_imported'),
            icon: Icons.inventory_2_outlined,
            isActive: _currentStep >= 1,
            isCompleted: _currentStep == 1,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int index,
    required String label,
    required IconData icon,
    required bool isActive,
    required bool isCompleted,
  }) {
    final Color bgColor = isActive ? AppColors.warning : AppColors.divider;
    final Color iconColor = isActive
        ? AppColors.white
        : AppColors.textSecondary;
    final Color textColor = isActive
        ? AppColors.warning
        : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: isCompleted 
              ? Icon(Icons.check, color: AppColors.success, size: 24)
              : Icon(icon, color: iconColor, size: 24),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: textColor,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: EdgeInsets.only(bottom: AppSpacing.lg),
        color: isActive ? AppColors.warning : AppColors.divider,
      ),
    );
  }

  Widget _buildImportTypeSection() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('stock_import.import_type'),
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _buildImportTypeChip(
                label: l10n.translate('stock_import.with_invoice'),
                isSelected: _hasInvoice,
                onTap: () => setState(() => _hasInvoice = true),
              ),
              SizedBox(width: AppSpacing.md),
              _buildImportTypeChip(
                label: l10n.translate('stock_import.without_invoice'),
                isSelected: !_hasInvoice,
                onTap: () => setState(() => _hasInvoice = false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportTypeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3E0) : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.warning : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.warning : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockSuggestions() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.translate('stock_import.low_stock_title'),
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            l10n.translate('stock_import.low_stock_subtitle'),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
          ),
          SizedBox(height: AppSpacing.md),
          // Sample low stock item
          _buildLowStockItem(
            name: 'Mì tôm Hảo Hảo',
            supplier: 'Acecook Việt Nam',
            currentStock: 15,
            minStock: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockItem({
    required String name,
    required String supplier,
    required int currentStock,
    required int minStock,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '$supplier • Tồn: $currentStock / Tối thiểu: $minStock',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.warning,
            onPressed: () {
              // Add this product to the import list
              setState(() {
                _selectedProducts.add(
                  StockImportItemEntity(
                    productId: '1',
                    productName: name,
                    supplier: supplier,
                    quantity: minStock - currentStock,
                    unit: 'gói',
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductListSection() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('stock_import.product_list'),
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: _openProductSelector,
                child: Text(
                  l10n.translate('common.add'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          if (_selectedProducts.isEmpty)
            _buildEmptyProductList()
          else
            _buildSelectedProductsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyProductList() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            l10n.translate('stock_import.no_products'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedProductsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedProducts.length,
      separatorBuilder: (_, __) => Divider(color: AppColors.divider),
      itemBuilder: (context, index) {
        final item = _selectedProducts[index];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${item.quantity} ${item.unit}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.textSecondary,
                    onPressed: () {
                      setState(() {
                        if (item.quantity > 1) {
                          item.quantity--;
                        }
                      });
                    },
                  ),
                  Text(
                    '${item.quantity}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.warning,
                    onPressed: () {
                      setState(() {
                        item.quantity++;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.error,
                    onPressed: () {
                      setState(() {
                        _selectedProducts.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoteSection() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('stock_import.note'),
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.translate('stock_import.note_hint'),
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDisabled,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.warning),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  side: BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  l10n.translate('common.cancel'),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedProducts.isEmpty ? null : _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedProducts.isEmpty
                      ? AppColors.disabled
                      : AppColors.textSecondary,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  l10n.translate('common.confirm'),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelectorSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                l10n.translate('stock_import.select_product'),
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              // Search field
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.translate('common.search_products'),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 10, // Sample products
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('Sản phẩm ${index + 1}'),
                      subtitle: const Text('Tồn kho: 100'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.warning,
                        onPressed: () {
                          setState(() {
                            _selectedProducts.add(
                              StockImportItemEntity(
                                productId: '$index',
                                productName: 'Sản phẩm ${index + 1}',
                                supplier: 'Nhà cung cấp',
                                quantity: 1,
                                unit: 'cái',
                              ),
                            );
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
