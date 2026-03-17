import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../widgets/order_card.dart';
import '../widgets/order_filter.dart';
import 'order_creation_selection_screen.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';

/// Order List Screen (SC-ORD-02) - Displays list of draft invoices/orders
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({Key? key}) : super(key: key);

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  String? _currentStatusFilter;
  String? _currentLocationFilter;

  @override
  void initState() {
    super.initState();
    // Load draft orders by default
    _loadDraftOrders();
  }

  void _loadDraftOrders() {
    context.read<OrderBloc>().add(const LoadDraftOrdersRequested());
  }

  void _loadAllOrders() {
    context.read<OrderBloc>().add(
      LoadOrdersRequested(
        status: _currentStatusFilter,
        locationId: _currentLocationFilter,
      ),
    );
  }

  void _applyFilter(Map<String, dynamic> filters) {
    _currentStatusFilter = filters['status'];
    _currentLocationFilter = filters['locationId'];

    context.read<OrderBloc>().add(
      FilterOrdersRequested(
        status: _currentStatusFilter,
        locationId: _currentLocationFilter,
      ),
    );
  }

  void _refreshOrders() {
    context.read<OrderBloc>().add(const RefreshOrdersRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order.list_title')),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: Colors.black,
          ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: l10n.translate('order.action_filter'),
            onPressed: () {
              showOrderFilterBottomSheet(
                context,
                initialStatus: _currentStatusFilter,
                initialLocationId: _currentLocationFilter,
                onApply: _applyFilter,
              );
            },
            color: Colors.black,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.translate('order.action_refresh'),
            onPressed: _refreshOrders,
            color: Colors.black,
          ),
        ],
        bottom: const AppSyncStatusText(),
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (state is OrderError) {
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
                      l10n.translate('common.error_occurred'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _refreshOrders,
                    child: Text(l10n.translate('common.retry')),
                  ),
                ],
              ),
            );
          }

          List<dynamic> orders = [];
          if (state is DraftOrdersLoaded) {
            orders = state.orders;
          } else if (state is OrdersLoaded) {
            orders = state.orders;
          } else if (state is OrdersFiltered) {
            orders = state.orders;
          }

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate('order.empty_orders'),
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrderCreationSelectionScreen(),
                        ),
                      );
                    },
                    child: Text(l10n.translate('order.action_add')),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshOrders();
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 120), // Increased bottom padding for FAB
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
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
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OrderCreationSelectionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
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
