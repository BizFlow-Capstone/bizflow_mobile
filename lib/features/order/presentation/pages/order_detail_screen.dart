import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order_bloc.dart';
import 'order_form_screen.dart';
import '../../data/order_api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<OrderEntity?> _detailFuture;
  bool _isCancelling = false;
  bool _isPublishing = false;

  String _formatDateTime(DateTime value) {
    return DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
  }

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail(context);
  }

  Future<OrderEntity?> _loadDetail(BuildContext context) async {
    final normalizedId = widget.orderId.trim();
    if (normalizedId.isEmpty) return null;
    try {
      return await context.read<OrderBloc>().repository.getOrder(normalizedId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cancelOrder(OrderEntity detail) async {
    if (_isCancelling) return;
    final l10n = AppLocalizations.of(context);
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('order.cancel_confirm_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.translate('order.cancel_confirm_message')),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.translate('order.detail_cancel_reason'),
                hintText: l10n.translate('order.detail_cancel_reason'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('order.cancel_reason_required'))),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: Text(l10n.translate('common.confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await context.read<OrderBloc>().repository.cancelOrder(
        detail.id,
        cancelReason: reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('order.cancel_success'))),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  Future<void> _completeOrder(OrderEntity detail, {bool confirmLowStock = false}) async {
    if (_isPublishing) return;
    
    final l10n = AppLocalizations.of(context);
    setState(() => _isPublishing = true);
    
    try {
      final repository = context.read<OrderBloc>().repository;
      await repository.completeOrder(detail.id, confirmLowStock: confirmLowStock);
      
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Đơn hàng đã được hoàn thành thành công!',
        type: AppSnackBarType.success,
      );
      
      // Refresh detail
      setState(() {
        _detailFuture = repository.getOrder(widget.orderId);
      });
      
      // Optionally notify Bloc about the update to refresh list
      context.read<OrderBloc>().add(RefreshOrdersRequested(
        locationId: detail.locationId,
      ));
      
    } catch (e) {
      if (!mounted) return;
      
      if (e is OrderConfirmationRequiredException) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.translate('order_create.confirm_continue_title')),
            content: Text('${e.toString()}\n\n${l10n.translate('order_create.confirm_continue_message')}'),
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
          // Retry with confirmation
          setState(() => _isPublishing = false);
          await _completeOrder(detail, confirmLowStock: true);
        }
        return;
      }

      AppSnackBar.show(
        context,
        message: e.toString(),
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
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
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderPublished || state is OrderUpdated) {
            final orderId = state is OrderPublished
                ? state.order.id
                : (state as OrderUpdated).order.id;
            if (orderId == widget.orderId) {
              setState(() {
                _detailFuture = context.read<OrderBloc>().repository.getOrder(widget.orderId);
              });
            }
          } else if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: FutureBuilder<OrderEntity?>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

          final detail = snapshot.data;
          if (detail == null) {
            return Center(
              child: Text(l10n.translate('common.no_data')),
            );
          }

          return Column(
            children: [
              if (detail.isPublished && !detail.isCancelled)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderFormScreen(
                              inputType: 'manual',
                              initialOrder: detail,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Sửa đơn hàng'),
                    ),
                  ),
                ),
              if (detail.isPending) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isCancelling ? null : () => _cancelOrder(detail),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          icon: _isCancelling
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cancel),
                          label: Text(l10n.translate('order.action_cancel')),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
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
                          label: const Text('Sửa đơn'),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isPublishing ? null : () => _completeOrder(detail),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      icon: _isPublishing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle),
                      label: const Text('Hoàn thành đơn hàng'),
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
                                  : l10n.translate('order.order_number', params: {'number': detail.id}),
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text('${l10n.translate('order.detail_status')}: ${detail.status}'),
                            Text('${l10n.translate('order.detail_location')}: ${detail.locationName}'),
                            if ((detail.customerName ?? '').trim().isNotEmpty)
                              Text('${l10n.translate('order.detail_customer_name')}: ${detail.customerName}'),
                            if ((detail.customerPhone ?? '').trim().isNotEmpty)
                              Text('${l10n.translate('order.detail_customer_phone')}: ${detail.customerPhone}'),
                            Text('${l10n.translate('order.detail_created_at')}: ${_formatDateTime(detail.createdAt)}'),
                            Text('${l10n.translate('order.detail_updated_at')}: ${_formatDateTime(detail.updatedAt)}'),
                            if (detail.completedAt != null)
                              Text('${l10n.translate('order.detail_completed_at')}: ${_formatDateTime(detail.completedAt!)}'),
                            if (detail.cancelledAt != null)
                              Text('${l10n.translate('order.detail_cancelled_at')}: ${_formatDateTime(detail.cancelledAt!)}'),
                            if ((detail.cancelReason ?? '').trim().isNotEmpty)
                              Text('${l10n.translate('order.detail_cancel_reason')}: ${detail.cancelReason}'),
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
                            Text('${l10n.translate('order.detail_cash_amount')}: ${CurrencyFormatter.formatVND(detail.cashAmount)}'),
                            Text('${l10n.translate('order.detail_bank_amount')}: ${CurrencyFormatter.formatVND(detail.bankAmount)}'),
                            Text('${l10n.translate('order.detail_debt_amount')}: ${CurrencyFormatter.formatVND(detail.debtAmount)}'),
                            const Divider(height: 20),
                            Text('${l10n.translate('order.detail_subtotal')}: ${CurrencyFormatter.formatVND(detail.subtotal)}'),
                            Text('${l10n.translate('order.detail_discount')}: ${CurrencyFormatter.formatVND(detail.discountAmount)}'),
                            Text('${l10n.translate('order.detail_tax')}: ${CurrencyFormatter.formatVND(detail.taxAmount)}'),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${l10n.translate('order.detail_total')}: ${CurrencyFormatter.formatVND(detail.totalAmount)}',
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
                            '${l10n.translate('order.detail_qty_label')}: ${item.quantity} | ${l10n.translate('order.detail_unit_price_label')}: ${CurrencyFormatter.formatVND(item.price)}',
                          ),
                          trailing: Text(
                            CurrencyFormatter.formatVND(item.price * item.quantity),
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
    );
  }
}
