import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../widgets/order_card.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import 'order_detail_screen.dart';
import 'order_form_screen.dart';

/// Order Status Screen (SC-ORD-02.2)
/// Displays unpublished invoices and draft orders with tabs
class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load draft orders
    context.read<OrderBloc>().add(const LoadDraftOrdersRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshOrders() {
    context.read<OrderBloc>().add(const RefreshOrdersRequested());
  }

  Future<void> _openDraftForEditing(OrderEntity order) async {
    if (!order.isDraft) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderFormScreen(
          inputType: 'manual',
          draftId: order.id,
        ),
      ),
    );
    if (!mounted) return;
    context.read<OrderBloc>().add(const LoadDraftOrdersRequested());
  }

  Future<void> _openPendingForEditing(OrderEntity order) async {
    if (!order.isPending) return;

    final storage = await LocalStorage.getInstance();
    final raw = storage.getString(StorageKeys.orderLocalDrafts);

    List<Map<String, dynamic>> drafts = [];
    if (raw != null && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        drafts = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    final draftId = 'edit_${order.id}';
    final payload = {
      'id': draftId,
      'locationId': order.locationId,
      'locationName': order.locationName,
      'status': 'draft',
      'customerType': 'walkin',
      'customerName': order.customerName ?? '',
      'customerPhone': order.customerPhone ?? '',
      'subtotal': order.subtotal,
      'discountAmount': order.discountAmount,
      'taxAmount': order.taxAmount,
      'totalAmount': order.totalAmount,
      'items': order.items
          .map(
            (item) => {
              'id': item.id,
              'productId': item.productId,
              'saleItemId': item.saleItemId ?? int.tryParse(item.productId),
              'unitName': item.unitName,
              'productName': item.productName,
              'price': item.price,
              'quantity': item.quantity,
              'discount': item.discount,
              'note': item.note,
            },
          )
          .toList(),
      'createdAt': order.createdAt.toUtc().toIso8601String(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };

    final index = drafts.indexWhere((item) => item['id'] == draftId);
    if (index >= 0) {
      drafts[index] = payload;
    } else {
      drafts.insert(0, payload);
    }

    await storage.setString(StorageKeys.orderLocalDrafts, jsonEncode(drafts));

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderFormScreen(
          inputType: 'manual',
          draftId: draftId,
        ),
      ),
    );
    if (!mounted) return;
    await _removeTempDraftById(draftId);
    if (!mounted) return;
    _refreshOrders();
  }

  Future<void> _removeTempDraftById(String draftId) async {
    final storage = await LocalStorage.getInstance();
    final raw = storage.getString(StorageKeys.orderLocalDrafts);
    if (raw == null || raw.trim().isEmpty) return;

    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    final drafts = decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final before = drafts.length;
    drafts.removeWhere((item) => item['id']?.toString() == draftId);
    if (drafts.length == before) return;

    await storage.setString(StorageKeys.orderLocalDrafts, jsonEncode(drafts));
  }

  void _openOrderDetail(OrderEntity order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: order.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order.status_title')),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: Column(
            children: [
              const AppSyncStatusText(),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    text: l10n.translate('order.tab_draft'),
                    icon: const Icon(Icons.edit, size: 18),
                  ),
                  Tab(
                    text: l10n.translate('order.tab_pending'),
                    icon: const Icon(Icons.pending_actions, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderError) {
            AppSnackBar.show(
              context,
              message: state.message.isNotEmpty
                  ? state.message
                  : l10n.translate('common.error_occurred'),
              type: AppSnackBarType.error,
            );
          }
        },
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Draft Orders (Tạm tính)
              _buildDraftOrdersTab(context, state),

              // Tab 2: Pending Orders (Chưa xuất)
              _buildPendingOrdersTab(context, state),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create order screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDraftOrdersTab(BuildContext context, OrderState state) {
    final l10n = AppLocalizations.of(context);
    List<OrderEntity> draftOrders = [];

    if (state is DraftOrdersLoaded) {
      draftOrders = state.orders;
    } else if (state is OrdersLoaded) {
      draftOrders = state.orders.where((o) => o.isDraft).toList();
    } else if (state is OrdersFiltered) {
      draftOrders = state.orders.where((o) => o.isDraft).toList();
    }

    if (draftOrders.isEmpty) {
      return _buildEmptyWidget(
        l10n.translate('order.empty_draft'),
        l10n.translate('order.empty_draft_subtitle'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _refreshOrders();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: draftOrders.length,
        itemBuilder: (context, index) {
          final order = draftOrders[index];
          return OrderCard(
            order: order,
            onTap: () {
              _openDraftForEditing(order);
            },
            onEdit: () {
              _openDraftForEditing(order);
            },
            onPublish: () {
              context.read<OrderBloc>().add(
                PublishOrderRequested(orderId: order.id),
              );
            },
            onCancel: () {
              _showCancelConfirmDialog(context, order.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildPendingOrdersTab(BuildContext context, OrderState state) {
    final l10n = AppLocalizations.of(context);
    List<OrderEntity> pendingOrders = [];

    if (state is OrdersLoaded) {
      pendingOrders = state.orders.where((o) => o.isPending).toList();
    } else if (state is OrdersFiltered) {
      pendingOrders = state.orders.where((o) => o.isPending).toList();
    }

    if (pendingOrders.isEmpty) {
      return _buildEmptyWidget(
        l10n.translate('order.empty_pending'),
        l10n.translate('order.empty_pending_subtitle'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _refreshOrders();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: pendingOrders.length,
        itemBuilder: (context, index) {
          final order = pendingOrders[index];
          return OrderCard(
            order: order,
            onTap: () {
              _openPendingForEditing(order);
            },
            onEdit: () {
              _openPendingForEditing(order);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyWidget(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmDialog(BuildContext context, String orderId) {
    final l10n = AppLocalizations.of(context);
    final reasonController = TextEditingController();
    showDialog(
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
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('order.cancel_confirm_no')),
          ),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                AppSnackBar.show(
                  context,
                  message: l10n.translate('order.cancel_reason_required'),
                  type: AppSnackBarType.warning,
                );
                return;
              }
              context.read<OrderBloc>().add(
                CancelOrderRequested(orderId: orderId, cancelReason: reason),
              );
              Navigator.pop(context);
            },
            child: Text(l10n.translate('order.cancel_confirm_yes')),
          ),
        ],
      ),
    );
  }
}
