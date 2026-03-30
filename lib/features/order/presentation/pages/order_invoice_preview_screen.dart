import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../invoice_template/domain/entities/invoice_template_entity.dart';
import '../../../invoice_template/presentation/bloc/invoice_template_bloc.dart';
import '../../../invoice_template/presentation/bloc/invoice_template_state.dart';
import '../../../invoice_template/presentation/widgets/invoice_preview_widget.dart';
import '../../domain/entities/order_entity.dart';
import '../../../../shared/utils/string_utils.dart';

class OrderInvoicePreviewScreen extends StatelessWidget {
  final OrderEntity order;

  const OrderInvoicePreviewScreen({super.key, required this.order});

  String _pdfFormat(String text) => StringUtils.removeDiacritics(text);
  String _pdfCurrency(num? amount) =>
      '${CurrencyFormatter.formatNumber(amount?.round() ?? 0)} VND';

  Future<File> _buildPdfFile(InvoiceTemplateEntity template) async {
    final pdf = pw.Document();
    final itemRows = order.items
        .map(
          (item) => [
            _pdfFormat(item.productName),
            item.quantity.toString(),
            _pdfCurrency(item.price),
            _pdfCurrency(item.price * item.quantity),
          ],
        )
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Business Info (Seller)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                _pdfFormat(template.businessName.isNotEmpty
                    ? template.businessName
                    : 'BIZFLOW STORE'),
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              if (template.businessAddress.isNotEmpty)
                pw.Text(_pdfFormat(template.businessAddress),
                    style: const pw.TextStyle(fontSize: 10)),
              if (template.businessPhone.isNotEmpty)
                pw.Text('SDT: ${template.businessPhone}',
                    style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),

          pw.Center(
            child: pw.Text(
              _pdfFormat('HOA DON BAN HANG'),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 12),

          // Order & Customer Info
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _pdfFormat(
                      'Ma don: ${order.orderCode.isNotEmpty ? order.orderCode : order.id}',
                    ),
                  ),
                  pw.Text(_pdfFormat('Ngay: ${CurrencyFormatter.formatDate(order.createdAt)}')),
                  pw.Text(_pdfFormat('Dia diem: ${order.locationName}')),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    _pdfFormat(
                      'Khach hang: ${order.customerName?.isNotEmpty == true ? order.customerName : "Khach le"}',
                    ),
                  ),
                  if (order.customerPhone?.isNotEmpty == true)
                    pw.Text('SDT: ${order.customerPhone}'),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['San pham', 'SL', 'Don gia', 'Thanh tien'],
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
                pw.Text(
                  _pdfFormat('Tong thanh toan: ${_pdfCurrency(order.totalAmount)}'),
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(_pdfFormat('Nguoi mua hang')),
              pw.Text(_pdfFormat('Nguoi ban hang')),
            ],
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/invoice_${order.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save(), flush: true);
    return file;
  }

  Future<void> _sharePdf(BuildContext context, InvoiceTemplateEntity template) async {
    final file = await _buildPdfFile(template);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: _pdfFormat(
        'Hoa don ban hang #${order.orderCode.isNotEmpty ? order.orderCode : order.id}',
      ),
    );
  }

  Future<void> _downloadInvoice(BuildContext context, InvoiceTemplateEntity template) async {
    final l10n = AppLocalizations.of(context);
    try {
      final file = await _buildPdfFile(template);

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
        message: e.toString(),
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(l10n.translate('order_payment.invoice_preview')),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: BlocBuilder<InvoiceTemplateBloc, InvoiceTemplateState>(
          builder: (context, state) {
            final template = state is InvoiceTemplateLoaded
                ? state.template
                : InvoiceTemplateEntity.empty();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCard(l10n),
                  const SizedBox(height: AppSpacing.md),
                  InvoicePreviewWidget(
                    businessName: template.businessName,
                    businessAddress: template.businessAddress,
                    businessPhone: template.businessPhone,
                    order: order,
                    showStt: template.showStt,
                    showItemName: template.showItemName,
                    showQuantity: template.showQuantity,
                    showUnit: template.showUnit,
                    showUnitPrice: template.showUnitPrice,
                    showItemDiscount: template.showItemDiscount,
                    showItemVat: template.showItemVat,
                    showItemTotalAmount: template.showItemTotalAmount,
                    showCustomerName: template.showCustomerName,
                    showCustomerPhone: template.showCustomerPhone,
                    showCustomerAddress: template.showCustomerAddress,
                    showCustomerEmail: template.showCustomerEmail,
                    showCustomerTaxCode: template.showCustomerTaxCode,
                    showTotalVat: template.showTotalVat,
                    showTotalDiscount: template.showTotalDiscount,
                    showSubTotal: template.showSubTotal,
                    showFooterNote: template.showFooterNote,
                    footerNoteText: template.footerNoteText,
                    showSignature: template.showSignature,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _sharePdf(context, template),
                          icon: const Icon(Icons.share_outlined),
                          label: Text(
                            l10n.translate('order_payment.share_invoice'),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadInvoice(context, template),
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
                      onPressed: () => Navigator.popUntil(
                        context,
                        ModalRoute.withName('/home'),
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
              '${l10n.translate('order.detail_order_id')}: ${order.orderCode.isNotEmpty ? order.orderCode : order.id}',
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
                  order.status == 'pending'
                      ? l10n.translate('order_payment.pending_confirmation')
                      : order.status.toUpperCase(),
                  style: TextStyle(
                    color: order.status == 'completed'
                        ? AppColors.success
                        : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.translate('order.detail_location')}: ${order.locationName}',
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.translate('order.detail_customer_name')}: ${order.customerName?.isNotEmpty == true ? order.customerName : l10n.translate('order_create.customer_walkin')}',
            ),
            if (order.customerPhone?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.translate('order.detail_customer_phone')}: ${order.customerPhone}',
              ),
            ],
            const Divider(height: AppSpacing.lg),
            Text(
              '${l10n.translate('order_payment.order_total')}: ${CurrencyFormatter.formatVND(order.totalAmount)}',
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
