import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/services/permission_service.dart';
import '../../domain/entities/product_entity.dart';
import '../../data/product_repository.dart';
import 'edit_product_page.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../../../core/network/api_error_message_parser.dart';

/// Product Detail Page
/// Displays detailed information about a product
class ProductDetailPage extends StatefulWidget {
  final ProductEntity product;
  final String locationId;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.locationId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late ProductEntity _currentProduct;
  bool _isCostHistoryLoading = false;
  String? _costHistoryError;
  double _historyCurrentCostPrice = 0;
  List<_CostPriceHistoryItem> _costPriceHistory = const [];

  ProductRepository get _repository => context.read<ProductBloc>().repository;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    // Trigger loading full details
    context.read<ProductBloc>().add(
      LoadProductDetailRequested(productId: widget.product.id),
    );
    _loadCostPriceHistory();
  }

  Future<void> _loadCostPriceHistory() async {
    if (mounted) {
      setState(() {
        _isCostHistoryLoading = true;
        _costHistoryError = null;
      });
    }

    try {
      final response = await _repository.getProductCostPriceHistory(
        _currentProduct.id,
      );
      final data = _extractCostPriceHistoryData(response);

      if (!mounted) return;
      setState(() {
        _historyCurrentCostPrice = data.$1;
        _costPriceHistory = data.$2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _costHistoryError = ApiErrorMessageParser.parse(e);
        _costPriceHistory = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _isCostHistoryLoading = false);
      }
    }
  }

  (double, List<_CostPriceHistoryItem>) _extractCostPriceHistoryData(
    dynamic response,
  ) {
    Map<String, dynamic>? payload;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        payload = data;
      } else {
        payload = response;
      }
    }

    if (payload == null) {
      return (0, const []);
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateFormatter.parseApiDateTime(value);
      }
      return null;
    }

    final rawHistory = payload['history'];
    final items = rawHistory is List
        ? rawHistory
              .map((item) {
                if (item is! Map<String, dynamic>) return null;
                return _CostPriceHistoryItem(
                  importCode: (item['importCode'] ?? '').toString(),
                  costPrice: parseDouble(item['costPrice']),
                  quantity: parseInt(item['quantity']),
                  totalPrice: parseDouble(item['totalPrice']),
                  supplier: (item['supplier'] ?? '').toString(),
                  receivedAt: parseDate(item['receivedAt']),
                  createdAt: parseDate(item['createdAt']),
                );
              })
              .whereType<_CostPriceHistoryItem>()
              .toList()
        : <_CostPriceHistoryItem>[];

    return (parseDouble(payload['currentCostPrice']), items);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (previous, current) =>
          current is ProductDetailLoaded &&
          current.product.id == widget.product.id,
      builder: (context, state) {
        if (state is ProductDetailLoaded) {
          _currentProduct = state.product;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context, l10n),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<ProductBloc>().add(
                LoadProductDetailRequested(productId: widget.product.id),
              );
              await _loadCostPriceHistory();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  _buildImageSection(),
                  SizedBox(height: AppSpacing.md),

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
                  SizedBox(height: AppSpacing.lg),

                  // Cost Price History Section
                  _buildCostPriceHistorySection(context, l10n),
                  const SafeArea(
                    top: false,
                    child: SizedBox(height: AppSpacing.xl),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection() {
    if (_currentProduct.imageUrl == null || _currentProduct.imageUrl!.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'No image available',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: CachedNetworkImage(
          imageUrl: _currentProduct.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: AppColors.error.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations? l10n,
  ) {
    final isOwner = context.watch<BusinessContext>().isOwner;
    final canAdjustStock = PermissionService.canAdjustStock(isOwner);
    final canEditProduct = PermissionService.canEditProduct(isOwner);

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
        if (canAdjustStock && _currentProduct.trackInventory)
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip:
                l10n?.translate('product.stock_adjust.title') ??
                'Chỉnh tồn kho',
            onPressed: () => _showAdjustStockDialog(l10n),
          ),
        if (canEditProduct)
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProductPage(
                        productId: _currentProduct.id,
                        locationId: widget.locationId,
                        productName: _currentProduct.name,
                        barcode: _currentProduct.barcode,
                        category: _currentProduct.category,
                        costPrice: _currentProduct.costPrice,
                        salePrice: _currentProduct.salePrice,
                        quantity: _currentProduct.quantity,
                        unit: _currentProduct.unit,
                        description: _currentProduct.description,
                        isActive: _currentProduct.isActive,
                        trackInventory: _currentProduct.trackInventory,
                        businessTypeId: _currentProduct.businessTypeId,
                        manufacturer: _currentProduct.manufacturer,
                        imageUrl: _currentProduct.imageUrl,
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

  Future<void> _showAdjustStockDialog(AppLocalizations? l10n) async {
    final stockController = TextEditingController(
      text: _currentProduct.quantity.toString(),
    );
    final memoController = TextEditingController();
    final costPriceController = TextEditingController(
      text: _currentProduct.costPrice != null
          ? CurrencyFormatter.formatNumber(_currentProduct.costPrice!)
          : '',
    );
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                l10n?.translate('product.stock_adjust.title') ??
                    'Chỉnh tồn kho',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      inputFormatters: AppInputFormatters.withSqlInjectionGuard(
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      decoration: InputDecoration(
                        labelText:
                            l10n?.translate('product.stock_adjust.stock') ??
                            'Tồn kho mới',
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: costPriceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: AppInputFormatters.withSqlInjectionGuard(
                        inputFormatters: [CurrencyInputFormatter()],
                      ),
                      decoration: InputDecoration(
                        labelText:
                            l10n?.translate(
                              'product.stock_adjust.cost_price',
                            ) ??
                            'Giá nhập (tùy chọn)',
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: memoController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText:
                            l10n?.translate('product.stock_adjust.memo') ??
                            'Ghi chú',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(l10n?.translate('common.cancel') ?? 'Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final stock = int.tryParse(stockController.text);
                          final parsedCostPrice = CurrencyFormatter.parse(
                            costPriceController.text,
                          );

                          if (stock == null || stock < 0) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n?.translate(
                                        'product.stock_adjust.invalid_stock',
                                      ) ??
                                      'Tồn kho không hợp lệ',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          try {
                            await _repository.adjustProductStock(
                              productId: _currentProduct.id,
                              stock: stock,
                              memo: memoController.text,
                              costPrice: parsedCostPrice?.toDouble(),
                            );

                            if (!mounted) return;
                            Navigator.pop(dialogContext);

                            if (mounted) {
                              ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n?.translate(
                                          'product.stock_adjust.success',
                                        ) ??
                                        'Cập nhật tồn kho thành công',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }

                            if (mounted) {
                              context.read<ProductBloc>().add(
                                LoadProductDetailRequested(
                                  productId: _currentProduct.id,
                                ),
                              );
                              context.read<ProductBloc>().add(
                                LoadProductsByLocationRequested(
                                  locationId: widget.locationId,
                                ),
                              );
                              _loadCostPriceHistory();
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(
                              SnackBar(
                                content: Text(ApiErrorMessageParser.parse(e)),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            setDialogState(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          l10n?.translate(
                                'product.stock_adjust.apply_button',
                              ) ??
                              'Xác nhận',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    stockController.dispose();
    memoController.dispose();
    costPriceController.dispose();
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
            value: _currentProduct.name,
          ),
          SizedBox(height: AppSpacing.sm),

          // SKU/Barcode
          if (_currentProduct.barcode != null)
            Column(
              children: [
                _buildDetailRow(
                  label:
                      l10n?.translate('product.detail.sku') ??
                      'Mã vạch / SKU ID',
                  value: _currentProduct.barcode!,
                ),
                SizedBox(height: AppSpacing.sm),
              ],
            ),

          // Unit
          if (_currentProduct.unit != null)
            Column(
              children: [
                _buildDetailRow(
                  label: l10n?.translate('product.unit') ?? 'Đơn vị',
                  value: _currentProduct.unit!,
                ),
                SizedBox(height: AppSpacing.sm),
              ],
            ),

          SizedBox(height: AppSpacing.sm),

          // Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.translate('product.detail.status') ?? 'Trạng thái',
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
                  color: _currentProduct.isActive
                      ? AppColors.success
                      : AppColors.error,
                ),
                child: Text(
                  _currentProduct.isActive
                      ? (l10n?.translate('product.detail.status_active') ??
                            'Đang hoạt động')
                      : (l10n?.translate('product.detail.status_inactive') ??
                            'Ngừng hoạt động'),
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
    final noData = l10n?.translate('common.no_data') ?? 'Không có';

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

          // Manufacturer Name
          _buildDetailRow(
            label:
                l10n?.translate('product.detail.supplier_name') ??
                'Tên nhà sản xuất',
            value:
                (_currentProduct.manufacturer != null &&
                    _currentProduct.manufacturer!.isNotEmpty)
                ? _currentProduct.manufacturer!
                : noData,
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

          // Table Row
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentProduct.businessLocationName ??
                      l10n?.translate('product.detail.default_warehouse') ??
                      'Kho chính',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 60,
                child: Text(
                  '${_currentProduct.quantity}',
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
    if (_currentProduct.saleItems.length <= 1) return const SizedBox.shrink();

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
                  l10n?.translate('product.detail.conversion_unit') ?? 'Đơn vị',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 100,
                child: Text(
                  l10n?.translate('product.detail.conversion_qty') ??
                      'Số lượng',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 100,
                child: Text(
                  l10n?.translate('product.sale_price') ?? 'Giá bán',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const Divider(),
          SizedBox(height: AppSpacing.sm),

          // Dynamic Rows (Skip the item that matches the base unit)
          ..._currentProduct.saleItems
              .where((item) {
                final itemUnit = item['unit'] ?? item['Unit'] ?? '';
                return itemUnit != _currentProduct.unit;
              })
              .map((item) {
                final unit = item['unit'] ?? item['Unit'] ?? '';
                final qty = item['quantity'] ?? item['Quantity'] ?? 0;
                final price = item['price'] ?? item['Price'] ?? 0;

                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          unit.toString(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      SizedBox(
                        width: 100,
                        child: Text(
                          '1 $unit = $qty ${_currentProduct.unit ?? ''}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      SizedBox(
                        width: 100,
                        child: Text(
                          _formatPrice(price.toDouble()),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
        ],
      ),
    );
  }

  Widget _buildBarcodeSection(BuildContext context, AppLocalizations? l10n) {
    final barcodeValue = (_currentProduct.barcode ?? '').trim();
    if (barcodeValue.isEmpty) return SizedBox.shrink();

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
          Center(child: _buildBarcodeCard(barcodeValue)),
          SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  // Widget _buildQrCodeCard(String value) {
  //   return Container(
  //     width: 180,
  //     padding: EdgeInsets.all(AppSpacing.sm),
  //     decoration: BoxDecoration(
  //       border: Border.all(color: AppColors.divider),
  //       borderRadius: BorderRadius.circular(8),
  //       color: AppColors.white,
  //     ),
  //     child: Column(
  //       children: [
  //         QrImageView(
  //           data: value,
  //           size: 140,
  //           backgroundColor: AppColors.white,
  //           eyeStyle: const QrEyeStyle(
  //             eyeShape: QrEyeShape.square,
  //             color: Colors.black,
  //           ),
  //           dataModuleStyle: const QrDataModuleStyle(
  //             dataModuleShape: QrDataModuleShape.square,
  //             color: Colors.black,
  //           ),
  //         ),
  //         SizedBox(height: AppSpacing.xs),
  //         Text(
  //           'QR',
  //           style: AppTextStyles.bodySmall.copyWith(
  //             color: AppColors.textSecondary,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildBarcodeCard(String value) {
    return Container(
      width: 240,
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.white,
      ),
      child: Column(
        children: [
          BarcodeWidget(
            barcode: Barcode.code128(),
            data: value,
            width: 220,
            height: 80,
            color: Colors.black,
            backgroundColor: AppColors.white,
            drawText: false,
            errorBuilder: (context, error) {
              return Container(
                width: 220,
                height: 80,
                alignment: Alignment.center,
                color: AppColors.background,
                child: Text(
                  'Barcode không hợp lệ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context, AppLocalizations? l10n) {
    final profit =
        (_currentProduct.salePrice ?? 0) - (_currentProduct.costPrice ?? 0);

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
            value: _formatPrice(_currentProduct.costPrice ?? 0),
          ),
          SizedBox(height: AppSpacing.sm),

          // Sale Price
          _buildPriceRow(
            label: l10n?.translate('product.sale_price') ?? 'Giá bán',
            value: _formatPrice(_currentProduct.salePrice ?? 0),
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

  Widget _buildCostPriceHistorySection(
    BuildContext context,
    AppLocalizations? l10n,
  ) {
    String formatDate(DateTime? value) {
      if (value == null) return '--';
      return DateFormatter.formatDateTime(value);
    }

    final title =
        l10n?.translate('product.detail.cost_history_title') ??
        'Lịch sử chỉnh giá vốn';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.white,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          tilePadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          childrenPadding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
          ),
          title: Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${l10n?.translate('product.detail.current_cost_price') ?? 'Giá vốn hiện tại'}: ${_formatPrice(_historyCurrentCostPrice)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          children: [
            if (_isCostHistoryLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_costHistoryError != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _costHistoryError!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadCostPriceHistory,
                    child: Text(l10n?.translate('common.retry') ?? 'Thử lại'),
                  ),
                ],
              )
            else if (_costPriceHistory.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  l10n?.translate('product.detail.no_cost_history') ??
                      'Chưa có lịch sử giá vốn',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  l10n?.translate('product.detail.cost_history_note') ??
                      'Chỉ hiển thị các lần nhập kho đã xác nhận. Số lượng là theo từng lần nhập.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (_costPriceHistory.isNotEmpty)
              ..._costPriceHistory.map(
                (item) => Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.importCode.isNotEmpty ? item.importCode : '#',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        '${l10n?.translate('product.cost_price') ?? 'Giá vốn'}: ${_formatPrice(item.costPrice)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${l10n?.translate('product.detail.cost_history_import_qty') ?? 'Số lượng nhập'}: ${item.quantity}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${l10n?.translate('stock_import.receipt_total') ?? 'Tổng tiền'}: ${_formatPrice(item.totalPrice)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.supplier.isNotEmpty)
                        Text(
                          '${l10n?.translate('stock_import.receipt_supplier') ?? 'Nhà cung cấp'}: ${item.supplier}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      Text(
                        '${l10n?.translate('stock_import.receipt_date') ?? 'Ngày nhập'}: ${formatDate(item.receivedAt ?? item.createdAt)}',
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
    return CurrencyFormatter.formatVND(price);
  }
}

class _CostPriceHistoryItem {
  final String importCode;
  final double costPrice;
  final int quantity;
  final double totalPrice;
  final String supplier;
  final DateTime? receivedAt;
  final DateTime? createdAt;

  const _CostPriceHistoryItem({
    required this.importCode,
    required this.costPrice,
    required this.quantity,
    required this.totalPrice,
    required this.supplier,
    required this.receivedAt,
    required this.createdAt,
  });
}
