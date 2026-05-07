import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/utils/action_guard.dart';
import '../../../invoice_template/domain/entities/invoice_template_entity.dart';
import '../../../invoice_template/presentation/bloc/invoice_template_bloc.dart';
import '../../../invoice_template/presentation/bloc/invoice_template_event.dart';
import '../../../invoice_template/presentation/bloc/invoice_template_state.dart';
import '../../../invoice_template/presentation/widgets/invoice_preview_widget.dart';
import '../../../location/domain/entities/location_entity.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_state.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';
import '../../domain/entities/order_entity.dart';
import '../../../../shared/utils/string_utils.dart';

class OrderInvoicePreviewScreen extends StatefulWidget {
  final OrderEntity order;

  const OrderInvoicePreviewScreen({super.key, required this.order});

  @override
  State<OrderInvoicePreviewScreen> createState() =>
      _OrderInvoicePreviewScreenState();
}

class _OrderInvoicePreviewScreenState extends State<OrderInvoicePreviewScreen> {
  static const String _featureReportExport =
      SubscriptionFeatureCodes.reportExport;
  final ActionGuard _exportGuard = ActionGuard();

  bool get _shouldReturnToOrderListOnBack =>
      widget.order.status.toLowerCase() == 'completed';

  LocationEntity? _findActiveLocation(
    List<LocationEntity> locations,
    String? businessId,
  ) {
    if ((businessId ?? '').isNotEmpty) {
      for (final location in locations) {
        if (location.isActive && location.id == businessId) {
          return location;
        }
      }
    }

    for (final location in locations) {
      if (location.isActive) {
        return location;
      }
    }

    return locations.isNotEmpty ? locations.first : null;
  }

  InvoiceTemplateEntity _mergeTemplateWithCurrentLocation(
    InvoiceTemplateEntity template,
  ) {
    final locationState = context.read<LocationBloc>().state;
    if (locationState is! LocationsLoaded) {
      return template;
    }

    final currentLocation = _findActiveLocation(
      locationState.locations,
      context.read<BusinessContext>().currentBusinessId,
    );
    if (currentLocation == null) return template;

    return template.copyWith(
      businessName: currentLocation.name,
      businessAddress: currentLocation.fullAddress,
      businessPhone: currentLocation.phone,
      businessTaxCode: currentLocation.taxCode ?? '',
    );
  }

  @override
  void initState() {
    super.initState();
    // Trigger load template khi screen mở
    context.read<InvoiceTemplateBloc>().add(const LoadInvoiceTemplateRequested());
  }

