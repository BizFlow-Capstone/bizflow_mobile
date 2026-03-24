import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../invoice_template/domain/entities/invoice_template_entity.dart';
import '../../../invoice_template/presentation/bloc/invoice_template_bloc.dart';
import '../../../invoice_template/presentation/bloc/invoice_template_state.dart';
import '../../../invoice_template/presentation/widgets/invoice_preview_widget.dart';
import '../../domain/entities/order_entity.dart';

class OrderInvoicePreviewScreen extends StatelessWidget {
  final OrderEntity order;

  const OrderInvoicePreviewScreen({
    super.key,
    required this.order,
  });

  Future<File> _buildPdfFile() async {
    final pdf = pw.Document();
    final itemRows = order.items
        .map(
          (item) => [
            item.productName,
            item.quantity.toString(),
            CurrencyFormatter.formatVND(item.price),
            CurrencyFormatter.formatVND(item.price * item.quantity),
          ],
        )
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'HOA DON TAM TINH',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Ma don: ${order.id}'),
          pw.Text('Trang thai: ${order.status}'),
          pw.Text('Dia diem: ${order.locationName}'),
          pw.Text('Ngay tao: ${order.createdAt.toLocal()}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const ['San pham', 'SL', 'Don gia', 'Thanh tien'],
            data: itemRows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Tong thanh toan: ${CurrencyFormatter.formatVND(order.totalAmount)}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
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

  Future<void> _sharePdf(BuildContext context) async {
    final file = await _buildPdfFile();
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Hoa don tam tinh #${order.id}',
    );
  }

  Future<void> _downloadInvoice(BuildContext context) async {
    final file = await _buildPdfFile();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã lưu PDF: ${file.path}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Hóa đơn tạm tính'),
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
                  _buildSummaryCard(),
                  const SizedBox(height: AppSpacing.md),
                  InvoicePreviewWidget(
                    businessName: template.businessName,
                    businessAddress: template.businessAddress,
                    businessPhone: template.businessPhone,
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
                          onPressed: () => _sharePdf(context),
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Chia sẻ'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadInvoice(context),
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Tải xuống'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn hàng #${order.id}',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Địa điểm: ${order.locationName}'),
            const SizedBox(height: AppSpacing.xs),
            Text('Trạng thái: ${order.status}'),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tổng tiền: ${CurrencyFormatter.formatVND(order.totalAmount)}',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
