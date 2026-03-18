import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/app_loading.dart';
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

  // Selected products for import
  List<ImportItemModel> _selectedItems = [];

  String? _selectedImagePath;
  String? _existingImageUrl;
  bool _removeImage = false;
  bool _confirmAfterUpdate = false;
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _noteController;
  late TextEditingController _supplierController;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _supplierController = TextEditingController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _supplierController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _selectedImagePath = pickedFile.path;
          _removeImage = false;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.translate('common.error')}: $e')),
      );
    }
  }

  AppLocalizations get l10n => AppLocalizations.of(context);

  void _onSaveDraft() {
    if (_selectedItems.isEmpty) {
      _showErrorSnackBar(l10n.translate('stock_import.add_product_required'));
      return;
    }

    if (widget.importId == null) {
      final req = CreateImportRequest(
        importType: _hasInvoice ? 'INVOICE' : 'MANUAL',
        businessLocationId: int.parse(widget.locationId),
        supplier: _supplierController.text,
        note: _noteController.text,
        receivedAt: null,
        saveAsDraft: true,
        imagePath: _selectedImagePath,
        items: _selectedItems,
      );
      context.read<ImportActionBloc>().add(CreateImportEvent(req));
    } else {
      final req = UpdateImportRequest(
        importType: _hasInvoice ? 'INVOICE' : 'MANUAL',
        supplier: _supplierController.text,
        note: _noteController.text,
        receivedAt: null,
        imagePath: _selectedImagePath,
        removeImage: _removeImage,
        items: _selectedItems,
      );
      context.read<ImportActionBloc>().add(
        UpdateImportEvent(widget.importId!, req),
      );
    }
  }

  void _onConfirm() {
    if (_selectedItems.isEmpty) {
      _showErrorSnackBar(l10n.translate('stock_import.add_product_required'));
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.translate('stock_import.confirm_title')),
        content: Text(
          l10n.translate(
            'stock_import.confirm_message',
            params: {'count': _selectedItems.length.toString()},
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
              if (widget.importId == null) {
                final req = CreateImportRequest(
                  importType: _hasInvoice ? 'INVOICE' : 'MANUAL',
                  businessLocationId: int.parse(widget.locationId),
                  supplier: _supplierController.text,
                  note: _noteController.text,
                  receivedAt: DateTime.now(),
                  saveAsDraft: false,
                  imagePath: _selectedImagePath,
                  items: _selectedItems,
                );
                context.read<ImportActionBloc>().add(CreateImportEvent(req));
              } else {
                _confirmAfterUpdate = true;
                final req = UpdateImportRequest(
                  importType: _hasInvoice ? 'INVOICE' : 'MANUAL',
                  supplier: _supplierController.text,
                  note: _noteController.text,
                  receivedAt: null,
                  imagePath: _selectedImagePath,
                  removeImage: _removeImage,
                  items: _selectedItems,
                );
                context.read<ImportActionBloc>().add(
                  UpdateImportEvent(widget.importId!, req),
                );
              }
            },
            child: Text(l10n.translate('common.confirm')),
          ),
        ],
      ),
    );
  }

  void _onCancelDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _status == 'DRAFT'
              ? l10n.translate('stock_import.delete_draft_title')
              : l10n.translate('stock_import.cancel_import_title'),
        ),
        content: Text(l10n.translate('stock_import.confirm_action_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(dialogContext);
              if (widget.importId != null) {
                context.read<ImportActionBloc>().add(
                  DeleteImportEvent(widget.importId!),
                );
              }
            },
            child: Text(l10n.translate('common.confirm')),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    AppSnackBar.show(
      context,
      message: message,
      type: AppSnackBarType.error,
    );
  }

  void _showSuccessSnackBar(String message) {
    AppSnackBar.show(
      context,
      message: message,
      type: AppSnackBarType.success,
    );
  }

  /// Show receipt template for MANUAL (no-invoice) import confirmation
  void _showReceiptDialog(dynamic detail) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateStr = detail.receivedAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(detail.receivedAt!)
        : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

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
        if (state.status == ImportActionStatus.success) {
          if (_confirmAfterUpdate && widget.importId != null) {
            _confirmAfterUpdate = false;
            final req = ConfirmImportRequest(receivedAt: DateTime.now());
            context.read<ImportActionBloc>().add(
              ConfirmImportEvent(widget.importId!, req),
            );
            return;
          }

          if (state.successMessage != null) {
            _showSuccessSnackBar(state.successMessage!);
          }
          // MANUAL type: show receipt template before popping
          if (!_hasInvoice && state.importDetail != null) {
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
            _hasInvoice = detail.importType == 'INVOICE';
            _supplierController.text = detail.supplier ?? '';
            _noteController.text = detail.note ?? '';
            _selectedItems = List.from(detail.items);
            _existingImageUrl = detail.imageUrl;
            _removeImage = false;
          });
        }
      },
      builder: (context, state) {
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
                  onPressed: _onCancelDelete,
                ),
            ],
            bottom: const AppSyncStatusText(),
          ),
          body:
              (state.status == ImportActionStatus.loading ||
                  state.status == ImportActionStatus.submitting)
              ? const Center(child: AppLoadingIndicator())
              : _buildBody(formatCurrency),
          bottomNavigationBar: _status == 'DRAFT' || widget.importId == null
              ? _buildBottomActions()
              : null,
        );
      },
    );
  }

  Widget _buildBody(NumberFormat formatCurrency) {
    final isEditable = _status == 'DRAFT' || widget.importId == null;

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
                        () => setState(() => _hasInvoice = false),
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
                      onTap: _pickImage,
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
                                        : Image.network(
                                            _existingImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
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
                  ],
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
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (isEditable)
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                        key: ValueKey(
                                          'cost_${item.productId}_${item.quantity}',
                                        ),
                                        initialValue:
                                            CurrencyFormatter.formatNumber(
                                              cost,
                                            ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          CurrencyInputFormatter(),
                                        ],
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
                                          _selectedItems[index] =
                                              ImportItemModel(
                                                productId: item.productId,
                                                productName: item.productName,
                                                quantity: item.quantity - 1,
                                                costPrice: item.costPrice,
                                                baseUnit: item.baseUnit,
                                              );
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 56,
                                    child: TextFormField(
                                      key: ValueKey(
                                        'qty_${item.productId}_${item.quantity}',
                                      ),
                                      initialValue: item.quantity.toString(),
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        final parsed = int.tryParse(value);
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
                                        _selectedItems[index] = ImportItemModel(
                                          productId: item.productId,
                                          productName: item.productName,
                                          quantity: item.quantity + 1,
                                          costPrice: item.costPrice,
                                          baseUnit: item.baseUnit,
                                        );
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    color: AppColors.error,
                                    onPressed: () {
                                      setState(() {
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
                                  'SL: ${item.quantity} \n${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(total)}',
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
                    _status,
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

  Widget _buildBottomActions() {
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
                onPressed: _onSaveDraft,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  side: BorderSide(color: AppColors.secondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
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
                onPressed: _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  l10n.translate('common.confirm'),
                  style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
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
  final Set<int> _loadingCostPriceProductIds = {};

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.selectedItems);
  }

  Future<void> _addOrIncrement(ProductEntity product) async {
    final idx = _items.indexWhere(
      (e) => e.productId == int.tryParse(product.id),
    );
    final resolvedCostPrice = await _resolveCostPrice(product);
    if (!mounted) return;
    setState(() {
      if (idx >= 0) {
        final existing = _items[idx];
        _items[idx] = ImportItemModel(
          productId: existing.productId,
          productName: existing.productName,
          quantity: existing.quantity + 1,
          costPrice: existing.costPrice,
          baseUnit: existing.baseUnit,
        );
      } else {
        _items.add(
          ImportItemModel(
            productId: int.tryParse(product.id) ?? 0,
            productName: product.name,
            quantity: 1,
            costPrice: resolvedCostPrice,
            baseUnit: product.unit ?? 'cái',
          ),
        );
      }
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
      _costPriceCache[productId] = resolved;
      return resolved;
    } catch (_) {
      return 0;
    }
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
    });
    _loadingCostPriceProductIds.remove(productId);
  }

  Future<void> _setQuantity(ProductEntity product, int quantity) async {
    final idx = _items.indexWhere(
      (e) => e.productId == int.tryParse(product.id),
    );
    final resolvedCostPrice = await _resolveCostPrice(product);
    if (!mounted) return;

    setState(() {
      if (quantity <= 0) {
        if (idx >= 0) {
          _items.removeAt(idx);
        }
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
            productId: int.tryParse(product.id) ?? 0,
            productName: product.name,
            quantity: quantity,
            costPrice: resolvedCostPrice,
            baseUnit: product.unit ?? 'cái',
          ),
        );
      }
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
        _items[idx] = ImportItemModel(
          productId: existing.productId,
          productName: existing.productName,
          quantity: existing.quantity - 1,
          costPrice: existing.costPrice,
          baseUnit: existing.baseUnit,
        );
      } else {
        _items.removeAt(idx);
      }
    });
  }

  int _quantityFor(ProductEntity product) {
    final idx = _items.indexWhere(
      (e) => e.productId == int.tryParse(product.id),
    );
    return idx >= 0 ? _items[idx].quantity : 0;
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
                            'count': _items
                                .fold<int>(0, (sum, e) => sum + e.quantity)
                                .toString(),
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
                              '${l10n.translate('stock_import.cost_price_label')}${CurrencyFormatter.formatNumber(displayCostPrice)}${l10n.translate('stock_import.stock_label')}${product.quantity} ${product.unit ?? ''}',
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
                                            'selector_qty_${product.id}_$qty',
                                          ),
                                          initialValue: qty.toString(),
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
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
                                            final parsed = int.tryParse(value);
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
