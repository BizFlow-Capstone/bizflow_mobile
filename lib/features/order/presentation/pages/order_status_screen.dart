import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../widgets/order_card.dart';

/// Order Status Screen (SC-ORD-02.2)
/// Displays unpublished invoices and draft orders with tabs
class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order.status_title')),
        elevation: 0,
        bottom: TabBar(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrderError) {
            return _buildErrorWidget(context, state.message, _refreshOrders);
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
    List<dynamic> draftOrders = [];

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
              // TODO: Navigate to order details
            },
            onEdit: () {
              // TODO: Navigate to edit order
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
    List<dynamic> pendingOrders = [];

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
              // TODO: Navigate to order details
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

  Widget _buildErrorWidget(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            l10n.translate('order.error_title'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(l10n.translate('common.retry')),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmDialog(BuildContext context, String orderId) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('order.cancel_confirm_title')),
        content: Text(l10n.translate('order.cancel_confirm_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('order.cancel_confirm_no')),
          ),
          TextButton(
            onPressed: () {
              context.read<OrderBloc>().add(
                CancelOrderRequested(orderId: orderId),
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
