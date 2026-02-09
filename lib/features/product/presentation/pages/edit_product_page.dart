import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';

/// Edit Product Page
/// SC-PRO-02: Chỉnh sửa sản phẩm
class EditProductPage extends StatefulWidget {
  final String productId;
  final String locationId;
  final String productName;
  final String? barcode;
  final String? category;
  final double? costPrice;
  final double? salePrice;
  final int? quantity;
  final String? unit;
  final String? description;
  final bool isActive;

  const EditProductPage({
    super.key,
    required this.productId,
    required this.locationId,
    required this.productName,
    this.barcode,
    this.category,
    this.costPrice,
    this.salePrice,
    this.quantity,
    this.unit,
    this.description,
    this.isActive = true,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  // Form controllers
  late TextEditingController _productNameController;
  late TextEditingController _barcodeController;
  late TextEditingController _categoryController;
  late TextEditingController _costPriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _descriptionController;

  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(text: widget.productName);
    _barcodeController = TextEditingController(text: widget.barcode ?? '');
    _categoryController = TextEditingController(text: widget.category ?? '');
    _costPriceController = TextEditingController(
      text: widget.costPrice != null ? widget.costPrice.toString() : '',
    );
    _salePriceController = TextEditingController(
      text: widget.salePrice != null ? widget.salePrice.toString() : '',
    );
    _quantityController = TextEditingController(
      text: widget.quantity != null ? widget.quantity.toString() : '',
    );
    _unitController = TextEditingController(text: widget.unit ?? '');
    _descriptionController = TextEditingController(text: widget.description ?? '');
    _isActive = widget.isActive;
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_productNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.translate('common.required_field') ?? 'Vui lòng nhập tên sản phẩm'),
        ),
      );
      return;
    }

    context.read<ProductBloc>().add(
          UpdateProductRequested(
            productId: widget.productId,
            locationId: widget.locationId,
            productName: _productNameController.text,
            barcode: _barcodeController.text.isNotEmpty ? _barcodeController.text : null,
            category: _categoryController.text.isNotEmpty ? _categoryController.text : null,
            costPrice: _costPriceController.text.isNotEmpty ? double.tryParse(_costPriceController.text) : null,
            salePrice: _salePriceController.text.isNotEmpty ? double.tryParse(_salePriceController.text) : null,
            quantity: _quantityController.text.isNotEmpty ? int.tryParse(_quantityController.text) : null,
            unit: _unitController.text.isNotEmpty ? _unitController.text : null,
            isActive: _isActive,
            description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
          ),
        );
  }

  AppLocalizations? get l10n => AppLocalizations.of(context);

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
        title: Text(
          l10n.translate('product.edit'),
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductUpdateSuccess) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.translate('product.edit_success')),
              ),
            );
            // Reload product list
            context.read<ProductBloc>().add(
                  LoadProductsByLocationRequested(locationId: widget.locationId),
                );
            // Navigate back
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) Navigator.pop(context);
            });
          } else if (state is ProductFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Section
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.translate('product.upload_image'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Status Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('product.status'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          _isActive
                              ? l10n.translate('product.status_active')
                              : l10n.translate('product.status_inactive'),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: AppColors.secondary,
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),

                // Basic Information Section
                Text(
                  l10n.translate('product.basic_info'),
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.md),

                // Product Name
                _buildTextFieldWithLabel(
                  label: l10n.translate('product.name'),
                  controller: _productNameController,
                  hint: l10n.translate('product.name_hint'),
                  isRequired: true,
                ),
                SizedBox(height: AppSpacing.lg),

                // Barcode
                _buildTextFieldWithLabel(
                  label: l10n.translate('product.barcode'),
                  controller: _barcodeController,
                  hint: l10n.translate('product.barcode_hint'),
                ),
                SizedBox(height: AppSpacing.lg),

                // Category
                _buildDropdownWithLabel(
                  label: l10n.translate('product.category'),
                  controller: _categoryController,
                  hint: l10n.translate('product.category_hint'),
                ),
                SizedBox(height: AppSpacing.lg),

                // Price & Inventory Section
                Text(
                  l10n.translate('product.price_inventory'),
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextFieldWithLabel(
                        label: l10n.translate('product.cost_price'),
                        controller: _costPriceController,
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildTextFieldWithLabel(
                        label: l10n.translate('product.sale_price'),
                        controller: _salePriceController,
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextFieldWithLabel(
                        label: l10n.translate('product.quantity'),
                        controller: _quantityController,
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildTextFieldWithLabel(
                        label: l10n.translate('product.unit'),
                        controller: _unitController,
                        hint: 'cái',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),

                // Unit Conversion Section
                _buildSectionTitle(
                  l10n.translate('product.unit_conversion'),
                ),
                SizedBox(height: AppSpacing.md),
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.background,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('product.add_conversion'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.translate('product.unit_conversion_example'),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Wholesale Price Section
                _buildSectionTitle(
                  l10n.translate('product.wholesale_price'),
                ),
                SizedBox(height: AppSpacing.md),
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.background,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('product.add_wholesale'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.translate('product.wholesale_price_example'),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Description
                _buildTextFieldWithLabel(
                  label: l10n.translate('product.description'),
                  controller: _descriptionController,
                  hint: l10n.translate('product.description_hint'),
                  maxLines: 3,
                ),
                SizedBox(height: AppSpacing.xl),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
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
                      child: BlocBuilder<ProductBloc, ProductState>(
                        builder: (context, state) {
                          return ElevatedButton(
                            onPressed: state is ProductUpdateInProgress ? null : _submitForm,
                            child: state is ProductUpdateInProgress
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : Text(
                                    l10n.translate('product.edit_button'),
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldWithLabel({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              Text(
                '*',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
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
              borderSide: BorderSide(color: AppColors.secondary),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownWithLabel({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    final l10n = AppLocalizations.of(context);
    final categoryItems = [
      l10n.translate('product.category_drinks'),
      l10n.translate('product.category_food'),
      l10n.translate('product.category_other'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    hint: Text(
                      hint,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                    value: controller.text.isNotEmpty && categoryItems.contains(controller.text) 
                        ? controller.text 
                        : null,
                    items: categoryItems
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        controller.text = value ?? '';
                      });
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: Icon(
                  Icons.expand_more,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          '+ ${l10n.translate('common.add')}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}
