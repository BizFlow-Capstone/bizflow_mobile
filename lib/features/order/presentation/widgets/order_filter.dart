import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

/// Order Filter Widget - Allows filtering orders by status and location
class OrderFilterBottomSheet extends StatefulWidget {
  final String? initialStatus;
  final String? initialLocationId;
  final ValueChanged<Map<String, dynamic>> onApply;

  const OrderFilterBottomSheet({
    Key? key,
    this.initialStatus,
    this.initialLocationId,
    required this.onApply,
  }) : super(key: key);

  @override
  State<OrderFilterBottomSheet> createState() => _OrderFilterBottomSheetState();
}

class _OrderFilterBottomSheetState extends State<OrderFilterBottomSheet> {
  late String? selectedStatus;
  late String? selectedLocation;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialStatus;
    selectedLocation = widget.initialLocationId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('order.filter_title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Filter
          Text(
            l10n.translate('order.filter_status'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildStatusChip(context, 'DRAFT', 'order.status_draft'),
              _buildStatusChip(context, 'PENDING', 'order.status_pending'),
              _buildStatusChip(context, 'PUBLISHED', 'order.status_published'),
              _buildStatusChip(context, 'CANCELLED', 'order.status_cancelled'),
            ],
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedStatus = null;
                    selectedLocation = null;
                  });
                },
                child: Text(l10n.translate('order.filter_clear')),
              ),
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply({
                      'status': selectedStatus,
                      'locationId': selectedLocation,
                    });
                    Navigator.pop(context);
                  },
                  child: Text(l10n.translate('order.filter_apply')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String code, String labelKey) {
    final l10n = AppLocalizations.of(context);
    final isSelected = selectedStatus == code;

    return FilterChip(
      label: Text(l10n.translate(labelKey)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedStatus = selected ? code : null;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }
}

/// Show order filter dialog
Future<void> showOrderFilterBottomSheet(
  BuildContext context, {
  String? initialStatus,
  String? initialLocationId,
  required ValueChanged<Map<String, dynamic>> onApply,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (context) => OrderFilterBottomSheet(
      initialStatus: initialStatus,
      initialLocationId: initialLocationId,
      onApply: onApply,
    ),
  );
}
