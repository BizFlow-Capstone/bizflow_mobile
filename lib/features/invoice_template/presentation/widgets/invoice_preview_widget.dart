import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../order/domain/entities/order_entity.dart';

class InvoicePreviewWidget extends StatelessWidget {
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final OrderEntity? order;
  final bool showStt;
  final bool showItemName;
  final bool showQuantity;
  final bool showUnit;
  final bool showUnitPrice;
  final bool showItemDiscount;
  final bool showItemVat;
  final bool showItemTotalAmount;
  final bool showCustomerName;
  final bool showCustomerPhone;
  final bool showCustomerEmail;
  final bool showCustomerTaxCode;
  final bool showTotalVat;
  final bool showTotalDiscount;
  final bool showSubTotal;
  final bool showFooterNote;
  final String footerNoteText;
  final bool showSignature;

  const InvoicePreviewWidget({
    super.key,
    required this.businessName,
    required this.businessAddress,
    required this.businessPhone,
    this.order,
    this.showStt = true,
    this.showItemName = true,
    this.showQuantity = true,
    this.showUnit = true,
    this.showUnitPrice = true,
    this.showItemDiscount = false,
    this.showItemVat = false,
    this.showItemTotalAmount = true,
    this.showCustomerName = true,
    this.showCustomerPhone = true,
    this.showCustomerEmail = false,
    this.showCustomerTaxCode = false,
    this.showTotalVat = true,
    this.showTotalDiscount = true,
    this.showSubTotal = true,
    this.showFooterNote = true,
    this.footerNoteText = '',
    this.showSignature = true,
  });

