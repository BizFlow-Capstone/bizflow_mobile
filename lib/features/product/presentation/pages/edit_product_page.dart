import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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

  // Image and price tiers
  String? _selectedImagePath;
  List<Map<String, dynamic>> _priceTiers = [];
  bool _removeImage = false;

  late bool _isActive;

  final ImagePicker _imagePicker = ImagePicker();

  AppLocalizations get l10n => AppLocalizations.of(context)!;

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
    _descriptionController = TextEditingController(
      text: widget.description ?? '',
    );
    _isActive = widget.isActive;

    // Load sale items (price tiers) from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductBloc>().add(
        LoadProductSaleItemsRequested(productId: widget.productId),
      );
    });
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

  /// Pick image from gallery or camera
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
          _removeImage =
              false; // Reset removeImage flag if new image is selected
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.translate('common.image_selected')}: ${pickedFile.name}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.translate('common.error')}: $e')),
      );
    }
  }

  /// Show dialog to add or edit price tier
  void _showAddPriceTierDialog({int? editIndex}) {
    final unitController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();

    // If editing, populate with existing data
    if (editIndex != null && editIndex < _priceTiers.length) {
      final tier = _priceTiers[editIndex];
      unitController.text = tier['Unit'] ?? '';
      quantityController.text = tier['Quantity']?.toString() ?? '';
      priceController.text = tier['Price']?.toString() ?? '';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          editIndex != null
              ? l10n.translate('common.edit')
              : l10n.translate('product.add_price_tier'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: unitController,
                decoration: InputDecoration(
                  labelText: l10n.translate('product.unit'),
                  hintText: 'Lốc, Thùng, ...',
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.translate('product.quantity'),
                  hintText: '12',
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.translate('product.price'),
                  hintText: '120000',
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
          if (editIndex != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _priceTiers.removeAt(editIndex);
                });
                Navigator.pop(context);
              },
              child: Text(
                l10n.translate('common.delete'),
                style: TextStyle(color: AppColors.error),
              ),
            ),
          TextButton(
            onPressed: () {
              if (unitController.text.isEmpty ||
                  quantityController.text.isEmpty ||
                  priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.translate('common.required_field')),
                  ),
                );
                return;
              }

              final quantity = int.tryParse(quantityController.text) ?? 0;
              final price = int.tryParse(priceController.text) ?? 0;

              if (quantity <= 0 || price < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.translate('product.invalid_value')),
                  ),
                );
                return;
              }

              setState(() {
                if (editIndex != null && editIndex < _priceTiers.length) {
                  // Update existing tier
                  _priceTiers[editIndex] = {
                    'Unit': unitController.text,
                    'Quantity': quantity,
                    'Price': price,
                  };
                } else {
                  // Add new tier
                  _priceTiers.add({
                    'Unit': unitController.text,
                    'Quantity': quantity,
                    'Price': price,
                  });
                }
              });

              Navigator.pop(context);
            },
            child: Text(
              editIndex != null
                  ? l10n.translate('common.save')
                  : l10n.translate('common.add'),
            ),
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('common.confirm')),
        content: Text(l10n.translate('product.delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct();
            },
            child: Text(
              l10n.translate('common.delete'),
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Delete product
  void _deleteProduct() {
    context.read<ProductBloc>().add(
      DeleteProductRequested(
        locationId: widget.locationId,
        productId: widget.productId,
      ),
    );
  }

  /// Submit form to update product
  void _submitForm() {
    if (_productNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('common.required_field'))),
      );
      return;
    }

    // Validate prices and quantity
    if (_costPriceController.text.isNotEmpty) {
      final costPrice = double.tryParse(_costPriceController.text);
      if (costPrice == null || costPrice < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('product.invalid_cost_price'))),
        );
        return;
      }
    }

    if (_salePriceController.text.isNotEmpty) {
      final salePrice = double.tryParse(_salePriceController.text);
      if (salePrice == null || salePrice < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('product.invalid_sale_price'))),
        );
        return;
      }
    }

    if (_quantityController.text.isNotEmpty) {
      final quantity = int.tryParse(_quantityController.text);
      if (quantity == null || quantity < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('product.invalid_quantity'))),
        );
        return;
      }
    }

    if (widget.productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('product.invalid_id')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    debugPrint(
      'EditProductPage: Updating product with ID: ${widget.productId}',
    );

    context.read<ProductBloc>().add(
      UpdateProductRequested(
        productId: widget.productId,
        locationId: widget.locationId,
        productName: _productNameController.text,
        barcode: _barcodeController.text.isNotEmpty
            ? _barcodeController.text
            : null,
        category: _categoryController.text.isNotEmpty
            ? _categoryController.text
            : null,
        costPrice: _costPriceController.text.isNotEmpty
            ? double.tryParse(_costPriceController.text)
            : null,
        salePrice: _salePriceController.text.isNotEmpty
            ? double.tryParse(_salePriceController.text)
            : null,
        quantity: _quantityController.text.isNotEmpty
            ? int.tryParse(_quantityController.text)
            : null,
        unit: _unitController.text.isNotEmpty ? _unitController.text : null,
        isActive: _isActive,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        imagePath: _selectedImagePath,
        priceTiers: _priceTiers.isNotEmpty ? _priceTiers : null,
        removeImage: _removeImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              SnackBar(content: Text(l10n.translate('product.edit_success'))),
            );
            // Reload product list
            context.read<ProductBloc>().add(
              LoadProductsByLocationRequested(locationId: widget.locationId),
            );
            // Navigate back
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) Navigator.pop(context);
            });
          } else if (state is ProductDeleteSuccess) {
            // Show delete success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.translate('product.delete_success')),
                backgroundColor: AppColors.success,
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
          } else if (state is ProductSaleItemsLoaded) {
            setState(() {
              _priceTiers = List<Map<String, dynamic>>.from(state.saleItems);
            });
          } else if (state is ProductFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
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
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                    child: _selectedImagePath != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(_selectedImagePath!),
                                fit: BoxFit.cover,
                              ),
                              Container(
                                color: Colors.black26,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 48,
                                      color: AppColors.white,
                                    ),
                                    SizedBox(height: AppSpacing.md),
                                    Text(
                                      l10n.translate('product.change_image') ??
                                          'Thay đổi ảnh',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
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
                              if (_selectedImagePath == null)
                                Padding(
                                  padding: EdgeInsets.only(top: AppSpacing.md),
                                  child: Text(
                                    l10n.translate('common.tap_to_select') ??
                                        'Nhấn để chọn ảnh',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
                        // Immediate update as requested by the user
                        context.read<ProductBloc>().add(
                          UpdateProductStatusRequested(
                            locationId: widget.locationId,
                            productId: widget.productId,
                            isActive: value,
                          ),
                        );
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

                // Unit Conversion Section (Price Tiers)
                _buildSectionTitle(l10n.translate('product.unit_conversion')),
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
                      // Price Tiers List
                      if (_priceTiers.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._priceTiers.asMap().entries.map((e) {
                              final index = e.key;
                              final tier = e.value;
                              return GestureDetector(
                                onTap: () =>
                                    _showAddPriceTierDialog(editIndex: index),
                                child: Container(
                                  margin: EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.secondary,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${tier['Unit']} - SL: ${tier['Quantity']}',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: AppColors.textPrimary,
                                                ),
                                          ),
                                          SizedBox(height: AppSpacing.xs),
                                          Text(
                                            'Giá: ${tier['Price']}đ',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: AppColors.secondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        Icons.edit,
                                        color: AppColors.secondary,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      // Add new tier button
                      GestureDetector(
                        onTap: () => _showAddPriceTierDialog(),
                        child: Text(
                          '+ ${l10n.translate('product.add_price_tier') ?? 'Thêm quy đổi giá'}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      if (_priceTiers.isEmpty) ...[
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.translate('product.unit_conversion_example'),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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
                Column(
                  children: [
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
                                onPressed:
                                    state is ProductUpdateInProgress ||
                                        state is ProductDeleteInProgress
                                    ? null
                                    : _submitForm,
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
                                        style: AppTextStyles.labelLarge
                                            .copyWith(color: AppColors.white),
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    BlocBuilder<ProductBloc, ProductState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed:
                              state is ProductDeleteInProgress ||
                                  state is ProductUpdateInProgress
                              ? null
                              : _showDeleteConfirmDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: state is ProductDeleteInProgress
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Text(
                                  l10n.translate('common.delete'),
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                const SafeArea(top: false, child: SizedBox.shrink()),
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
                    value:
                        controller.text.isNotEmpty &&
                            categoryItems.contains(controller.text)
                        ? controller.text
                        : null,
                    items: categoryItems
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
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
                child: Icon(Icons.expand_more, color: AppColors.textSecondary),
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
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
        ),
      ],
    );
  }
}