  void _handleBack(BuildContext context) {
    if (_shouldReturnToOrderListOnBack) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.orderList,
        (route) => false,
      );
      return;
    }

    Navigator.pop(context);
  }

  String _pdfFormat(String text) => StringUtils.removeDiacritics(text);
  String _pdfCurrency(num? amount) =>
      '${CurrencyFormatter.formatNumber(amount?.round() ?? 0)} VND';

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
        'label': _pdfFormat(l10n.translate('invoice_tax')),
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
          return CurrencyFormatter.formatNumber(item.discount.round());
        case 'vat':
          return _pdfCurrency(0);
        case 'total':
          return _pdfCurrency((item.price * item.quantity - item.discount).clamp(0, double.infinity));
        default:
          return '';
      }
    }).toList();
  }

  Future<File> _buildPdfFile(
    BuildContext context,
    InvoiceTemplateEntity template,
  ) async {
    final l10n = AppLocalizations.of(context);
    final pdf = pw.Document();
    final columns = _buildColumns(template, l10n);
    final itemRows = <List<String>>[];
    for (var i = 0; i < widget.order.items.length; i++) {
      itemRows.add(_buildRow(i, widget.order.items[i], columns));
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

          // Order & Customer Info
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                  pw.Text(
                    _pdfFormat(
                      '${_translateOrFallback(l10n, 'invoice_order_code', 'Mã đơn')}: ${widget.order.orderCode.isNotEmpty ? widget.order.orderCode : widget.order.id}',
                    ),
                  ),
                  pw.Text(
                    _pdfFormat(
                      '${_translateOrFallback(l10n, 'invoice_date', 'Ngày')}: ${CurrencyFormatter.formatDate(widget.order.createdAt)}',
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
                        '${_translateOrFallback(l10n, 'invoice_customer', 'Khách hàng')}: ${widget.order.customerName?.isNotEmpty == true ? widget.order.customerName : l10n.translate('order_create.customer_walkin')}',
                      ),
                    ),
                  if (template.showCustomerPhone)
                    pw.Text(
                      _pdfFormat(
                        '${_translateOrFallback(l10n, 'invoice_phone', 'SĐT')}: ${widget.order.customerPhone?.isNotEmpty == true ? widget.order.customerPhone : '-'}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: columns.map((c) => c['label']!).toList(),
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
                    _pdfFormat(
                      '${_translateOrFallback(l10n, 'invoice_subtotal', 'Tạm tính')}: ${_pdfCurrency(widget.order.subtotal)}',
                    ),
                  ),
                if (template.showTotalDiscount)
                  pw.Text(
                    _pdfFormat(
                      '${_translateOrFallback(l10n, 'invoice_discount', 'Giảm giá')}: ${_pdfCurrency(widget.order.discountAmount)}',
                    ),
                  ),
                if (template.showTotalVat)
                  pw.Text(
                    _pdfFormat(
                      '${_translateOrFallback(l10n, 'invoice_tax', 'VAT')}: ${_pdfCurrency(widget.order.taxAmount)}',
                    ),
                  ),
                pw.Text(
                  _pdfFormat(
                    '${_translateOrFallback(l10n, 'invoice_total', 'Tổng thanh toán')}: ${_pdfCurrency(widget.order.totalAmount)}',
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
      '${directory.path}/invoice_${widget.order.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save(), flush: true);
    return file;
  }

  Future<void> _sharePdf(
    BuildContext context,
    InvoiceTemplateEntity template,
  ) async {
    final file = await _buildPdfFile(context, template);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: _pdfFormat(
        'Hoa don ban hang #${widget.order.orderCode.isNotEmpty ? widget.order.orderCode : widget.order.id}',
      ),
    );
  }

  Future<void> _downloadInvoice(
    BuildContext context,
    InvoiceTemplateEntity template,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final file = await _buildPdfFile(context, template);

      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final newFile = File(
            '${downloadDir.path}/${file.path.split('/').last}',
          );
          await file.copy(newFile.path);
        }
      }

      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message:
            l10n.translate('order_payment.save_pdf_success') +
            (Platform.isAndroid ? ' (Downloads)' : ''),
        type: AppSnackBarType.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: ApiErrorMessageParser.parse(e),
        type: AppSnackBarType.error,
      );
    }
  }

  Future<bool> _checkExportFeature(BuildContext context) async {
    return SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: _featureReportExport,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_shouldReturnToOrderListOnBack,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: Text(l10n.translate('order_payment.invoice_preview')),
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBack(context),
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: SafeArea(
          child: BlocBuilder<InvoiceTemplateBloc, InvoiceTemplateState>(
            builder: (context, state) {
              final template = state is InvoiceTemplateLoaded
                  ? state.template
                  : InvoiceTemplateEntity.empty();
              final effectiveTemplate = _mergeTemplateWithCurrentLocation(
                template,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCard(l10n),
                    const SizedBox(height: AppSpacing.md),
                    InvoicePreviewWidget(
                      businessName: effectiveTemplate.businessName,
                      businessAddress: effectiveTemplate.businessAddress,
                      businessPhone: effectiveTemplate.businessPhone,
                      order: widget.order,
                      showStt: effectiveTemplate.showStt,
                      showItemName: effectiveTemplate.showItemName,
                      showQuantity: effectiveTemplate.showQuantity,
                      showUnit: effectiveTemplate.showUnit,
                      showUnitPrice: effectiveTemplate.showUnitPrice,
                      showItemDiscount: effectiveTemplate.showItemDiscount,
                      showItemVat: effectiveTemplate.showItemVat,
                      showItemTotalAmount: effectiveTemplate.showItemTotalAmount,
                      showCustomerName: effectiveTemplate.showCustomerName,
                      showCustomerPhone: effectiveTemplate.showCustomerPhone,
                      showCustomerEmail: effectiveTemplate.showCustomerEmail,
                      showCustomerTaxCode: effectiveTemplate.showCustomerTaxCode,
                      showTotalVat: effectiveTemplate.showTotalVat,
                      showTotalDiscount: effectiveTemplate.showTotalDiscount,
                      showSubTotal: effectiveTemplate.showSubTotal,
                      showFooterNote: effectiveTemplate.showFooterNote,
                      footerNoteText: effectiveTemplate.footerNoteText,
                      showSignature: effectiveTemplate.showSignature,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _exportGuard.run(() async {
                                final allowed = await _checkExportFeature(
                                  context,
                                );
                                if (!allowed) return;
                                await _sharePdf(context, effectiveTemplate);
                              });
                            },
                            icon: const Icon(Icons.share_outlined),
                            label: Text(
                              l10n.translate('order_payment.share_invoice'),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _exportGuard.run(() async {
                                final allowed = await _checkExportFeature(
                                  context,
                                );
                                if (!allowed) return;
                                await _downloadInvoice(context, effectiveTemplate);
                              });
                            },
                            icon: const Icon(Icons.download_outlined),
                            label: Text(
                              l10n.translate('order_payment.download_invoice'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.orderList,
                          (route) => false,
                        ),
                        child: Text(l10n.translate('order_payment.back_to_list')),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.translate('order.detail_order_id')}: ${widget.order.orderCode.isNotEmpty ? widget.order.orderCode : widget.order.id}',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${l10n.translate('order.detail_status')}:'),
                Text(
                  widget.order.statusLabel ??
                      (widget.order.status == 'pending'
                          ? l10n.translate('order_payment.pending_confirmation')
                          : widget.order.status.toUpperCase()),
                  style: TextStyle(
                    color: widget.order.status == 'completed'
                        ? AppColors.success
                        : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${_translateOrFallback(l10n, 'invoice_customer', 'Khách hàng')}: ${widget.order.customerName?.isNotEmpty == true ? widget.order.customerName : l10n.translate('order_create.customer_walkin')}',
            ),
            if (widget.order.customerPhone?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${_translateOrFallback(l10n, 'invoice_phone', 'SĐT')}: ${widget.order.customerPhone}',
              ),
            ],
            const Divider(height: AppSpacing.lg),
            Text(
              '${l10n.translate('order_payment.order_total')}: ${CurrencyFormatter.formatVND(widget.order.totalAmount)}',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