  String _translateOrFallback(
    AppLocalizations l10n,
    String key,
    String fallback,
  ) {
    final translated = l10n.translate(key);
    if (translated.trim().isEmpty || translated == key) return fallback;
    return translated;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Text(
            businessName.isNotEmpty ? businessName : l10n.translate('app_name'),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (businessAddress.isNotEmpty)
            Text(
              businessAddress,
              style: AppTextStyles.labelSmall,
              textAlign: TextAlign.center,
            ),
          if (businessPhone.isNotEmpty)
            Text(
              'SĐT: $businessPhone',
              style: AppTextStyles.labelSmall,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 12),

          Text(
            _translateOrFallback(l10n, 'invoice_title', 'HÓA ĐƠN BÁN HÀNG'),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            order != null
                ? '${_translateOrFallback(l10n, 'invoice_order_code', 'Mã đơn')}: ${order!.orderCode.isNotEmpty ? order!.orderCode : order!.id} - ${_translateOrFallback(l10n, 'invoice_date', 'Ngày')}: ${CurrencyFormatter.formatDate(order!.createdAt)}'
                : '${_translateOrFallback(l10n, 'invoice_order_code', 'Mã đơn')}: HD000123 - ${_translateOrFallback(l10n, 'invoice_date', 'Ngày')}: 12/03/2026',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 12),
          const Divider(),

          // Customer info
          if (showCustomerName ||
              showCustomerPhone ||
              showCustomerEmail ||
              showCustomerTaxCode) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showCustomerName)
                        Text(
                          '${_translateOrFallback(l10n, 'invoice_customer', 'Khách hàng')}: ${order != null ? (order!.customerName?.isNotEmpty == true ? order!.customerName : l10n.translate('order_create.customer_walkin')) : "Nguyễn Văn A"}',
                          style: AppTextStyles.labelSmall,
                        ),
                      if (showCustomerPhone)
                        Text(
                          '${_translateOrFallback(l10n, 'invoice_phone', 'SĐT')}: ${order != null ? (order!.customerPhone?.isNotEmpty == true ? order!.customerPhone : '-') : "0987654321"}',
                          style: AppTextStyles.labelSmall,
                        ),
                      if (showCustomerEmail)
                        Text(
                          'Email: ${order != null ? "" : "nguyenvana@example.com"}',
                          style: AppTextStyles.labelSmall,
                        ),
                      if (showCustomerTaxCode)
                        Text(
                          'MST: ${order != null ? "" : "0101234567"}',
                          style: AppTextStyles.labelSmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
          ],

          // Table Header
          Row(
            children: [
              if (showStt) _buildCell('STT', flex: 1),
              if (showItemName)
                _buildCell(_translateOrFallback(l10n, 'invoice_item_name', 'Tên hàng'), flex: 3),
              if (showQuantity)
                _buildCell(_translateOrFallback(l10n, 'quantity', 'SL'), flex: 1),
              if (showUnit)
                _buildCell(_translateOrFallback(l10n, 'invoice_unit', 'ĐVT'), flex: 1),
              if (showUnitPrice)
                _buildCell(_translateOrFallback(l10n, 'detail_unit_price_label', 'Đơn giá'), flex: 2),
              if (showItemDiscount)
                _buildCell(_translateOrFallback(l10n, 'invoice_item_discount', 'Chiết khấu'), flex: 1),
              if (showItemVat) _buildCell('VAT', flex: 1),
              if (showItemTotalAmount)
                _buildCell(_translateOrFallback(l10n, 'invoice_item_total', 'T.Tiền'), flex: 2, alignRight: true),
            ],
          ),
          const Divider(thickness: 1),

          // Table Rows
          if (order != null)
            ...order!.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    if (showStt) _buildCell((index + 1).toString(), flex: 1),
                    if (showItemName) _buildCell(item.productName, flex: 3),
                    if (showQuantity)
                      _buildCell(item.quantity.toString(), flex: 1),
                    if (showUnit) _buildCell(item.unitName ?? '', flex: 1),
                    if (showUnitPrice)
                      _buildCell(
                        CurrencyFormatter.formatNumber(item.price.round()),
                        flex: 2,
                      ),
                    if (showItemDiscount)
                      _buildCell(
                        CurrencyFormatter.formatNumber(item.discount.round()),
                        flex: 1,
                      ),
                    if (showItemVat) _buildCell('0%', flex: 1),
                    if (showItemTotalAmount)
                      _buildCell(
                        CurrencyFormatter.formatNumber(
                          (item.price * item.quantity - item.discount).round(),
                        ),
                        flex: 2,
                        alignRight: true,
                      ),
                  ],
                ),
              );
            })
          else ...[
            // Sample Row 1
            Row(
              children: [
                if (showStt) _buildCell('1', flex: 1),
                if (showItemName) _buildCell('Sản phẩm mẫu 1', flex: 3),
                if (showQuantity) _buildCell('2', flex: 1),
                if (showUnit) _buildCell('Cái', flex: 1),
                if (showUnitPrice) _buildCell('50,000', flex: 2),
                if (showItemDiscount) _buildCell('0', flex: 1),
                if (showItemVat) _buildCell('10%', flex: 1),
                if (showItemTotalAmount)
                  _buildCell('100,000', flex: 2, alignRight: true),
              ],
            ),
            const SizedBox(height: 8),
            // Sample Row 2
            Row(
              children: [
                if (showStt) _buildCell('2', flex: 1),
                if (showItemName) _buildCell('Sản phẩm mẫu 2', flex: 3),
                if (showQuantity) _buildCell('1', flex: 1),
                if (showUnit) _buildCell('Cái', flex: 1),
                if (showUnitPrice) _buildCell('150,000', flex: 2),
                if (showItemDiscount) _buildCell('10%', flex: 1),
                if (showItemVat) _buildCell('0%', flex: 1),
                if (showItemTotalAmount)
                  _buildCell('135,000', flex: 2, alignRight: true),
              ],
            ),
          ],
          const Divider(),

          // Totals
          if (showSubTotal)
            _buildTotalRow(
              '${_translateOrFallback(l10n, 'invoice_subtotal', 'Tạm tính')}:',
              CurrencyFormatter.formatNumber(
                (order?.subtotal ?? 250000).round(),
              ),
            ),
          if (showTotalDiscount)
            _buildTotalRow(
              '${_translateOrFallback(l10n, 'invoice_discount', 'Giảm giá')}:',
              CurrencyFormatter.formatNumber(
                (order?.discountAmount ?? 15000).round(),
              ),
            ),
          if (showTotalVat)
            _buildTotalRow(
              '${_translateOrFallback(l10n, 'invoice_tax', 'VAT')}:',
              CurrencyFormatter.formatNumber(
                (order?.taxAmount ?? 10000).round(),
              ),
            ),
          _buildTotalRow(
            '${_translateOrFallback(l10n, 'invoice_total', 'Tổng thanh toán')}:',
            CurrencyFormatter.formatNumber(
              (order?.totalAmount ?? 245000).round(),
            ),
            isBold: true,
          ),

          const SizedBox(height: 16),
          if (showFooterNote)
            Text(
              footerNoteText.isNotEmpty
                  ? footerNoteText
                  : _translateOrFallback(
                      l10n,
                      'invoice_footer_note',
                      'Cảm ơn quý khách và hẹn gặp lại!',
                    ),
              style: AppTextStyles.labelSmall.copyWith(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

          if (showSignature) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _translateOrFallback(
                      l10n,
                      'invoice_buyer_signature',
                      'Người mua hàng\n(Ký, ghi rõ họ tên)',
                    ),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    _translateOrFallback(
                      l10n,
                      'invoice_seller_signature',
                      'Người bán hàng\n(Ký, ghi rõ họ tên)',
                    ),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ],
      ),
    );
  }

  Widget _buildCell(String text, {int flex = 1, bool alignRight = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
