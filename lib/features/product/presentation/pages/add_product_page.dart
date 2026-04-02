import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/utils/action_guard.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../../../shared/widgets/app_barcode_scanner.dart';
import '../../data/models/business_type_model.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';

/// Add New Product Page
/// SC-PRO-01: Thêm sản phẩm mới
class AddProductPage extends StatefulWidget {
  final String locationId;

  const AddProductPage({super.key, required this.locationId});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // Form controllers
  late TextEditingController _productNameController;
  late TextEditingController _barcodeController;
  late TextEditingController _costPriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _descriptionController;
  late TextEditingController _manufacturerController;

  // Image and price tiers
  String? _selectedImagePath;
  final List<Map<String, dynamic>> _priceTiers = [];

  bool _isActive = true;
  String? _selectedBusinessTypeId;
  List<BusinessTypeDto> _businessTypes = [];
  String? _productNameError;
  String? _unitError;
  String? _businessTypeError;
  String? _costPriceError;
  String? _salePriceError;
  String? _quantityError;

  final ImagePicker _imagePicker = ImagePicker();
  final ActionGuard _submitGuard = ActionGuard();

  @override
  void initState() {
    super.initState();
    // Load business types when page opens
    context.read<ProductBloc>().add(const LoadBusinessTypesRequested());
    _productNameController = TextEditingController();
    _barcodeController = TextEditingController();
    _costPriceController = TextEditingController();
    _salePriceController = TextEditingController();
    _quantityController = TextEditingController();
    _unitController = TextEditingController();
    _descriptionController = TextEditingController();
    _manufacturerController = TextEditingController();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _manufacturerController.dispose();
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
        });
        AppSnackBar.show(
          context,
          message:
              '${l10n?.translate('common.image_selected') ?? 'Image selected'}: ${pickedFile.name}',
          type: AppSnackBarType.info,
        );
      }
    } catch (e) {
      AppSnackBar.show(
        context,
        message: '${l10n?.translate('common.error') ?? 'Error'}: $e',
        type: AppSnackBarType.error,
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
      priceController.text = tier['Price'] != null
          ? CurrencyFormatter.formatNumber(tier['Price'])
          : '';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          editIndex != null
              ? l10n?.translate('common.edit') ?? 'Sửa quy đổi giá'
              : l10n?.translate('product.add_price_tier') ?? 'Thêm quy đổi giá',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: unitController,
                decoration: InputDecoration(
                  labelText: l10n?.translate('product.unit') ?? 'Đơn vị',
                  hintText: 'Lốc, Thùng, ...',
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n?.translate('product.quantity') ?? 'Số lượng',
                  hintText: '12',
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: InputDecoration(
                  labelText: l10n?.translate('product.price') ?? 'Giá',
                  hintText: '120,000',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.translate('common.cancel') ?? 'Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (unitController.text.isEmpty ||
                  quantityController.text.isEmpty ||
                  priceController.text.isEmpty) {
                AppSnackBar.show(
                  context,
                  message:
                      l10n?.translate('common.required_field') ??
                      'Vui lòng nhập đủ thông tin',
                  type: AppSnackBarType.warning,
                );
                return;
              }

              final quantity = int.tryParse(quantityController.text) ?? 0;
              final price =
                  int.tryParse(
                    priceController.text.replaceAll(RegExp(r'[,.]'), ''),
                  ) ??
                  0;

              if (quantity <= 0 || price < 0) {
                AppSnackBar.show(
                  context,
                  message:
                      l10n?.translate('product.invalid_value') ??
                      'Giá trị không hợp lệ',
                  type: AppSnackBarType.error,
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
                  ? l10n?.translate('common.save') ?? 'Lưu'
                  : l10n?.translate('common.add') ?? 'Thêm',
            ),
          ),
        ],
      ),
    );
  }

  /// Format price to VND format
  // String _formatVND(String value) {
  //   if (value.isEmpty) return '';
  //   try {
  //     final number = int.parse(value.replaceAll(',', ''));
  //     return number.toString().replaceAllMapped(
  //       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
  //       (Match m) => '${m[1]},',
  //     );
  //   } catch (e) {
  //     return value;
  //   }
  // }

  /// Validate if number is non-negative
  // bool _isValidNumber(String value) {
  //   if (value.isEmpty) return true;
  //   try {
  //     return double.parse(value) >= 0;
  //   } catch (e) {
  //     return false;
  //   }
  // }

  Future<void> _submitForm() async {
    final requiredMessage =
        l10n?.translate('common.required_field') ?? 'Trường này là bắt buộc';
    final invalidCostPriceMessage =
        l10n?.translate('product.invalid_cost_price') ?? 'Giá vốn không hợp lệ';
    final invalidSalePriceMessage =
        l10n?.translate('product.invalid_sale_price') ?? 'Giá bán không hợp lệ';
    final invalidStockMessage =
        l10n?.translate('product.invalid_stock') ?? 'Tồn kho không hợp lệ';

    double? parseMoney(String value) {
      return double.tryParse(value.replaceAll(RegExp(r'[,.]'), ''));
    }

    int? parseQuantity(String value) {
      return int.tryParse(value.replaceAll(RegExp(r'[,.]'), ''));
    }

    final costPriceText = _costPriceController.text.trim();
    final salePriceText = _salePriceController.text.trim();
    final quantityText = _quantityController.text.trim();

    final costPrice = costPriceText.isEmpty ? null : parseMoney(costPriceText);
    final salePrice = salePriceText.isEmpty ? null : parseMoney(salePriceText);
    final quantity = quantityText.isEmpty ? null : parseQuantity(quantityText);

    setState(() {
      _productNameError = _productNameController.text.trim().isEmpty
          ? requiredMessage
          : null;
      _unitError = _unitController.text.trim().isEmpty ? requiredMessage : null;
      _businessTypeError = _selectedBusinessTypeId == null
          ? requiredMessage
          : null;
      _costPriceError =
          (costPriceText.isNotEmpty && (costPrice == null || costPrice < 0))
          ? invalidCostPriceMessage
          : null;
      _salePriceError =
          (salePriceText.isNotEmpty && (salePrice == null || salePrice < 0))
          ? invalidSalePriceMessage
          : null;
      _quantityError =
          (quantityText.isNotEmpty && (quantity == null || quantity < 0))
          ? invalidStockMessage
          : null;
    });

    if (_productNameError != null ||
        _unitError != null ||
        _businessTypeError != null ||
        _costPriceError != null ||
        _salePriceError != null ||
        _quantityError != null) {
      return;
    }

    await _submitGuard.run(() async {
      final allowed = await SubscriptionFeatureGuard.ensureAllowed(
        context,
        featureCode: SubscriptionFeatureCodes.products,
      );
      if (!allowed || !mounted) return;

      context.read<ProductBloc>().add(
        AddProductRequested(
          locationId: widget.locationId,
          productName: _productNameController.text,
          barcode: _barcodeController.text.isNotEmpty
              ? _barcodeController.text
              : null,
          costPrice: _costPriceController.text.isNotEmpty ? costPrice : null,
          salePrice: _salePriceController.text.isNotEmpty ? salePrice : null,
          quantity: _quantityController.text.isNotEmpty ? quantity : null,
          unit: _unitController.text.isNotEmpty ? _unitController.text : null,
          isActive: _isActive,
          manufacturer: _manufacturerController.text.isNotEmpty
              ? _manufacturerController.text
              : null,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          imagePath: _selectedImagePath,
          priceTiers: _priceTiers,
          businessTypeId: _selectedBusinessTypeId,
        ),
      );
    });
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
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.black,
        ),
        title: Text(
          l10n.translate('product.add_new'),
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductAddSuccess) {
            // Show success message
            AppSnackBar.show(
              context,
              message: l10n.translate('product.add_success'),
              type: AppSnackBarType.success,
            );
            // Navigate back and return true to trigger reload
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) Navigator.pop(context, true);
            });
          } else if (state is BusinessTypesLoaded) {
            setState(() {
              _businessTypes = state.businessTypes;
            });
          } else if (state is ProductFailure) {
            AppSnackBar.show(
              context,
              message: state.message,
              type: AppSnackBarType.error,
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
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_selectedImagePath!),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
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
                          l10n.translate('product.status_active'),
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
                      activeThumbColor: AppColors.secondary,
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
                  errorText: _productNameError,
                  onChanged: (_) {
                    if (_productNameError == null) return;
                    setState(() => _productNameError = null);
                  },
                ),
                SizedBox(height: AppSpacing.lg),

                // Barcode
                _buildBarcodeFieldWithScanner(
                  label: l10n.translate('product.barcode'),
                  controller: _barcodeController,
                  hint: l10n.translate('product.barcode_hint'),
                ),
                SizedBox(height: AppSpacing.lg),

                // Manufacturer
                _buildTextFieldWithLabel(
                  label: l10n.translate('product.manufacturer'),
                  controller: _manufacturerController,
                  hint: l10n.translate('product.manufacturer_hint'),
                ),
                SizedBox(height: AppSpacing.lg),

                // Business Type Dropdown
                _buildBusinessTypeDropdown(),
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
                        errorText: _costPriceError,
                        onChanged: (_) {
                          if (_costPriceError == null) return;
                          setState(() => _costPriceError = null);
                        },
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildTextFieldWithLabel(
                        label: l10n.translate('product.sale_price'),
                        controller: _salePriceController,
                        hint: '0',
                        errorText: _salePriceError,
                        onChanged: (_) {
                          if (_salePriceError == null) return;
                          setState(() => _salePriceError = null);
                        },
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextFieldWithLabel(
                        label: l10n.translate('product.stock'),
                        controller: _quantityController,
                        hint: '0',
                        errorText: _quantityError,
                        onChanged: (_) {
                          if (_quantityError == null) return;
                          setState(() => _quantityError = null);
                        },
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildTextFieldWithLabel(
                        label: l10n.translate('product.unit'),
                        controller: _unitController,
                        hint: 'cái',
                        isRequired: true,
                        errorText: _unitError,
                        onChanged: (_) {
                          if (_unitError == null) return;
                          setState(() => _unitError = null);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),

                // Unit Conversion Section
                GestureDetector(
                  onTap: _showAddPriceTierDialog,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        child: _priceTiers.isEmpty
                            ? Column(
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
                                    l10n.translate(
                                      'product.unit_conversion_example',
                                    ),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _priceTiers
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: AppSpacing.sm,
                                        ),
                                        child: GestureDetector(
                                          onTap: () => _showAddPriceTierDialog(
                                            editIndex: e.key,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${e.value['Unit']}: ${e.value['Quantity']} x ${CurrencyFormatter.formatVND((e.value['Price'] as num).toDouble())}',
                                                  style:
                                                      AppTextStyles.bodySmall,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete,
                                                  size: 16,
                                                  color: AppColors.error,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _priceTiers.removeAt(e.key);
                                                  });
                                                },
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Wholesale Price Section (For future implementation)
                // GestureDetector(
                //   onTap: _showAddWholesalePriceDialog,
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       _buildSectionTitle(
                //         l10n.translate('product.wholesale_price'),
                //       ),
                //       SizedBox(height: AppSpacing.md),
                //       Container(
                //         padding: EdgeInsets.all(AppSpacing.md),
                //         decoration: BoxDecoration(
                //           border: Border.all(color: AppColors.divider),
                //           borderRadius: BorderRadius.circular(12),
                //           color: AppColors.background,
                //         ),
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             Text(
                //               l10n.translate('product.add_wholesale'),
                //               style: AppTextStyles.bodyMedium.copyWith(
                //                 color: AppColors.secondary,
                //               ),
                //             ),
                //             SizedBox(height: AppSpacing.sm),
                //             Text(
                //               l10n.translate('product.wholesale_price_example'),
                //               style: AppTextStyles.bodySmall.copyWith(
                //                 color: AppColors.textSecondary,
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                SizedBox(height: AppSpacing.lg),

                // Description
                _buildTextFieldWithLabel(
                  label: l10n.translate('product.description'),
                  controller: _descriptionController,
                  hint: l10n.translate('product.description_hint'),
                  maxLines: 3,
                ),
                SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
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
                      onPressed: state is ProductAddInProgress
                          ? null
                          : _submitForm,
                      child: state is ProductAddInProgress
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              l10n.translate('product.add_button'),
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
        ),
      ),
    );
  }

  Widget _buildTextFieldWithLabel({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isRequired = false,
    String? errorText,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
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
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : AppColors.divider,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppColors.error
                    : AppColors.secondary,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.error),
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

  Widget _buildBarcodeFieldWithScanner({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
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
        TextField(
          controller: controller,
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
            suffixIcon: IconButton(
              icon: Icon(Icons.qr_code_scanner, color: AppColors.secondary),
              onPressed: () async {
                final res = await AppBarcodeScanner.scan(context);
                if (res != null) {
                  setState(() {
                    controller.text = res;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessTypeDropdown() {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final typeItems = _businessTypes.map((type) {
          return DropdownMenuItem<String>(
            value: type.businessTypeId,
            child: Text(type.name),
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.translate('product.business_type'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '*',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _businessTypeError != null
                      ? AppColors.error
                      : AppColors.divider,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text(
                      l10n.translate('product.select_business_type'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                    value: _selectedBusinessTypeId,
                    items: typeItems,
                    onChanged: (value) {
                      setState(() {
                        _selectedBusinessTypeId = value;
                        if (value != null) {
                          _businessTypeError = null;
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            if (_businessTypeError != null) ...[
              SizedBox(height: AppSpacing.xs),
              Text(
                _businessTypeError!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
          ],
        );
      },
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
