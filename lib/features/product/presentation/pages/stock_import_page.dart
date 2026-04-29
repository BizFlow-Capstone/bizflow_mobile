import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/ocr_purchase_invoice_dto.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/utils/name_similarity.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/action_guard.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../data/import_repository.dart';
import '../../data/models/import_model.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/import_action/import_action_bloc.dart';
import '../bloc/import_action/import_action_event.dart';
import '../bloc/import_action/import_action_state.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';

/// Stock Import Page (Tạo / Sửa / Chi tiết phiếu nhập kho)
/// Flow: Chọn sản phẩm -> Lưu Nháp / Xác nhận
class StockImportPage extends StatelessWidget {
  final String locationId;
  final int? importId; // Nếu null: tạo mới. Nếu có: xem/sửa chi tiết

  const StockImportPage({super.key, required this.locationId, this.importId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = ImportActionBloc(
          repository: context.read<ImportRepository>(),
        );
        if (importId != null) {
          bloc.add(GetImportDetailEvent(importId!));
        } else {
          bloc.add(const GetImportTemplateEvent());
        }
        return bloc;
      },
      child: _StockImportView(locationId: locationId, importId: importId),
    );
  }
}

class _StockImportView extends StatefulWidget {
  final String locationId;
  final int? importId;

  const _StockImportView({required this.locationId, this.importId});

  @override
  State<_StockImportView> createState() => _StockImportViewState();
}

class _StockImportViewState extends State<_StockImportView> {
  // Import type: true = INVOICE, false = MANUAL
  bool _hasInvoice = true;
  String _status = 'DRAFT'; // DRAFT, CONFIRMED, CANCELLED
  String? _statusLabel;

  // Selected products for import
  List<ImportItemModel> _selectedItems = [];
  final Map<int, TextEditingController> _quantityControllers = {};

  String? _selectedImagePath;
  String? _existingImageUrl;
  bool _removeImage = false;
  bool _confirmAfterUpdate = false;
  final ImagePicker _imagePicker = ImagePicker();
  final ActionGuard _saveDraftGuard = ActionGuard();
  final ActionGuard _confirmGuard = ActionGuard();
  final ActionGuard _deleteGuard = ActionGuard();

