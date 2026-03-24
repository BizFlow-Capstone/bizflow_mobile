import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';

class OrderDebtConfirmationScreen extends StatelessWidget {
  final double totalAmount;
  final double paidAmount;
  final double debtAmount;
  final String customerName;
  final String? customerPhone;
  final String? locationName;
  final int? debtorId;

  const OrderDebtConfirmationScreen({
    super.key,
    required this.totalAmount,
    required this.paidAmount,
    required this.debtAmount,
    required this.customerName,
    this.customerPhone,
    this.locationName,
    this.debtorId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận ghi nợ'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 80,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Center(
              child: Text(
                'Ghi nhận nợ thành công',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildInfoRow('Khách hàng', customerName),
            _buildInfoRow('Tổng đơn', CurrencyFormatter.formatVND(totalAmount)),
            _buildInfoRow('Đã thanh toán', CurrencyFormatter.formatVND(paidAmount)),
            _buildInfoRow('Còn nợ', CurrencyFormatter.formatVND(debtAmount)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Về trang chủ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
