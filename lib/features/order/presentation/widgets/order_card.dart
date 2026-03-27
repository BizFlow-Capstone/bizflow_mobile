import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../domain/entities/order_entity.dart';

/// Order Card Widget - Displays a single order in list format
class OrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onCancel;
  final VoidCallback? onDeleteDraft;
  final bool isPublishing;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onEdit,
    this.onPublish,
    this.onCancel,
    this.onDeleteDraft,
    this.isPublishing = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with order info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate(
                            'order.order_number',
                            params: {
                              'number': order.isDraft
                                  ? order.id
                                  : (order.id.length > 8
                                      ? order.id.substring(order.id.length - 8)
                                      : order.id),
                            },
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.locationName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              const SizedBox(height: 12),

              // Items info
              Text(
                l10n.translate(
                  'order.products_count',
                  params: {'count': order.items.length.toString()},
                ),
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),

              // Total and date row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('order.total_amount'),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatCurrency(order.totalAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormatter.formatDate(order.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              // Action buttons
              if (order.isDraft || order.isPending) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton(
                        onPressed: onEdit,
                        child: Text(l10n.translate('order.action_edit')),
                      ),
                    const SizedBox(width: 8),
                    if (order.isDraft && onDeleteDraft != null)
                      TextButton(
                        onPressed: onDeleteDraft,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: Text(l10n.translate('common.delete')),
                      ),
                    if (order.isDraft && onDeleteDraft != null)
                      const SizedBox(width: 8),
                    if (order.isPending && onCancel != null)
                      TextButton(
                        onPressed: onCancel,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: Text(l10n.translate('order.action_cancel')),
                      ),
                    const SizedBox(width: 8),
                    if (!order.isDraft && onPublish != null)
                      TextButton(
                        onPressed: isPublishing ? null : onPublish,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                        child: isPublishing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.green,
                                ),
                              )
                            : Text(l10n.translate('order.action_publish')),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color bgColor;
    Color textColor = Colors.white;
    String label;

    if (order.isDraft) {
      bgColor = Colors.orange;
      label = 'Nháp';
    } else if (order.isPending) {
      bgColor = Colors.blue;
      label = l10n.translate('order.status_pending');
    } else if (order.isPublished) {
      bgColor = Colors.green;
      label = l10n.translate('order.status_published');
    } else {
      bgColor = Colors.grey;
      label = l10n.translate('order.status_cancelled');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(amount);
  }
}
