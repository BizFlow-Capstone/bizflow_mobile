import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/order_entity.dart';

/// Order Card Widget - Displays a single order in list format
class OrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onCancel;

  const OrderCard({
    Key? key,
    required this.order,
    required this.onTap,
    this.onEdit,
    this.onPublish,
    this.onCancel,
  }) : super(key: key);

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
                              'number': order.id.length > 8
                                  ? order.id.substring(0, 8)
                                  : order.id,
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
                    DateFormat('dd/MM/yyyy').format(order.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              // Action buttons (if draft)
              if (order.isDraft) ...[
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
                    if (onPublish != null)
                      TextButton(
                        onPressed: onPublish,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                        child: Text(l10n.translate('order.action_publish')),
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
      label = l10n.translate('order.status_draft');
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
