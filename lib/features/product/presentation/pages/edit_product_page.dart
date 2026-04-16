import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/config/app_config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/utils/action_guard.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../../../shared/widgets/app_barcode_scanner.dart';
import '../../data/models/business_type_model.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';

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
  final String? businessTypeId;
  final String? manufacturer;
  final String? imageUrl;
  final bool trackInventory;

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
    this.businessTypeId,
    this.manufacturer,
    this.imageUrl,
    this.trackInventory = true,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
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
  bool _removeImage = false;

  late bool _isActive;
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
  final ActionGuard _deleteGuard = ActionGuard();
  bool _isSubmitting = false;
  bool _isDeleting = false;
  bool _isStatusUpdating = false;
  bool? _statusBeforeToggle;
  late bool _trackInventory;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(text: widget.productName);
    _barcodeController = TextEditingController(text: widget.barcode ?? '');
    _costPriceController = TextEditingController(
      text: widget.costPrice != null
          ? CurrencyFormatter.formatNumber(widget.costPrice!)
          : '',
    );
    _salePriceController = TextEditingController(
      text: widget.salePrice != null
          ? CurrencyFormatter.formatNumber(widget.salePrice!)
          : '',
    );
    _quantityController = TextEditingController(
      text: widget.quantity != null ? widget.quantity.toString() : '',
    );
    _unitController = TextEditingController(text: widget.unit ?? '');
    _descriptionController = TextEditingController(
      text: widget.description ?? '',
    );
    _manufacturerController = TextEditingController(
      text: widget.manufacturer ?? '',
    );
    _isActive = widget.isActive;
    _trackInventory = widget.trackInventory;
    _selectedBusinessTypeId = widget.businessTypeId;

    // Load business types
    context.read<ProductBloc>().add(const LoadBusinessTypesRequested());

    // Load sale items (price tiers) from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductBloc>().add(
        LoadProductDetailRequested(productId: widget.productId),
      );
      context.read<ProductBloc>().add(
        LoadProductSaleItemsRequested(productId: widget.productId),
      );
    });
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
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (sheetCtx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l10n.translate('common.source_camera')),
                onTap: () => Navigator.of(sheetCtx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.translate('common.source_gallery')),
                onTap: () => Navigator.of(sheetCtx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
          _removeImage =
              false; // Reset removeImage flag if new image is selected
        });
        AppSnackBar.show(
          context,
          message:
              '${l10n.translate('common.image_selected')}: ${pickedFile.name}',
          type: AppSnackBarType.info,
        );
      }
    } catch (e) {
      AppSnackBar.show(
        context,
        message: '${l10n.translate('common.error')}: $e',
        type: AppSnackBarType.error,
      );
    }
  }

  String? _resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final value = rawUrl.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final normalizedBase = AppConfig.baseUrl.endsWith('/')
        ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
        : AppConfig.baseUrl;
    final normalizedPath = value.startsWith('/') ? value : '/$value';
    return '$normalizedBase$normalizedPath';
  }

  /// Show dialog to add or edit price tier
  void _showAddPriceTierDialog({int? editIndex}) {
    final unitController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();

    // If editing, populate with existing data
    if (editIndex != null && editIndex < _priceTiers.length) {
      final tier = _priceTiers[editIndex];
      unitController.text =
          tier['unit']?.toString() ?? tier['Unit']?.toString() ?? '';
      quantityController.text =
          tier['quantity']?.toString() ?? tier['Quantity']?.toString() ?? '';

      final dynamic rawPrice = tier['price'] ?? tier['Price'];
      priceController.text = rawPrice != null
          ? CurrencyFormatter.formatNumber(rawPrice)
          : '';
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
                inputFormatters: AppInputFormatters.withSqlInjectionGuard(
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                decoration: InputDecoration(
                  labelText: l10n.translate('product.quantity'),
                  hintText: '12',
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                inputFormatters: AppInputFormatters.withSqlInjectionGuard(
                  inputFormatters: [CurrencyInputFormatter()],
                ),
                decoration: InputDecoration(
                  labelText: l10n.translate('product.price'),
                  hintText: '120,000',
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
                ScaffoldMessenger.of(context)
                  ..removeCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(l10n.translate('common.required_field')),
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
                ScaffoldMessenger.of(context)
                  ..removeCurrentSnackBar()
                  ..showSnackBar(
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
  Future<void> _deleteProduct() async {
    if (_isDeleting || _isSubmitting) return;

    setState(() {
      _isDeleting = true;
    });

    var hasDispatchedDeleteEvent = false;
    await _deleteGuard.run(() async {
      final allowed = await SubscriptionFeatureGuard.ensureAllowed(
        context,
        featureCode: SubscriptionFeatureCodes.productManagement,
      );
      if (!allowed || !mounted) return;

      hasDispatchedDeleteEvent = true;
      context.read<ProductBloc>().add(
        DeleteProductRequested(
          locationId: widget.locationId,
          productId: widget.productId,
        ),
      );
    });

    if (!hasDispatchedDeleteEvent && mounted) {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  /// Submit form to update product
  Future<void> _submitForm() async {
    if (_isSubmitting || _isDeleting) return;

    final requiredMessage = l10n.translate('common.required_field');
    final invalidCostPriceMessage = l10n.translate(
      'product.invalid_cost_price',
    );
    final invalidSalePriceMessage = l10n.translate(
      'product.invalid_sale_price',
    );
    final invalidStockMessage = l10n.translate('product.invalid_stock');

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
        _quantityError = !_trackInventory
          ? null
          :
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

    setState(() {
      _isSubmitting = true;
    });

    var hasDispatchedUpdateEvent = false;

    await _submitGuard.run(() async {
      final allowed = await SubscriptionFeatureGuard.ensureAllowed(
        context,
        featureCode: SubscriptionFeatureCodes.productManagement,
      );
      if (!allowed || !mounted) return;

      if (widget.productId.isEmpty) {
        AppSnackBar.show(
          context,
          message: l10n.translate('product.invalid_id'),
          type: AppSnackBarType.error,
        );
        return;
      }
      debugPrint(
        'EditProductPage: Updating product with ID: ${widget.productId}',
      );

      hasDispatchedUpdateEvent = true;
      context.read<ProductBloc>().add(
        UpdateProductRequested(
          productId: widget.productId,
          locationId: widget.locationId,
          productName: _productNameController.text,
          barcode: _barcodeController.text.isNotEmpty
              ? _barcodeController.text
              : null,
          costPrice: _costPriceController.text.isNotEmpty ? costPrice : null,
          salePrice: _salePriceController.text.isNotEmpty ? salePrice : null,
            quantity:
              _trackInventory && _quantityController.text.isNotEmpty
              ? quantity
              : null,
          unit: _unitController.text.isNotEmpty ? _unitController.text : null,
            trackInventory: _trackInventory,
          isActive: _isActive,
          manufacturer: _manufacturerController.text.isNotEmpty
              ? _manufacturerController.text
              : null,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          imagePath: _selectedImagePath,
          priceTiers: _priceTiers.isNotEmpty ? _priceTiers : null,
          removeImage: _removeImage,
          businessTypeId: _selectedBusinessTypeId,
        ),
      );
    });

    if (!hasDispatchedUpdateEvent && mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
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
            if (_isStatusUpdating) {
              setState(() {
                _isStatusUpdating = false;
                _statusBeforeToggle = null;
                _isActive = state.product.isActive;
              });

              AppSnackBar.show(
                context,
                message: 'Đã cập nhật trạng thái sản phẩm',
                type: AppSnackBarType.success,
              );
              return;
            }

            if (!_isSubmitting && !_isDeleting) {
              return;
            }

            if (_isSubmitting || _isDeleting) {
              setState(() {
                _isSubmitting = false;
                _isDeleting = false;
              });
            }
            // Show success message
            AppSnackBar.show(
              context,
              message: l10n.translate('product.edit_success'),
              type: AppSnackBarType.success,
            );
            // Navigate back and return true to indicate success
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) Navigator.pop(context, true);
            });
          } else if (state is ProductDeleteSuccess) {
            if (!_isDeleting) {
              return;
            }

            if (_isSubmitting || _isDeleting) {
              setState(() {
                _isSubmitting = false;
                _isDeleting = false;
              });
            }
            // Show delete success message
            AppSnackBar.show(
              context,
              message: l10n.translate('product.delete_success'),
              type: AppSnackBarType.success,
            );
            // Navigate back and return true to indicate success
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) Navigator.pop(context, true);
            });
          } else if (state is ProductSaleItemsLoaded) {
            setState(() {
              final items = List<Map<String, dynamic>>.from(state.saleItems);
              if (items.isNotEmpty) {
                // First element is the base unit
                final baseItem = items.first;
                final baseUnit =
                    baseItem['unit']?.toString() ??
                    baseItem['Unit']?.toString() ??
                    '';
                if (baseUnit.trim().isNotEmpty ||
                    _unitController.text.trim().isEmpty) {
                  _unitController.text = baseUnit;
                }
                // The rest are price tiers
                _priceTiers = items.skip(1).toList();
              }
            });
          } else if (state is ProductDetailLoaded &&
              state.product.id == widget.productId) {
            final detail = state.product;
            setState(() {
              if (detail.name.trim().isNotEmpty) {
                _productNameController.text = detail.name;
              }

              final detailBarcode = (detail.barcode ?? '').trim();
              if (detailBarcode.isNotEmpty ||
                  _barcodeController.text.trim().isEmpty) {
                _barcodeController.text = detailBarcode;
              }

              if ((detail.costPrice ?? 0) > 0 ||
                  _costPriceController.text.trim().isEmpty) {
                _costPriceController.text = detail.costPrice != null
                    ? CurrencyFormatter.formatNumber(detail.costPrice!)
                    : '';
              }

              if ((detail.salePrice ?? 0) > 0 ||
                  _salePriceController.text.trim().isEmpty) {
                _salePriceController.text = detail.salePrice != null
                    ? CurrencyFormatter.formatNumber(detail.salePrice!)
                    : '';
              }

              if (detail.quantity > 0 ||
                  _quantityController.text.trim().isEmpty ||
                  _quantityController.text.trim() == '0') {
                _quantityController.text = detail.quantity.toString();
              }

              _trackInventory = detail.trackInventory;

              final detailUnit = (detail.unit ?? '').trim();
              if (detailUnit.isNotEmpty ||
                  _unitController.text.trim().isEmpty) {
                _unitController.text = detailUnit;
              }

              final detailDescription = (detail.description ?? '').trim();
              if (detailDescription.isNotEmpty ||
                  _descriptionController.text.trim().isEmpty) {
                _descriptionController.text = detailDescription;
              }

              final detailManufacturer = (detail.manufacturer ?? '').trim();
              if (detailManufacturer.isNotEmpty ||
                  _manufacturerController.text.trim().isEmpty) {
                _manufacturerController.text = detailManufacturer;
              }

              if ((detail.businessTypeId ?? '').trim().isNotEmpty ||
                  _selectedBusinessTypeId == null) {
                _selectedBusinessTypeId = detail.businessTypeId;
              }

              _isActive = detail.isActive;
            });
          } else if (state is BusinessTypesLoaded) {
            setState(() {
              _businessTypes = state.businessTypes;
            });
          } else if (state is ProductFailure) {
            if (_isSubmitting || _isDeleting) {
              setState(() {
                _isSubmitting = false;
                _isDeleting = false;
              });
            }

            if (_isStatusUpdating) {
              setState(() {
                _isStatusUpdating = false;
                if (_statusBeforeToggle != null) {
                  _isActive = _statusBeforeToggle!;
                }
                _statusBeforeToggle = null;
              });
            }

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
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(_selectedImagePath!),
                                fit: BoxFit.cover,
                              ),
                              _buildEditOverlay(),
                            ],
                          )
                        : ((_resolveImageUrl(widget.imageUrl) != null) &&
                              !_removeImage)
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                _resolveImageUrl(widget.imageUrl)!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildUploadPlaceholder(),
                              ),
                              _buildEditOverlay(),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _removeImage = true;
                                    });
                                  },
                                ),
                              ),
                            ],
                          )
                        : _buildUploadPlaceholder(),
                  ),
                ),
                if (_removeImage && widget.imageUrl != null)
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _removeImage = false;
                        });
                      },
                      icon: const Icon(Icons.undo, size: 16),
                      label: Text(l10n.translate('product.undo_remove_image')),
                    ),
                  ),
                SizedBox(height: AppSpacing.lg),

                // Status Section
                BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    final isStatusBusy =
                        _isStatusUpdating || state is ProductUpdateInProgress;

                    return Row(
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
                        isStatusBusy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.secondary,
                                ),
                              )
                            : Switch(
                                value: _isActive,
                                onChanged: (value) {
                                  setState(() {
                                    _statusBeforeToggle = _isActive;
                                    _isActive = value;
                                    _isStatusUpdating = true;
                                  });

                                  context.read<ProductBloc>().add(
                                    UpdateProductStatusRequested(
                                      locationId: widget.locationId,
                                      productId: widget.productId,
                                      isActive: value,
                                    ),
                                  );
                                },
                                activeThumbColor: AppColors.secondary,
                              ),
                      ],
                    );
                  },
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
                        inputFormatters:
                            AppInputFormatters.withSqlInjectionGuard(
                              inputFormatters: [CurrencyInputFormatter()],
                            ),
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
                        inputFormatters:
                            AppInputFormatters.withSqlInjectionGuard(
                              inputFormatters: [CurrencyInputFormatter()],
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),

                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _trackInventory,
                        onChanged: (value) {
                          setState(() {
                            _trackInventory = value ?? true;
                            if (!_trackInventory) {
                              _quantityController.clear();
                              _quantityError = null;
                            }
                          });
                        },
                        activeColor: AppColors.secondary,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quản lý tồn kho',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              _trackInventory
                                  ? 'Bật để cho phép nhập và chỉnh tồn kho.'
                                  : 'Tắt quản lý tồn kho: không thể chỉnh tồn kho ở danh sách sản phẩm.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                        enabled: _trackInventory,
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
                                            '${tier['unit'] ?? tier['Unit']} - SL: ${tier['quantity'] ?? tier['Quantity']}',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: AppColors.textPrimary,
                                                ),
                                          ),
                                          SizedBox(height: AppSpacing.xs),
                                          Text(
                                            'Giá: ${CurrencyFormatter.formatVND(((tier['price'] ?? tier['Price']) as num).toDouble())}',
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
                            }),
                            SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      // Add new tier button
                      GestureDetector(
                        onTap: () => _showAddPriceTierDialog(),
                        child: Text(
                          '+ ${l10n.translate('product.add_price_tier')}',
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
                              final isUpdateBusy =
                                  _isSubmitting ||
                                  state is ProductUpdateInProgress ||
                                  state is ProductDeleteInProgress;
                              return ElevatedButton(
                                onPressed: isUpdateBusy ? null : _submitForm,
                                child: isUpdateBusy
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
                        final isDeleteBusy =
                            _isDeleting ||
                            state is ProductDeleteInProgress ||
                            state is ProductUpdateInProgress;
                        return ElevatedButton(
                          onPressed: isDeleteBusy
                              ? null
                              : _showDeleteConfirmDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: isDeleteBusy
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
    String? errorText,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
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
          enabled: enabled,
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: AppInputFormatters.withSqlInjectionGuard(
            inputFormatters: inputFormatters,
          ),
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
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final typeItems = _businessTypes.map((type) {
          return DropdownMenuItem<String>(
            value: type.businessTypeId,
            child: Text(type.name),
          );
        }).toList();

        final hasSelectedInList =
            _selectedBusinessTypeId != null &&
            _businessTypes.any(
              (type) => type.businessTypeId == _selectedBusinessTypeId,
            );

        if (!hasSelectedInList && _selectedBusinessTypeId != null) {
          typeItems.insert(
            0,
            DropdownMenuItem<String>(
              value: _selectedBusinessTypeId,
              child: Text(l10n.translate('common.loading')),
            ),
          );
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
                        _businessTypeError = null;
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

  Widget _buildEditOverlay() {
    return Container(
      color: Colors.black26,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit, size: 48, color: AppColors.white),
          SizedBox(height: AppSpacing.md),
          Text(
            l10n.translate('product.change_image'),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
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
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.md),
          child: Text(
            l10n.translate('common.tap_to_select'),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
