import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../../core/reference/presentation/bloc/reference_bloc.dart';
import '../../../../core/reference/presentation/bloc/reference_event.dart';
import '../../../../core/reference/presentation/bloc/reference_state.dart';
import '../../../../core/reference/data/reference_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/utils/string_utils.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../../invoice_template/domain/entities/invoice_template_entity.dart';
import '../../../invoice_template/presentation/bloc/invoice_template_bloc.dart';
import '../../../invoice_template/presentation/bloc/invoice_template_event.dart';
import '../../../invoice_template/presentation/bloc/invoice_template_state.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';
import '../../../../shared/context/business_context.dart';
import '../../../accounting/data/repositories/accounting_repository.dart';
import '../../../accounting/domain/models/accounting_period.dart';
import '../../data/order_api_service.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order_bloc.dart';
import 'order_form_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderEntity? _detail;
  bool _isInitialLoading = true;
  String? _detailError;
  bool _isCancelling = false;
  bool _isPublishing = false;
  bool _isInvoiceActionInProgress = false;
  List<AccountingPeriod> _periods = [];
  bool _periodsLoaded = false;

  String _formatDateTime(DateTime value) {
    return DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
  }

  bool _canEditOrder(OrderEntity order) {
    // Rule 0: do not allow edit until accounting periods are loaded.
    if (!_periodsLoaded) return false;

    // Rule 1: if order belongs to a closed/finalized accounting period, editing is blocked.
    for (final period in _periods) {
      DateTime? start;
      DateTime? end;
      try {
        start = DateUtils.dateOnly(DateTime.parse(period.startDate));
        end = DateUtils.dateOnly(DateTime.parse(period.endDate));
      } catch (_) {
        continue;
      }

      if (!period.isOpen) {
        return false;
      }
    }

    return true;
  }

  bool _isDateInPeriod(DateTime date, AccountingPeriod period) {
    try {
      final targetDate = DateUtils.dateOnly(date.toLocal());
      final startDate = DateUtils.dateOnly(DateTime.parse(period.startDate));
      final endDate = DateUtils.dateOnly(DateTime.parse(period.endDate));
      return !targetDate.isBefore(startDate) && !targetDate.isAfter(endDate);
    } catch (_) {
      return false;
    }
  }

  bool _hideCancelForCompletedOrder(OrderEntity order) {
    if (!order.isPublished || !_periodsLoaded) {
      return false;
    }

    final orderDate = order.completedAt ?? order.createdAt;
    for (final period in _periods) {
      if (_isDateInPeriod(orderDate, period) && period.isFinalized) {
        return true;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadDetailSWR();
    final refState = context.read<ReferenceBloc>().state;
    if (refState is! ReferenceLoaded) {
      context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
    }
    // Trigger load template khi screen mở
    context.read<InvoiceTemplateBloc>().add(const LoadInvoiceTemplateRequested());
  }

  Future<void> _loadAccountingPeriods(String locationId) async {
    final fallbackLocationId = context.read<BusinessContext>().currentBusinessId;
    final resolvedLocationId = int.tryParse(locationId) != null
        ? locationId
        : (fallbackLocationId ?? '');

    if (resolvedLocationId.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _periods = const <AccountingPeriod>[];
          _periodsLoaded = true;
        });
      }
      return;
    }

    try {
      await context.read<AccountingRepository>().fetchPeriodsSWR(
        locationId: resolvedLocationId,
        onData: (periods, _) {
          if (!mounted) return;
          setState(() {
            _periods = periods;
            _periodsLoaded = true;
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _periodsLoaded = true;
          });
        },
      );
    } catch (e) {
      debugPrint('Error loading accounting periods: $e');
      if (mounted) {
        setState(() {
          _periodsLoaded = true;
        });
      }
    }
  }

  Future<void> _loadDetailSWR({bool refreshOnly = false}) async {
    final normalizedId = widget.orderId.trim();
    if (normalizedId.isEmpty) {
      final l10n = AppLocalizations.of(context);
      if (!mounted) return;
      setState(() {
        _detail = null;
        _detailError = l10n.translate('common.no_data');
        _isInitialLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      if (!refreshOnly || _detail == null) {
        _isInitialLoading = true;
      }
      _detailError = null;
      _periodsLoaded = false;
    });

    try {
      await context
          .read<OrderBloc>()
          .repository
          .fetchOrderSWR(
            orderId: normalizedId,
            onData: (order, _) {
              if (!mounted) return;
              setState(() {
                _detail = order;
                _detailError = null;
                _isInitialLoading = false;
              });
              _loadAccountingPeriods(order.locationId);
            },
            onError: (error) {
              if (!mounted) return;
              setState(() {
                _detailError = ApiErrorMessageParser.parse(error);
                _isInitialLoading = false;
              });
            },
          )
          .timeout(const Duration(seconds: 35));
    } on TimeoutException {
      final l10n = AppLocalizations.of(context);
      if (!mounted) return;
      setState(() {
        _detailError = l10n.translate('order.detail_load_failed');
        _isInitialLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _detailError = ApiErrorMessageParser.parse(error);
        _isInitialLoading = false;
      });
    }

    if (!mounted) return;
    if (_detail == null && _detailError == null) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _cancelOrder(OrderEntity detail) async {
    if (_isCancelling) return;

    final allowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.orderManagement,
    );
    if (!allowed) return;

    final l10n = AppLocalizations.of(context);
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('order.cancel_confirm_title')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.translate('order.cancel_confirm_message')),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return l10n.translate('order.cancel_reason_required');
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: l10n.translate('order.detail_cancel_reason'),
                  hintText: l10n.translate('order.detail_cancel_reason'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }
              Navigator.pop(context, true);
            },
            child: Text(l10n.translate('common.confirm')),
          ),
        ],
      ),
    );
    final cancelReason = reasonController.text.trim();
    reasonController.dispose();

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await context.read<OrderBloc>().repository.cancelOrder(
        detail.id,
        cancelReason: cancelReason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.translate('order.cancel_success'))),
        );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ApiErrorMessageParser.parse(e))));
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  Future<void> _completeOrder(
    OrderEntity detail, {
    bool confirmLowStock = false,
  }) async {
    if (_isPublishing) return;

    final allowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.orderManagement,
    );
    if (!allowed) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _isPublishing = true);

    try {
      final repository = context.read<OrderBloc>().repository;
      await repository.completeOrder(
        detail.id,
        confirmLowStock: confirmLowStock,
      );

      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.translate('order.complete_success'),
        type: AppSnackBarType.success,
      );

      unawaited(_loadDetailSWR(refreshOnly: true));
      context.read<OrderBloc>().add(
        RefreshOrdersRequested(locationId: detail.locationId),
      );
    } catch (e) {
      if (!mounted) return;

      if (e is OrderConfirmationRequiredException) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.translate('order_create.confirm_continue_title')),
            content: Text(
              l10n.translate('order_create.confirm_continue_message'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.translate('common.cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.translate('common.confirm')),
              ),
            ],
          ),
        );

        if (confirm == true) {
          setState(() => _isPublishing = false);
          await _completeOrder(detail, confirmLowStock: true);
        }
        return;
      }

      AppSnackBar.show(
        context,
        message: ApiErrorMessageParser.parse(e),
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  InvoiceTemplateEntity _getTemplate() {
    final state = context.read<InvoiceTemplateBloc>().state;
    return state is InvoiceTemplateLoaded
        ? state.template
        : InvoiceTemplateEntity.empty();
  }

  String _pdfFormat(String text) => StringUtils.removeDiacritics(text);
  String _formatMoney(num? amount) => CurrencyFormatter.formatVND(amount);
  String _pdfCurrency(num? amount) => _formatMoney(amount).replaceAll('đ', ' VND');

  String _formatQuantityWithUnit(double quantity, String? unitName) {
    final unit = unitName?.trim() ?? '';
    final quantityText = quantity % 1 == 0 ? quantity.toStringAsFixed(1) : quantity.toString();
    return unit.isNotEmpty ? '$quantityText $unit' : quantityText;
  }

  String _translateOrFallback(AppLocalizations l10n, String key, String fallback) {
    final t = l10n.translate(key);
    if (t.trim().isEmpty || t == key) return fallback;
    return t;
  }

  List<Map<String, String>> _buildColumns(
    InvoiceTemplateEntity template,
    AppLocalizations l10n,
  ) {
    final columns = <Map<String, String>>[];
    if (template.showStt) {
      columns.add({'key': 'stt', 'label': _pdfFormat('STT')});
    }
    if (template.showItemName) {
      columns.add({
        'key': 'name',
        'label': _pdfFormat(_translateOrFallback(l10n, 'invoice_item_name', 'Tên hàng')),
      });
    }
    if (template.showQuantity) {
      columns.add({
        'key': 'qty',
        'label': _pdfFormat(_translateOrFallback(l10n, 'quantity', 'SL')),
      });
    }
    if (template.showUnit) {
      columns.add({
        'key': 'unit',
        'label': _pdfFormat(_translateOrFallback(l10n, 'invoice_unit', 'ĐVT')),
      });
    }
    if (template.showUnitPrice) {
      columns.add({
        'key': 'unitPrice',
        'label': _pdfFormat(_translateOrFallback(l10n, 'detail_unit_price_label', 'Đơn giá')),
      });
    }
    if (template.showItemDiscount) {
      columns.add({
        'key': 'discount',
        'label': _pdfFormat(_translateOrFallback(l10n, 'invoice_item_discount', 'Chiết khấu')),
      });
    }
    if (template.showItemVat) {
      columns.add({
        'key': 'vat',
        'label': _pdfFormat(_translateOrFallback(l10n, 'invoice_tax', 'VAT')),
      });
    }
    if (template.showItemTotalAmount) {
      columns.add({
        'key': 'total',
        'label': _pdfFormat(_translateOrFallback(l10n, 'invoice_item_total', 'T.Tiền')),
      });
    }
    if (columns.isEmpty) {
      columns.addAll([
        {
          'key': 'name',
          'label': _pdfFormat(_translateOrFallback(l10n, 'invoice_item_name', 'Tên hàng')),
        },
        {'key': 'qty', 'label': _pdfFormat(_translateOrFallback(l10n, 'quantity', 'SL'))},
        {
          'key': 'unitPrice',
          'label': _pdfFormat(_translateOrFallback(l10n, 'detail_unit_price_label', 'Đơn giá')),
        },
        {
          'key': 'total',
          'label': _pdfFormat(_translateOrFallback(l10n, 'invoice_item_total', 'T.Tiền')),
        },
      ]);
    }
    return columns;
  }

  List<String> _buildRow(
    int index,
    dynamic item,
    List<Map<String, String>> columns,
  ) {
    return columns.map((column) {
      switch (column['key']) {
        case 'stt':
          return (index + 1).toString();
        case 'name':
          return _pdfFormat(item.productName);
        case 'qty':
          return item.quantity.toString();
        case 'unit':
          return _pdfFormat(
            item.unitName?.trim().isNotEmpty == true ? item.unitName! : '-',
          );
        case 'unitPrice':
          return _pdfCurrency(item.price);
        case 'discount':
          return '${item.discount.toStringAsFixed(0)}%';
        case 'vat':
          return _pdfCurrency(0);
        case 'total':
          return _pdfCurrency(item.total);
        default:
          return '';
      }
    }).toList();
  }

  Future<File> _buildPdfFile(
    OrderEntity detail,
    InvoiceTemplateEntity template,
  ) async {
    final l10n = AppLocalizations.of(context);
    final pdf = pw.Document();
    final columns = _buildColumns(template, l10n);
    final itemRows = <List<String>>[];
    for (var index = 0; index < detail.items.length; index++) {
      itemRows.add(_buildRow(index, detail.items[index], columns));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Business Info (Seller)
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  _pdfFormat(
                    template.businessName.isNotEmpty ? template.businessName : '',
                  ),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (template.businessAddress.isNotEmpty)
                  pw.Text(
                    _pdfFormat(template.businessAddress),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                if (template.businessPhone.isNotEmpty)
                  pw.Text(
                    'SDT: ${template.businessPhone}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              _pdfFormat(_translateOrFallback(l10n, 'invoice_title', 'HÓA ĐƠN BÁN HÀNG')),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                  pw.Text(
                    _pdfFormat(
                      '${_translateOrFallback(l10n, 'invoice_order_code', 'Mã đơn')}: ${detail.orderCode.isNotEmpty ? detail.orderCode : detail.id}',
                    ),
                  ),
                  pw.Text(
                    _pdfFormat(
                      '${_translateOrFallback(l10n, 'invoice_date', 'Ngày')}: ${CurrencyFormatter.formatDate(detail.createdAt)}',
                    ),
                  ),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                  if (template.showCustomerName)
                    pw.Text(
                      _pdfFormat(
                        '${_translateOrFallback(l10n, 'invoice_customer', 'Khách hàng')}: ${detail.customerName?.isNotEmpty == true ? detail.customerName : l10n.translate('order_create.customer_walkin')}',
                      ),
                    ),
                  if (template.showCustomerPhone)
                    pw.Text(
                      _pdfFormat(
                        '${_translateOrFallback(l10n, 'invoice_phone', 'SĐT')}: ${detail.customerPhone?.isNotEmpty == true ? detail.customerPhone : '-'}',
                      ),
                    ),
                  ],
                ),
              ),
          ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: columns.map((column) => column['label']!).toList(),
            data: itemRows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (template.showSubTotal)
                  pw.Text(
                    _pdfFormat('${_translateOrFallback(l10n, 'invoice_subtotal', 'Tạm tính')}: ${_pdfCurrency(detail.subtotal)}'),
                  ),
                if (template.showTotalDiscount)
                  pw.Text(
                    _pdfFormat(
                      '${_translateOrFallback(l10n, 'invoice_discount', 'Giảm giá')}: ${_pdfCurrency(detail.discountAmount)}',
                    ),
                  ),
                if (template.showTotalVat)
                  pw.Text(_pdfFormat('${_translateOrFallback(l10n, 'invoice_tax', 'VAT')}: ${_pdfCurrency(detail.taxAmount)}')),
                pw.Text(
                  _pdfFormat(
                    '${_translateOrFallback(l10n, 'invoice_total', 'Tổng thanh toán')}: ${_pdfCurrency(detail.totalAmount)}',
                  ),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (template.showFooterNote &&
              template.footerNoteText.trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              _pdfFormat(template.footerNoteText.trim()),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
          pw.SizedBox(height: 24),
          if (template.showSignature)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  _pdfFormat(
                    _translateOrFallback(
                      l10n,
                      'invoice_buyer_signature',
                      'Người mua hàng\n(Ký, ghi rõ họ tên)',
                    ),
                  ),
                ),
                pw.Text(
                  _pdfFormat(
                    _translateOrFallback(
                      l10n,
                      'invoice_seller_signature',
                      'Người bán hàng\n(Ký, ghi rõ họ tên)',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/invoice_${detail.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save(), flush: true);
    return file;
  }

  Future<void> _shareInvoice(OrderEntity detail) async {
    if (_isInvoiceActionInProgress) return;
    setState(() => _isInvoiceActionInProgress = true);
    final template = _getTemplate();
    try {
      final file = await _buildPdfFile(detail, template);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: _pdfFormat(
          'Hoa don ban hang #${detail.orderCode.isNotEmpty ? detail.orderCode : detail.id}',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isInvoiceActionInProgress = false);
      }
    }
  }

  Future<void> _downloadInvoice(OrderEntity detail) async {
    if (_isInvoiceActionInProgress) return;
    setState(() => _isInvoiceActionInProgress = true);
    final l10n = AppLocalizations.of(context);
    try {
      final template = _getTemplate();
      final file = await _buildPdfFile(detail, template);

      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final copiedFile = File(
            '${downloadDir.path}/${file.path.split('/').last}',
          );
          await file.copy(copiedFile.path);
        }
      }

      if (!mounted) return;
      AppSnackBar.show(
        context,
        message:
            l10n.translate('order_payment.save_pdf_success') +
            (Platform.isAndroid ? ' (Downloads)' : ''),
        type: AppSnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: ApiErrorMessageParser.parse(e),
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isInvoiceActionInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleText = l10n.translate('order.detail_title');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        title: Text(titleText),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.black,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const AppSyncStatusText(),
      ),
      body: SafeArea(
        top: false,
        child: BlocListener<OrderBloc, OrderState>(
          listener: (context, state) {
            if (state is OrderPublished || state is OrderUpdated) {
              final orderId = state is OrderPublished
                  ? state.order.id
                  : (state as OrderUpdated).order.id;
              if (orderId == widget.orderId) {
                unawaited(_loadDetailSWR(refreshOnly: true));
              }
            } else if (state is OrderError) {
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
            }
          },
          child: Builder(
            builder: (context) {
              if (_isInitialLoading && _detail == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final detail = _detail;
              if (detail == null) {
                return Center(
                  child: Text(_detailError ?? l10n.translate('common.no_data')),
                );
              }

              return Column(
                children: [
                if (detail.status.toLowerCase() == 'completed')
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isInvoiceActionInProgress
                                ? null
                                : () => _shareInvoice(detail),
                            icon: const Icon(Icons.share_outlined),
                            label: Text(
                              l10n.translate('order_payment.share_invoice'),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isInvoiceActionInProgress
                                ? null
                                : () => _downloadInvoice(detail),
                            icon: const Icon(Icons.download_outlined),
                            label: Text(
                              l10n.translate('order_payment.download_invoice'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (detail.isPending ||
                    (detail.isPublished && !_hideCancelForCompletedOrder(detail))) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: (_isCancelling || _isPublishing)
                                ? null
                                : () => _cancelOrder(detail),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                            icon: _isCancelling
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cancel),
                            label: Text(l10n.translate('order.action_cancel')),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if ((detail.isPending || (detail.isPublished && !_hideCancelForCompletedOrder(detail))) && _canEditOrder(detail))
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (_isCancelling || _isPublishing)
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => OrderFormScreen(
                                            inputType: 'manual',
                                            initialOrder: detail,
                                            pendingOrderId: detail.id,
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.edit),
                              label: Text(l10n.translate('order.action_edit')),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (detail.isPending)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_isPublishing || _isCancelling)
                              ? null
                              : () => _completeOrder(detail),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          icon: _isPublishing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle),
                          label: Text(l10n.translate('order.action_publish')),
                        ),
                      ),
                    ),
                ],
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.orderCode.trim().isNotEmpty
                                    ? detail.orderCode
                                    : l10n.translate(
                                        'order.order_number',
                                        params: {'number': detail.id},
                                      ),
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '${l10n.translate('accounting.document_number')}: ${detail.documentNumber?.trim().isNotEmpty == true ? detail.documentNumber!.trim() : ''}',
                              ),
                              Text(
                                '${l10n.translate('order.detail_status')}: ${detail.statusLabel ?? (() {
                                  final refState = context.read<ReferenceBloc>().state;
                                  if (refState is ReferenceLoaded) {
                                    final orderStatuses = refState.references['orderStatuses'] ?? <ReferenceItem>[];
                                    return orderStatuses.getLabelByCode(detail.status);
                                  }
                                  return detail.status;
                                })()} ',
                              ),
                              Text(
                                '${l10n.translate('order.detail_customer_name')}: ${((detail.customerName ?? '').trim().isNotEmpty) ? detail.customerName : l10n.translate('order_create.customer_walkin')}',
                              ),
                              if ((detail.customerPhone ?? '').trim().isNotEmpty)
                                Text(
                                  '${l10n.translate('order.detail_customer_phone')}: ${detail.customerPhone}',
                                ),
                              Text(
                                '${l10n.translate('order.detail_created_at')}: ${_formatDateTime(detail.createdAt)}',
                              ),
                              Text(
                                '${l10n.translate('order.detail_updated_at')}: ${_formatDateTime(detail.updatedAt)}',
                              ),
                              Text(
                                '${l10n.translate('order.detail_created_by')}: ${detail.createdByProfileFullName ?? detail.createdByProfileId ?? '-'}',
                              ),
                              if (detail.completedAt != null)
                                Text(
                                  '${l10n.translate('order.detail_completed_at')}: ${_formatDateTime(detail.completedAt!)}',
                                ),
                              if (detail.cancelledAt != null)
                                Text(
                                  '${l10n.translate('order.detail_cancelled_at')}: ${_formatDateTime(detail.cancelledAt!)}',
                                ),
                              if (detail.status.toLowerCase() == 'cancelled' && (detail.cancelReason ?? '').trim().isNotEmpty)
                                Text(
                                  '${l10n.translate('order.detail_cancel_reason')}: ${detail.cancelReason}',
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.translate('order.detail_payment_section'),
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '${l10n.translate('order.detail_cash_amount')}: ${_formatMoney(detail.cashAmount)}',
                              ),
                              Text(
                                '${l10n.translate('order.detail_bank_amount')}: ${_formatMoney(detail.bankAmount)}',
                              ),
                              Text(
                                '${l10n.translate('order.detail_debt_amount')}: ${_formatMoney(detail.debtAmount)}',
                              ),
                              const Divider(height: 20),
                              Text(
                                '${l10n.translate('order.detail_subtotal')}: ${_formatMoney(detail.subtotal)}',
                              ),
                              Text(
                                '${l10n.translate('order.detail_discount')}: ${_formatMoney(detail.discountAmount)}',
                              ),
                              if ((detail.taxAmount).round() != 0)
                                Text(
                                  '${l10n.translate('order.detail_tax')}: ${_formatMoney(detail.taxAmount)}',
                                ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${l10n.translate('order.detail_total')}: ${_formatMoney(detail.totalAmount)}',
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.translate('order.detail_items_section'),
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...detail.items.map(
                        (item) => Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            title: Text(item.productName),
                            subtitle: Text(
                                '${l10n.translate('order.detail_qty_label')}: ${_formatQuantityWithUnit(item.quantity, item.unitName)} | ${l10n.translate('order.detail_unit_price_label')}: ${_formatMoney(item.price)}',
                            ),
                            trailing: Text(
                              _formatMoney(
                                item.price * item.quantity,
                              ),
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
