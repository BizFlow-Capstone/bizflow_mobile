import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

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
  List<Map<String, dynamic>> _priceTiers = [];

  bool _isActive = true;
  String? _selectedBusinessTypeId;

  final ImagePicker _imagePicker = ImagePicker();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n?.translate('common.image_selected') ?? 'Image selected'}: ${pickedFile.name}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n?.translate('common.error') ?? 'Error'}: $e'),
        ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.translate('common.required_field') ??
                          'Vui lòng nhập đủ thông tin',
                    ),
                  ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.translate('product.invalid_value') ??
                          'Giá trị không hợp lệ',
                    ),
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
                  ? l10n?.translate('common.save') ?? 'Lưu'
                  : l10n?.translate('common.add') ?? 'Thêm',
            ),
          ),
        ],
      ),
    );
  }

  /// Format price to VND format
  String _formatVND(String value) {
    if (value.isEmpty) return '';
    try {
      final number = int.parse(value.replaceAll(',', ''));
      return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } catch (e) {
      return value;
    }
  }

  /// Validate if number is non-negative
  bool _isValidNumber(String value) {
    if (value.isEmpty) return true;
    try {
      return double.parse(value) >= 0;
    } catch (e) {
      return false;
    }
  }

  void _submitForm() {
    if (_productNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.translate('common.required_field') ??
                'Vui lòng nhập tên sản phẩm',
          ),
        ),
      );
      return;
    }

    if (_unitController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.translate('common.required_field') ?? 'Vui lòng chọn đơn vị',
          ),
        ),
      );
      return;
    }

    if (_selectedBusinessTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.translate('common.required_field') ??
                'Vui lòng chọn loại hình kinh doanh',
          ),
        ),
      );
      return;
    }

    context.read<ProductBloc>().add(
      AddProductRequested(
        locationId: widget.locationId,
        productName: _productNameController.text,
        barcode: _barcodeController.text.isNotEmpty
            ? _barcodeController.text
            : null,
        costPrice: _costPriceController.text.isNotEmpty
            ? double.tryParse(
                _costPriceController.text.replaceAll(RegExp(r'[,.]'), ''),
              )
            : null,
        salePrice: _salePriceController.text.isNotEmpty
            ? double.tryParse(
                _salePriceController.text.replaceAll(RegExp(r'[,.]'), ''),
              )
            : null,
        quantity: _quantityController.text.isNotEmpty
            ? int.tryParse(_quantityController.text)
            : null,
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.translate('product.add_success'))),
            );
            // Navigate back and return true to trigger reload
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) Navigator.pop(context, true);
            });
          } else if (state is ProductFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
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
                          _selectedImagePath != null
                              ? _selectedImagePath!.split('/').last
                              : l10n.translate('product.upload_image'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _selectedImagePath != null
                                ? AppColors.secondary
                                : AppColors.textSecondary,
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
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
                var res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimpleBarcodeScannerPage(),
                  ),
                );
                if (res is String && res != '-1' && res.isNotEmpty) {
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
        List<DropdownMenuItem<String>> typeItems = [];

        if (state is BusinessTypesLoaded) {
          typeItems = state.businessTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type.businessTypeId,
              child: Text(type.name),
            );
          }).toList();
        }

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
                border: Border.all(color: AppColors.divider),
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
                      });
                    },
                  ),
                ),
              ),
            ),
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