  late TextEditingController _noteController;
  late TextEditingController _supplierController;
  late TextEditingController _searchController;
  late TextEditingController _documentNumberController;
  DateTime? _documentDate;
  bool _isOcrProcessing = false;
  String? _ocrInlineError;
  OcrPurchaseInvoiceResultDto? _ocrResult;
  List<String> _ocrUnmatchedProducts = const [];
  int _ocrMatchedProductCount = 0;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _supplierController = TextEditingController();
    _searchController = TextEditingController();
    _documentNumberController = TextEditingController();
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _noteController.dispose();
    _supplierController.dispose();
    _searchController.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }

  void _syncQuantityControllers() {
    final activeProductIds = _selectedItems.map((item) => item.productId).toSet();

    final staleKeys = _quantityControllers.keys
        .where((productId) => !activeProductIds.contains(productId))
        .toList();
    for (final productId in staleKeys) {
      _quantityControllers.remove(productId)?.dispose();
    }

    for (final item in _selectedItems) {
      final controller = _quantityControllers.putIfAbsent(
        item.productId,
        () => TextEditingController(),
      );
      final quantityText = _formatQuantity(item.quantity);
      if (controller.text != quantityText) {
        controller.text = quantityText;
      }
    }
  }

  String _formatQuantity(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  Future<ImageSource?> _selectImageSource() async {
    return showModalBottomSheet<ImageSource>(
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
  }

  Future<void> _pickImage({ImageSource? source}) async {
    try {
      final selectedSource = source ?? await _selectImageSource();
      if (selectedSource == null) return;

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: selectedSource,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _selectedImagePath = pickedFile.path;
          _removeImage = false;
          _ocrInlineError = null;
          _ocrResult = null;
          _ocrUnmatchedProducts = const [];
          _ocrMatchedProductCount = 0;
        });
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '${l10n.translate('common.image_selected')}: ${pickedFile.name}',
              ),
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${l10n.translate('common.error')}: $e')),
        );
    }
  }

  void _showImagePreview({String? imagePath, String? imageUrl}) {
    if ((imagePath == null || imagePath.isEmpty) &&
        (imageUrl == null || imageUrl.isEmpty)) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogCtx) => SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.7,
                maxScale: 4,
                child: imagePath != null && imagePath.isNotEmpty
                    ? Image.file(File(imagePath), fit: BoxFit.contain)
                    : CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (_, __, ___) => Center(
                          child: Text(
                            l10n.translate('common.error_occurred'),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: IconButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _tryParseInvoiceDate(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }

  String _resolveDirectNetworkError(Object error) {
    if (!ConnectivityService().isOnline) {
      return l10n.translate('error.no_internet');
    }

    if (error is ApiException && error.statusCode == -3) {
      return l10n.translate('error.no_internet');
    }

    final parsed = ApiErrorMessageParser.parse(
      error,
      fallback: l10n.translate('common.error'),
    );
    final normalized = parsed.toLowerCase();
    if (normalized.contains('khong ket noi') ||
        normalized.contains('network') ||
        normalized.contains('connection')) {
      return l10n.translate('error.no_internet');
    }
    return parsed;
  }

  Future<List<ProductEntity>> _loadProductsForOcrMapping() async {
    final repository = context.read<ProductBloc>().repository;
    final cached = await repository.getCachedProducts(widget.locationId);
    if (cached.isNotEmpty) {
      return cached;
    }

    try {
      return await repository.getLocationProducts(widget.locationId);
    } catch (_) {
      return const <ProductEntity>[];
    }
  }

  Future<void> _scanPurchaseInvoice() async {
    if (_isOcrProcessing) return;

    final aiAllowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.ai,
    );
    if (!aiAllowed || !mounted) return;

    final imagePath = _selectedImagePath;
    if (imagePath == null || imagePath.trim().isEmpty) {
      setState(() {
        _ocrInlineError = l10n.translate('stock_import.ocr_select_local_image');
      });
      return;
    }

    if (!ConnectivityService().isOnline) {
      setState(() {
        _ocrInlineError = l10n.translate('error.no_internet');
      });
      return;
    }

    final locationId = int.tryParse(widget.locationId);
    if (locationId == null || locationId <= 0) {
      setState(() {
        _ocrInlineError = l10n.translate('common.error');
      });
      return;
    }

    setState(() {
      _isOcrProcessing = true;
      _ocrInlineError = null;
    });

    try {
      final result = await context.read<ImportRepository>().ocrPurchaseInvoice(
        locationId: locationId,
        imageFile: File(imagePath),
      );
      final products = await _loadProductsForOcrMapping();
      final matchedItemsByProductId = <int, ImportItemModel>{};
      final unmatchedProducts = <String>[];

      for (final item in result.items) {
        final matchedProduct = NameSimilarity.findBestMatch<ProductEntity>(
          item.productName,
          products,
          (product) => product.name,
        );
        final matchedProductId = int.tryParse(matchedProduct?.id ?? '');
        if (matchedProduct == null ||
            matchedProductId == null ||
            matchedProductId <= 0) {
          if (item.productName.trim().isNotEmpty) {
            unmatchedProducts.add(item.productName.trim());
          }
          continue;
        }

        final quantity = item.quantity > 0 ? item.quantity : 1.0;
        final existing = matchedItemsByProductId[matchedProductId];
        matchedItemsByProductId[matchedProductId] = ImportItemModel(
          productId: matchedProductId,
          productName: matchedProduct.name,
          quantity: (existing?.quantity ?? 0.0) + quantity,
          costPrice: item.unitPrice > 0
              ? item.unitPrice
              : (existing?.costPrice ?? matchedProduct.costPrice ?? 0),
          baseUnit: (matchedProduct.unit?.trim().isNotEmpty ?? false)
              ? matchedProduct.unit
              : (item.unit.trim().isNotEmpty ? item.unit.trim() : null),
        );
      }

      final parsedInvoiceDate = _tryParseInvoiceDate(result.invoiceDate);
      final hasFillableData =
          (result.supplierName?.trim().isNotEmpty ?? false) ||
          parsedInvoiceDate != null ||
          matchedItemsByProductId.isNotEmpty;

      setState(() {
        _ocrResult = result;
        _ocrMatchedProductCount = matchedItemsByProductId.length;
        _ocrUnmatchedProducts = unmatchedProducts;
        if (result.supplierName?.trim().isNotEmpty ?? false) {
          _supplierController.text = result.supplierName!.trim();
        }
        if (parsedInvoiceDate != null) {
          _documentDate = parsedInvoiceDate;
        }
        if (matchedItemsByProductId.isNotEmpty) {
          _selectedItems = matchedItemsByProductId.values.toList();
          _syncQuantityControllers();
        }
        _ocrInlineError = hasFillableData
            ? null
            : l10n.translate('stock_import.ocr_no_fillable_data');
      });
    } catch (error) {
      setState(() {
        _ocrResult = null;
        _ocrMatchedProductCount = 0;
        _ocrUnmatchedProducts = const [];
        _ocrInlineError = _resolveDirectNetworkError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isOcrProcessing = false;
        });
      }
    }
  }

  Widget _buildOcrInlineMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrSummaryCard(NumberFormat formatCurrency) {
    final result = _ocrResult;
    if (result == null) {
      return const SizedBox.shrink();
    }

    final supplierName = result.supplierName?.trim() ?? '';
    final invoiceDate = result.invoiceDate?.trim() ?? '';
    final totalAmount = result.totalAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('stock_import.ocr_result_title'),
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.translate('accounting.ai_confidence')}: ${result.confidence}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (supplierName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.translate('stock_import.receipt_supplier')}: $supplierName',
              style: AppTextStyles.bodySmall,
            ),
          ],
          if (totalAmount != null) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.translate('stock_import.receipt_total')}: ${formatCurrency.format(totalAmount)}',
              style: AppTextStyles.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            l10n.translate(
              'stock_import.ocr_matched_count',
              params: {'count': _ocrMatchedProductCount.toString()},
            ),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_ocrUnmatchedProducts.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${l10n.translate('stock_import.ocr_unmatched_label')}: ${_ocrUnmatchedProducts.join(', ')}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  AppLocalizations get l10n => AppLocalizations.of(context);

  bool _isActionGuardLoading = false;
  Future<void> _onSaveDraft() async {
    if (_isActionGuardLoading) return;
    if (_selectedItems.isEmpty) {
      _showErrorSnackBar(l10n.translate('stock_import.add_product_required'));
      return;
    }

    final hasInvoiceImage =
        _selectedImagePath != null ||
        ((_existingImageUrl?.isNotEmpty == true) && !_removeImage);
    if (_hasInvoice && !hasInvoiceImage) {
      _showErrorSnackBar(l10n.translate('stock_import.upload_invoice'));
      return;
    }

    if (mounted) {
      setState(() => _isActionGuardLoading = true);
    }

    var hasDispatchedSubmitEvent = false;
    await _saveDraftGuard.run(() async {
      final allowed = await SubscriptionFeatureGuard.ensureAllowed(
        context,
        featureCode: SubscriptionFeatureCodes.inventoryImport,
      );
      if (!allowed || !mounted) return;

      hasDispatchedSubmitEvent = true;

      if (widget.importId == null) {
        final req = CreateImportRequest(
          importType: _hasInvoice ? 'INVOICE' : 'INVENTORY_ADJUSTMENT',
          businessLocationId: int.parse(widget.locationId),
          supplier: _supplierController.text,
          note: _noteController.text,
          receivedAt: null,
          documentDate: _documentDate,
          documentNumber: _documentNumberController.text.isNotEmpty
              ? _documentNumberController.text
              : null,
          saveAsDraft: true,
          imagePath: _selectedImagePath,
          items: _selectedItems,
        );
        context.read<ImportActionBloc>().add(CreateImportEvent(req));
      } else {
        final req = UpdateImportRequest(
          importType: _hasInvoice ? 'INVOICE' : 'INVENTORY_ADJUSTMENT',
          supplier: _supplierController.text,
          note: _noteController.text,
          receivedAt: null,
          documentDate: _documentDate,
          documentNumber: _documentNumberController.text.isNotEmpty
              ? _documentNumberController.text
              : null,
          imagePath: _selectedImagePath,
          removeImage: _removeImage,
          items: _selectedItems,
        );
        context.read<ImportActionBloc>().add(
          UpdateImportEvent(widget.importId!, req),
        );
      }
    });

    if (!hasDispatchedSubmitEvent && mounted) {
      setState(() => _isActionGuardLoading = false);
    }
  }

  Future<void> _onConfirm() async {
    if (_isActionGuardLoading) return;
    if (_selectedItems.isEmpty) {
      _showErrorSnackBar(l10n.translate('stock_import.add_product_required'));
      return;
    }

    final hasInvoiceImage =
        _selectedImagePath != null ||
        ((_existingImageUrl?.isNotEmpty == true) && !_removeImage);
    if (_hasInvoice && !hasInvoiceImage) {
      _showErrorSnackBar(l10n.translate('stock_import.upload_invoice'));
      return;
    }

    if (mounted) {
      setState(() => _isActionGuardLoading = true);
    }

    final allowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.inventoryImport,
    );
    if (!allowed) {
      if (mounted) {
        setState(() => _isActionGuardLoading = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _isActionGuardLoading = false);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        var isSubmitting = false;
        return StatefulBuilder(
          builder: (innerContext, setDialogState) => AlertDialog(
            title: Text(l10n.translate('stock_import.confirm_title')),
            content: Text(
              l10n.translate(
                'stock_import.confirm_message',
                params: {'count': _selectedItems.length.toString()},
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: Text(l10n.translate('common.cancel')),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        await _confirmGuard.run(() async {
                          Navigator.pop(dialogContext);
                          if (widget.importId == null) {
                            final req = CreateImportRequest(
                              importType: _hasInvoice
                                  ? 'INVOICE'
                                  : 'INVENTORY_ADJUSTMENT',
                              businessLocationId: int.parse(widget.locationId),
                              supplier: _supplierController.text,
                              note: _noteController.text,
                              receivedAt: DateTime.now(),
                              documentDate: _documentDate,
                              documentNumber:
                                  _documentNumberController.text.isNotEmpty
                                  ? _documentNumberController.text
                                  : null,
                              saveAsDraft: false,
                              imagePath: _selectedImagePath,
                              items: _selectedItems,
                            );
                            this.context.read<ImportActionBloc>().add(
                              CreateImportEvent(req),
                            );
                          } else {
                            _confirmAfterUpdate = true;
                            final req = UpdateImportRequest(
                              importType: _hasInvoice
                                  ? 'INVOICE'
                                  : 'INVENTORY_ADJUSTMENT',
                              supplier: _supplierController.text,
                              note: _noteController.text,
                              receivedAt: null,
                              documentDate: _documentDate,
                              documentNumber:
                                  _documentNumberController.text.isNotEmpty
                                  ? _documentNumberController.text
                                  : null,
                              imagePath: _selectedImagePath,
                              removeImage: _removeImage,
                              items: _selectedItems,
                            );
                            this.context.read<ImportActionBloc>().add(
                              UpdateImportEvent(widget.importId!, req),
                            );
                          }
                        });
                        if (mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.translate('common.confirm')),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onCancelDelete() async {
    if (_isActionGuardLoading) return;

    if (mounted) {
      setState(() => _isActionGuardLoading = true);
    }

    final allowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.inventoryImport,
    );
    if (!allowed) {
      if (mounted) {
        setState(() => _isActionGuardLoading = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _isActionGuardLoading = false);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        var isSubmitting = false;
        return StatefulBuilder(
          builder: (innerContext, setDialogState) => AlertDialog(
            title: Text(
              _status == 'DRAFT'
                  ? l10n.translate('stock_import.delete_draft_title')
                  : l10n.translate('stock_import.cancel_import_title'),
            ),
            content: Text(
              l10n.translate('stock_import.confirm_action_message'),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: Text(l10n.translate('common.cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        await _deleteGuard.run(() async {
                          Navigator.pop(dialogContext);
                          if (widget.importId != null) {
                            this.context.read<ImportActionBloc>().add(
                              DeleteImportEvent(widget.importId!),
                            );
                          }
                        });
                        if (mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.translate('common.confirm')),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    AppSnackBar.show(context, message: message, type: AppSnackBarType.error);
  }

  void _showSuccessSnackBar(String message) {
    AppSnackBar.show(context, message: message, type: AppSnackBarType.success);
  }

  /// Show receipt template for MANUAL (no-invoice) import confirmation
  void _showReceiptDialog(dynamic detail) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateStr = detail.receivedAt != null
        ? DateFormatter.formatDateTime(detail.receivedAt)
        : DateFormatter.formatDateTime(DateTime.now());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 56,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.translate('stock_import.receipt_title'),
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.translate('stock_import.receipt_subtitle'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _receiptRow(
                l10n.translate('stock_import.receipt_code'),
                detail.importCode ?? '-',
              ),
              _receiptRow(l10n.translate('stock_import.receipt_date'), dateStr),
              _receiptRow(
                l10n.translate('stock_import.receipt_location'),
                detail.businessLocationName ?? '-',
              ),
              if ((detail.supplier ?? '').isNotEmpty)
                _receiptRow(
                  l10n.translate('stock_import.receipt_supplier'),
                  detail.supplier!,
                ),
              const Divider(),
              if (detail.items != null &&
                  (detail.items as List).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.translate('stock_import.product_list'),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...(detail.items as List).map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName ?? item.productId}',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        Text(
                          'x${item.quantity}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatCurrency.format(
                            (item.costPrice) * (item.quantity),
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('stock_import.receipt_total'),
                    style: AppTextStyles.titleSmall,
                  ),
                  Text(
                    formatCurrency.format(detail.totalAmount ?? 0),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(true);
                  },
                  child: Text(
                    l10n.translate('stock_import.receipt_done'),
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _openProductSelector() {
    // Trigger product loading first
    context.read<ProductBloc>().add(
      LoadProductsByLocationRequested(locationId: widget.locationId),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => BlocProvider.value(
        value: context.read<ProductBloc>(),
        child: _ProductSelectorSheet(
          locationId: widget.locationId,
          selectedItems: _selectedItems,
          onItemsChanged: (updatedItems) {
            setState(() {
              _selectedItems = updatedItems;
              _syncQuantityControllers();
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return BlocConsumer<ImportActionBloc, ImportActionState>(
      listener: (context, state) {
        if (_isActionGuardLoading &&
            state.status != ImportActionStatus.initial) {
          setState(() => _isActionGuardLoading = false);
        }

        if (state.status == ImportActionStatus.success) {
          final isDeleteSuccess = state.actionType == ImportActionType.delete;

          if (_confirmAfterUpdate && widget.importId != null) {
            _confirmAfterUpdate = false;
            _confirmGuard.run(() async {
              final allowed = await SubscriptionFeatureGuard.ensureAllowed(
                context,
                featureCode: SubscriptionFeatureCodes.inventoryImport,
              );
              if (!allowed || !context.mounted) return;
              final req = ConfirmImportRequest(receivedAt: DateTime.now());
              context.read<ImportActionBloc>().add(
                ConfirmImportEvent(widget.importId!, req),
              );
            });
            return;
          }

          if (state.successMessage != null) {
            _showSuccessSnackBar(state.successMessage!);
          }
          if (isDeleteSuccess) {
            Navigator.pop(context, true);
            return;
          }

          // MANUAL type: show receipt template before popping
          if (!_hasInvoice &&
              state.importDetail != null &&
              state.actionType == ImportActionType.confirm) {
            _showReceiptDialog(state.importDetail!);
          } else {
            Navigator.pop(context, true);
          }
        } else if (state.status == ImportActionStatus.failure) {
          _showErrorSnackBar(
            state.errorMessage ?? l10n.translate('common.error'),
          );
        } else if (state.status == ImportActionStatus.loaded &&
            state.importDetail != null) {
          final detail = state.importDetail!;
          setState(() {
            _status = detail.status;
            _statusLabel = detail.statusLabel;
            _hasInvoice = detail.importType.toUpperCase() == 'INVOICE';
            _supplierController.text = detail.supplier ?? '';
            _noteController.text = detail.note ?? '';
            _selectedItems = List.from(detail.items);
            _existingImageUrl = detail.imageUrl;
            _removeImage = false;
            _syncQuantityControllers();
          });
        }
      },
      builder: (context, state) {
        final isSubmitting =
            _isActionGuardLoading ||
            state.status == ImportActionStatus.submitting;

        if (widget.importId != null &&
            state.importDetail == null &&
            state.status != ImportActionStatus.failure) {
          return Scaffold(
            backgroundColor: AppColors.background,
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
                l10n.translate('common.detail'),
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              bottom: const AppSyncStatusText(),
            ),
            body: const Center(child: AppLoadingIndicator()),
          );
        }

        final isDetailLoadFailed =
            widget.importId != null &&
            state.status == ImportActionStatus.failure &&
            state.importDetail == null;

        if (isDetailLoadFailed) {
          return Scaffold(
            backgroundColor: AppColors.background,
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
                l10n.translate('common.detail'),
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              bottom: const AppSyncStatusText(),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 36,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      state.errorMessage ?? l10n.translate('common.error'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => context.read<ImportActionBloc>().add(
                        GetImportDetailEvent(widget.importId!),
                      ),
                      child: Text(l10n.translate('common.retry')),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final hasBottomActions = _status == 'DRAFT' || widget.importId == null;

        return Scaffold(
          backgroundColor: AppColors.background,
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
              widget.importId == null
                  ? l10n.translate('stock_import.title')
                  : '${l10n.translate('common.detail')} (${state.importDetail?.importCode ?? '...'})',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              if (widget.importId != null && _status != 'CANCELLED')
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onPressed: isSubmitting ? null : _onCancelDelete,
                ),
            ],
            bottom: const AppSyncStatusText(),
          ),
          body: AppLoadingOverlay(
            isLoading: isSubmitting,
            child: SafeArea(
              top: true,
              bottom: !hasBottomActions,
              child: _buildBody(formatCurrency),
            ),
          ),
          bottomNavigationBar: hasBottomActions
              ? _buildBottomActions(isSubmitting: isSubmitting)
              : null,
        );
      },
    );
  }

  Widget _buildBody(NumberFormat formatCurrency) {
    final isEditable = _status == 'DRAFT' || widget.importId == null;
    final totalAmount = _selectedItems.fold<double>(
      0,
      (sum, item) => sum + (item.quantity * item.costPrice),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info Layer
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEditable) ...[
                  Text(
                    l10n.translate('stock_import.import_type'),
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _buildChip(
                        l10n.translate('stock_import.with_invoice'),
                        _hasInvoice,
                        () => setState(() => _hasInvoice = true),
                      ),
                      SizedBox(width: AppSpacing.md),
                      _buildChip(
                        l10n.translate('stock_import.without_invoice'),
                        !_hasInvoice,
                        () => setState(() {
                          _hasInvoice = false;
                          _ocrInlineError = null;
                          _ocrResult = null;
                          _ocrUnmatchedProducts = const [];
                          _ocrMatchedProductCount = 0;
                        }),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  if (_hasInvoice) ...[
                    Text(
                      l10n.translate('stock_import.invoice_image'),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: () {
                        final hasImage =
                            _selectedImagePath != null ||
                            (_existingImageUrl?.isNotEmpty == true &&
                                !_removeImage);
                        if (hasImage) {
                          _showImagePreview(
                            imagePath: _selectedImagePath,
                            imageUrl: _existingImageUrl,
                          );
                          return;
                        }
                        _pickImage();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.background,
                        ),
                        child:
                            (_selectedImagePath != null ||
                                (_existingImageUrl?.isNotEmpty == true &&
                                    !_removeImage))
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _selectedImagePath != null
                                        ? Image.file(
                                            File(_selectedImagePath!),
                                            fit: BoxFit.cover,
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: _existingImageUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              color: AppColors.background,
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            ),
                                            errorWidget: (_, __, ___) =>
                                                Container(
                                                  color: AppColors.background,
                                                ),
                                          ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (_selectedImagePath != null) {
                                            _selectedImagePath = null;
                                          } else if (_existingImageUrl !=
                                                  null &&
                                              _existingImageUrl!.isNotEmpty) {
                                            _removeImage = true;
                                          }
                                          _ocrInlineError = null;
                                          _ocrResult = null;
                                          _ocrUnmatchedProducts = const [];
                                          _ocrMatchedProductCount = 0;
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 32,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    l10n.translate(
                                      'stock_import.upload_invoice',
                                    ),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _isOcrProcessing ? null : _scanPurchaseInvoice,
                      icon: _isOcrProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.document_scanner_outlined),
                      label: Text(
                        l10n.translate('stock_import.ocr_scan_button'),
                      ),
                    ),
                    if (_ocrInlineError != null) ...[
                      SizedBox(height: AppSpacing.sm),
                      _buildOcrInlineMessage(_ocrInlineError!),
                    ],
                    if (_ocrResult != null) ...[
                      SizedBox(height: AppSpacing.sm),
                      _buildOcrSummaryCard(formatCurrency),
                    ],
                    SizedBox(height: AppSpacing.md),
                  ],
                ] else if (_hasInvoice) ...[
                  Text(
                    l10n.translate('stock_import.invoice_image'),
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => _showImagePreview(imageUrl: _existingImageUrl),
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.background,
                      ),
                      child: (_existingImageUrl?.isNotEmpty == true)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: _existingImageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppColors.background,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Center(
                                  child: Text(
                                    l10n.translate(
                                      'stock_import.upload_invoice',
                                    ),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                l10n.translate('stock_import.upload_invoice'),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                ],
                TextField(
                  controller: _supplierController,
                  enabled: isEditable,
                  decoration: InputDecoration(
                    labelText: l10n.translate('stock_import.receipt_supplier'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _noteController,
                  enabled: isEditable,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.translate('stock_import.note'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                // Document Number
                TextField(
                  controller: _documentNumberController,
                  enabled: isEditable,
                  decoration: InputDecoration(
                    labelText: l10n.translate('stock_import.document_number'),
                    hintText: l10n.translate(
                      'stock_import.document_number_hint',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Product List Layer
          Container(
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
                    if (isEditable)
                      GestureDetector(
                        onTap: _openProductSelector,
                        child: Text(
                          l10n.translate('common.add'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                if (_selectedItems.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: Text(l10n.translate('stock_import.no_products')),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedItems.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: AppColors.divider),
                    itemBuilder: (context, index) {
                      final item = _selectedItems[index];
                      final cost = item.costPrice;
                      final total = item.quantity * cost;
                      final baseUnit = (item.baseUnit ?? '').trim();
                      final quantityController = _quantityControllers.putIfAbsent(
                        item.productId,
                        () => TextEditingController(
                          text: _formatQuantity(item.quantity),
                        ),
                      );

                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName ?? 'SP #${item.productId}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (baseUnit.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${l10n.translate('product.unit')}: $baseUnit',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  if (isEditable)
                                    SizedBox(
                                      width: 190,
                                      child: TextFormField(
                                        key: ValueKey(
                                          'cost_${item.productId}_${item.quantity}',
                                        ),
                                        initialValue:
                                            CurrencyFormatter.formatNumber(
                                              cost,
                                            ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters:
                                            AppInputFormatters.withSqlInjectionGuard(
                                              inputFormatters: [
                                                CurrencyInputFormatter(),
                                              ],
                                            ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          labelText: l10n.translate(
                                            'stock_import.cost_price_label',
                                          ),
                                          border: const OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          final parsed = double.tryParse(
                                            value.replaceAll(',', '').trim(),
                                          );
                                          if (parsed == null) return;
                                          setState(() {
                                            _selectedItems[index] =
                                                ImportItemModel(
                                                  productId: item.productId,
                                                  productName: item.productName,
                                                  quantity: item.quantity,
                                                  costPrice: parsed,
                                                  baseUnit: item.baseUnit,
                                                );
                                          });
                                        },
                                      ),
                                    )
                                  else
                                    Text(
                                      NumberFormat.currency(
                                        locale: 'vi_VN',
                                        symbol: 'đ',
                                      ).format(cost),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isEditable)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    color: AppColors.textSecondary,
                                    onPressed: () {
                                      setState(() {
                                        if (item.quantity > 1) {
                                          final updatedQuantity =
                                              item.quantity - 1.0;
                                          _selectedItems[index] =
                                              ImportItemModel(
                                                productId: item.productId,
                                                productName: item.productName,
                                                quantity: updatedQuantity,
                                                costPrice: item.costPrice,
                                                baseUnit: item.baseUnit,
                                              );
                                          quantityController.text =
                                              _formatQuantity(updatedQuantity);
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 56,
                                    child: TextFormField(
                                      key: ValueKey('qty_${item.productId}'),
                                      controller: quantityController,
                                      textAlign: TextAlign.center,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters:
                                          AppInputFormatters.withSqlInjectionGuard(
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'[0-9,\.]'),
                                              ),
                                            ],
                                          ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        final normalized = value.trim();
                                        if (normalized.isEmpty) {
                                          return;
                                        }
                                        final parsed = double.tryParse(
                                          normalized.replaceAll(',', '.'),
                                        );
                                        if (parsed == null || parsed <= 0) {
                                          return;
                                        }
                                        setState(() {
                                          _selectedItems[index] =
                                              ImportItemModel(
                                                productId: item.productId,
                                                productName: item.productName,
                                                quantity: parsed,
                                                costPrice: item.costPrice,
                                                baseUnit: item.baseUnit,
                                              );
                                          quantityController.text =
                                              _formatQuantity(parsed);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: AppColors.warning,
                                    onPressed: () {
                                      setState(() {
                                        final updatedQuantity =
                                            item.quantity + 1.0;
                                        _selectedItems[index] = ImportItemModel(
                                          productId: item.productId,
                                          productName: item.productName,
                                          quantity: updatedQuantity,
                                          costPrice: item.costPrice,
                                          baseUnit: item.baseUnit,
                                        );
                                        quantityController.text =
                                            _formatQuantity(updatedQuantity);
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    color: AppColors.error,
                                    onPressed: () {
                                      setState(() {
                                        _quantityControllers.remove(
                                          item.productId,
                                        )?.dispose();
                                        _selectedItems.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              )
                            else
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'SL: ${item.quantity}${baseUnit.isNotEmpty ? ' $baseUnit' : ''} \n${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(total)}',
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                if (_selectedItems.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.md),
                  const Divider(color: AppColors.divider),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('stock_import.receipt_total'),
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        formatCurrency.format(totalAmount),
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          if (!isEditable) ...[
            SizedBox(height: AppSpacing.md),
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('stock_import.status_label'),
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text(
                    _statusLabel ?? _status,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: _status == 'CONFIRMED'
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
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
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions({required bool isSubmitting}) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: (isSubmitting || _saveDraftGuard.isRunning)
                    ? null
                    : _onSaveDraft,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  side: BorderSide(color: AppColors.secondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.translate('stock_import.save_draft'),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: (isSubmitting || _confirmGuard.isRunning)
                    ? null
                    : _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.translate('common.confirm'),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Product selector bottom sheet backed by ProductBloc
class _ProductSelectorSheet extends StatefulWidget {
  final String locationId;
  final List<ImportItemModel> selectedItems;
  final ValueChanged<List<ImportItemModel>> onItemsChanged;

  const _ProductSelectorSheet({
    required this.locationId,
    required this.selectedItems,
    required this.onItemsChanged,
  });

  @override
  State<_ProductSelectorSheet> createState() => _ProductSelectorSheetState();
}

class _ProductSelectorSheetState extends State<_ProductSelectorSheet> {
  late List<ImportItemModel> _items;
  String _searchQuery = '';
  final Map<int, double> _costPriceCache = {};
  final Map<int, String> _saleUnitsCache = {};
  final Map<int, String?> _baseUnitCache = {};
  final Set<int> _loadingCostPriceProductIds = {};
  final Map<String, TextEditingController> _quantityControllers = {};

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.selectedItems);
    for (final item in _items) {
      _quantityControllers.putIfAbsent(
        item.productId.toString(),
        () => TextEditingController(text: _formatQuantity(item.quantity)),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _quantityControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addOrIncrement(ProductEntity product) async {
    final idx = _items.indexWhere(
      (e) => e.productId == int.tryParse(product.id),
    );
    final resolvedCostPrice = await _resolveCostPrice(product);
    final productId = int.tryParse(product.id) ?? 0;
    final resolvedBaseUnit =
        _baseUnitCache[productId] ?? _resolveBaseUnit(product);
    if (!mounted) return;
    setState(() {
      double newQty;
      if (idx >= 0) {
        final existing = _items[idx];
        newQty = existing.quantity + 1.0;
        _items[idx] = ImportItemModel(
          productId: existing.productId,
          productName: existing.productName,
          quantity: newQty,
          costPrice: existing.costPrice,
          baseUnit: existing.baseUnit,
        );
      } else {
        newQty = 1.0;
        _items.add(
          ImportItemModel(
            productId: productId,
            productName: product.name,
            quantity: newQty,
            costPrice: resolvedCostPrice,
            baseUnit: resolvedBaseUnit,
          ),
        );
      }

      final key = product.id;
      _quantityControllers.putIfAbsent(key, () => TextEditingController());
      _quantityControllers[key]!.text = _formatQuantity(newQty);
    });
  }

  Future<double> _resolveCostPrice(ProductEntity product) async {
    final productId = int.tryParse(product.id) ?? 0;

    if (_costPriceCache.containsKey(productId)) {
      return _costPriceCache[productId]!;
    }

    if (product.costPrice != null) {
      _costPriceCache[productId] = product.costPrice!;
      return product.costPrice!;
    }

    try {
      final detail = await context
          .read<ProductBloc>()
          .repository
          .getProductDetail(product.id);
      final resolved = detail?.costPrice ?? 0;
      final resolvedProduct = detail ?? product;
      final resolvedUnits = _extractSaleUnits(resolvedProduct);
      _baseUnitCache[productId] = _resolveBaseUnit(resolvedProduct);
      _costPriceCache[productId] = resolved;
      _saleUnitsCache[productId] = resolvedUnits;
      return resolved;
    } catch (_) {
      return 0;
    }
  }

  String _extractSaleUnits(ProductEntity product) {
    final units = <String>{};

    final baseUnit = (product.unit ?? '').trim();
    if (baseUnit.isNotEmpty) {
      units.add(baseUnit);
    }

    for (final item in product.saleItems) {
      final unitName = (item['unitName'] ?? item['unit'] ?? item['Unit'])
          ?.toString()
          .trim();
      if (unitName != null && unitName.isNotEmpty) {
        units.add(unitName);
      }
    }

    if (units.isEmpty) {
      return '--';
    }

    return units.join(', ');
  }

  String? _resolveBaseUnit(ProductEntity product) {
    final directUnit = (product.unit ?? '').trim();
    if (directUnit.isNotEmpty) {
      return directUnit;
    }

    if (product.saleItems.isEmpty) {
      return null;
    }

    num? parseNum(dynamic value) {
      if (value == null) return null;
      if (value is num) return value;
      return num.tryParse(value.toString().trim());
    }

    String? parseUnit(Map<String, dynamic> item) {
      final unit = (item['baseUnit'] ??
              item['BaseUnit'] ??
              item['unitName'] ??
              item['UnitName'] ??
              item['unit'] ??
              item['Unit'])
          ?.toString()
          .trim();
      if (unit == null || unit.isEmpty) return null;
      return unit;
    }

    final baseItem = product.saleItems.firstWhere(
      (item) => parseNum(item['quantity'] ?? item['Quantity']) == 1,
      orElse: () => product.saleItems.first,
    );

    return parseUnit(baseItem);
  }

  Future<void> _prefetchCostPrice(ProductEntity product) async {
    final productId = int.tryParse(product.id) ?? 0;
    if (productId <= 0) return;
    if (_costPriceCache.containsKey(productId)) return;
    if (_loadingCostPriceProductIds.contains(productId)) return;

    _loadingCostPriceProductIds.add(productId);
    final resolved = await _resolveCostPrice(product);
    if (!mounted) return;
    setState(() {
      _costPriceCache[productId] = resolved;
      _baseUnitCache[productId] = _resolveBaseUnit(product);
      _saleUnitsCache[productId] = _extractSaleUnits(product);
    });
    _loadingCostPriceProductIds.remove(productId);
  }

  Future<void> _setQuantity(ProductEntity product, double quantity) async {
    final idx = _items.indexWhere(
      (e) => e.productId == int.tryParse(product.id),
    );
    final resolvedCostPrice = await _resolveCostPrice(product);
    final productId = int.tryParse(product.id) ?? 0;
    final resolvedBaseUnit =
        _baseUnitCache[productId] ?? _resolveBaseUnit(product);
    if (!mounted) return;

    setState(() {
      if (quantity <= 0) {
        if (idx >= 0) {
          _items.removeAt(idx);
        }
        // clear controller
        _quantityControllers[product.id]?.text = '';
        return;
      }

      if (idx >= 0) {
        final existing = _items[idx];
        _items[idx] = ImportItemModel(
          productId: existing.productId,
          productName: existing.productName,
          quantity: quantity,
          costPrice: existing.costPrice,
          baseUnit: existing.baseUnit,
        );
      } else {
        _items.add(
          ImportItemModel(
            productId: productId,
            productName: product.name,
            quantity: quantity,
            costPrice: resolvedCostPrice,
            baseUnit: resolvedBaseUnit,
          ),
        );
      }

      _quantityControllers.putIfAbsent(product.id, () => TextEditingController());
      _quantityControllers[product.id]!.text = _formatQuantity(quantity);
    });
  }

  void _removeOrDecrement(ProductEntity product) {
    final idx = _items.indexWhere(
      (e) => e.productId == int.tryParse(product.id),
    );
    if (idx < 0) return;

    setState(() {
      if (_items[idx].quantity > 1) {
        final existing = _items[idx];
        final newQty = (existing.quantity - 1.0) > 0 ? existing.quantity - 1.0 : 0.0;
        _items[idx] = ImportItemModel(
          productId: existing.productId,
          productName: existing.productName,
          quantity: newQty,
          costPrice: existing.costPrice,
          baseUnit: existing.baseUnit,
        );
        _quantityControllers.putIfAbsent(product.id, () => TextEditingController());
        _quantityControllers[product.id]!.text = _formatQuantity(newQty);
      } else {
        _items.removeAt(idx);
        _quantityControllers[product.id]?.text = '';
      }
    });
  }

  double _quantityFor(ProductEntity product) {
    final idx = _items.indexWhere(
      (e) => e.productId == int.tryParse(product.id),
    );
    return idx >= 0 ? _items[idx].quantity : 0.0;
  }

  String _formatQuantity(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.translate('stock_import.select_product'),
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onItemsChanged(_items);
                        Navigator.pop(context);
                      },
                      child: Text(
                        l10n.translate(
                          'stock_import.done_with_count',
                          params: {
                            'count': _formatQuantity(
                              _items.fold<double>(
                                0.0,
                                (sum, e) => sum + e.quantity,
                              ),
                            ),
                          },
                        ),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  onChanged: (v) {
                    setState(() => _searchQuery = v.toLowerCase());
                    context.read<ProductBloc>().add(
                      SearchProductsRequested(
                        query: v,
                        locationId: widget.locationId,
                      ),
                    );
                  },
                  decoration: InputDecoration(
                    hintText: l10n.translate('common.search_products'),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              // Product list
              Expanded(
                child: BlocConsumer<ProductBloc, ProductState>(
                  listener: (context, state) {
                    if (state is ProductFailure) {
                      AppSnackBar.show(
                        context,
                        message: state.message.isNotEmpty
                            ? state.message
                            : l10n.translate('common.error_occurred'),
                        type: AppSnackBarType.error,
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is ProductLoading) {
                      return const Center(child: AppLoadingIndicator());
                    }
                    if (state is ProductFailure) {
                      return Center(
                        child: Text(
                          l10n.translate('stock_import.no_products_found'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    if (state is ProductsLoaded) {
                      final products = _searchQuery.isEmpty
                          ? state.products
                          : state.products
                                .where(
                                  (p) => p.name.toLowerCase().contains(
                                    _searchQuery,
                                  ),
                                )
                                .toList();

                      if (products.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.translate('stock_import.no_products_found'),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        controller: scrollController,
                        itemCount: products.length,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        separatorBuilder: (_, __) =>
                            Divider(color: AppColors.divider),
                        itemBuilder: (ctx, index) {
                          final product = products[index];
                          _prefetchCostPrice(product);
                          final qty = _quantityFor(product);
                          final displayCostPrice =
                              _costPriceCache[int.tryParse(product.id) ?? 0] ??
                              product.costPrice ??
                              0;
                          final productId = int.tryParse(product.id) ?? 0;
                          final saleUnitsText =
                              _saleUnitsCache[productId] ??
                              _extractSaleUnits(product);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              product.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${l10n.translate('order_create.sale_unit_label')}: $saleUnitsText\n${l10n.translate('stock_import.cost_price_label')}${CurrencyFormatter.formatNumber(displayCostPrice)}\n${l10n.translate('stock_import.stock_label')}${_formatQuantity(product.quantity)} ${product.unit ?? ''}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: qty > 0
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: () =>
                                            _removeOrDecrement(product),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 56,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.warning,
                                          ),
                                        ),
                                        child: TextFormField(
                                          key: ValueKey(
                                            'selector_qty_${product.id}',
                                          ),
                                          controller: _quantityControllers.putIfAbsent(
                                            product.id,
                                            () => TextEditingController(
                                              text: qty > 0 ? _formatQuantity(qty) : '',
                                            ),
                                          ),
                                          textAlign: TextAlign.center,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters:
                                              AppInputFormatters.withSqlInjectionGuard(
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.allow(
                                                    RegExp(r'[0-9,\.]'),
                                                  ),
                                                ],
                                              ),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            counterText: '',
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 6,
                                                ),
                                            border: InputBorder.none,
                                          ),
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: AppColors.warning,
                                                fontWeight: FontWeight.bold,
                                              ),
                                          onChanged: (value) {
                                            final normalized = value.trim();
                                            if (normalized.isEmpty) {
                                              return;
                                            }
                                            final parsed = double.tryParse(
                                              normalized.replaceAll(',', '.'),
                                            );
                                            if (parsed == null) return;
                                            _setQuantity(product, parsed);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: AppColors.warning,
                                        ),
                                        onPressed: () =>
                                            _addOrIncrement(product),
                                      ),
                                    ],
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: AppColors.warning,
                                    ),
                                    onPressed: () => _addOrIncrement(product),
                                  ),
                          );
                        },
                      );
                    }
                    // Initial state or not loaded yet
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppLoadingIndicator(),
                          SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.translate('stock_import.loading_products'),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SafeArea(top: false, child: const SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }
}
