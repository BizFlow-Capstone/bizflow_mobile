import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../../core/storage/local_storage.dart';
import 'package:bizflow_mobile/features/order/presentation/bloc/order_bloc.dart';
import 'package:bizflow_mobile/features/order/domain/entities/order_entity.dart';
import 'package:bizflow_mobile/shared/context/business_context.dart';
import 'package:bizflow_mobile/shared/utils/action_guard.dart';
import 'package:bizflow_mobile/core/theme/app_colors.dart';
import 'package:bizflow_mobile/core/theme/app_spacing.dart';
import 'package:bizflow_mobile/core/theme/app_text_styles.dart';
import 'package:bizflow_mobile/shared/widgets/app_text_field.dart';
import 'package:bizflow_mobile/shared/widgets/app_sync_status_text.dart';
import 'package:bizflow_mobile/shared/dialogs/app_snackbar.dart';
import 'package:bizflow_mobile/shared/cache/sync_status_controller.dart';
import '../widgets/order_card.dart';
import '../widgets/order_filter.dart';
import 'order_creation_selection_screen.dart';
import 'order_detail_screen.dart';
import 'order_form_screen.dart';
import '../../data/order_api_service.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';
import '../../../accounting/data/repositories/accounting_repository.dart';
import '../../../accounting/domain/models/accounting_period.dart';

import '../../../../core/routing/app_router.dart';

/// Order List Screen (SC-ORD-02) - Displays list of draft invoices/orders
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  String? _currentStatusFilter;
  String? _currentLocationFilter;
  final Set<String> _publishingOrderIds = {};
  final ActionGuard _cancelOrderGuard = ActionGuard();
  final ActionGuard _openOrderCreationGuard = ActionGuard();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<AccountingPeriod> _periods = const <AccountingPeriod>[];
  bool _periodsLoaded = false;

  String? _resolveLocationId({String? preferred}) {
    final raw = (preferred ?? context.read<BusinessContext>().currentBusinessId)
        ?.trim();
    if (raw == null || raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) return null;
    return parsed.toString();
  }

  @override
  void initState() {
    super.initState();
    SyncStatusController().setManualRefreshCallback(_refreshOrders);
    _loadInitialOrders();
  }

  Future<void> _loadAccountingPeriodsForLocation(String locationId) async {
    setState(() {
      _periodsLoaded = false;
    });

    try {
      await context.read<AccountingRepository>().fetchPeriodsSWR(
        locationId: locationId,
        onData: (periods, _) {
          if (!mounted) return;
          setState(() {
            _periods = periods;
            _periodsLoaded = true;
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _periodsLoaded = true;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _periodsLoaded = true;
      });
    }
  }

  bool _isDateInPeriod(DateTime date, AccountingPeriod period) {
    try {
      final targetDate = DateUtils.dateOnly(date.toLocal());
      final startDate = DateUtils.dateOnly(DateTime.parse(period.startDate));
      final endDate = DateUtils.dateOnly(DateTime.parse(period.endDate));
      return !targetDate.isBefore(startDate) && !targetDate.isAfter(endDate);
    } catch (_) {
      return false;
    }
  }

  bool _hideCancelForCompletedOrder(OrderEntity order) {
    if (!order.isPublished || !_periodsLoaded) {
      return false;
    }

    final orderDate = order.completedAt ?? order.createdAt;
    for (final period in _periods) {
      if (_isDateInPeriod(orderDate, period) && period.isFinalized) {
        return true;
      }
    }

    return false;
  }

  void _loadInitialOrders() {
    final locationId = _resolveLocationId();
    if (locationId == null) {
      final l10n = AppLocalizations.of(context);
      AppSnackBar.show(
        context,
        message: l10n.translate('debt.location_required'),
        type: AppSnackBarType.warning,
      );
      return;
    }
    _loadAccountingPeriodsForLocation(locationId);
    context.read<OrderBloc>().add(LoadOrdersRequested(locationId: locationId));
  }

  void _loadDraftOrders() {
    // Re-use logic to refresh all orders (which now includes drafts)
    // so we don't accidentally overwrite the main list with ONLY drafts.
    _refreshOrders();
  }

  void _applyFilter(Map<String, dynamic> filters) {
    _currentStatusFilter = filters['status'];
    _currentLocationFilter = _resolveLocationId(
      preferred: filters['locationId']?.toString(),
    );

    if (_currentLocationFilter == null) {
      final l10n = AppLocalizations.of(context);
      AppSnackBar.show(
        context,
        message: l10n.translate('debt.location_required'),
        type: AppSnackBarType.warning,
      );
      return;
    }

    _loadAccountingPeriodsForLocation(_currentLocationFilter!);

    context.read<OrderBloc>().add(
      FilterOrdersRequested(
        status: _currentStatusFilter,
        locationId: _currentLocationFilter,
      ),
    );
  }

  void _refreshOrders() {
    final locationId = _resolveLocationId();
    if (locationId == null) {
      final l10n = AppLocalizations.of(context);
      AppSnackBar.show(
        context,
        message: l10n.translate('debt.location_required'),
        type: AppSnackBarType.warning,
      );
      return;
    }
    _loadAccountingPeriodsForLocation(locationId);
    context.read<OrderBloc>().add(
      RefreshOrdersRequested(locationId: locationId),
    );
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<OrderBloc>().add(SearchOrdersRequested(keyword: query));
      }
    });
  }

  Future<void> _completeOrder(
    OrderEntity order, {
    bool confirmLowStock = false,
  }) async {
    if (_publishingOrderIds.contains(order.id)) return;

    final allowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.orderManagement,
    );
    if (!allowed) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _publishingOrderIds.add(order.id));

    try {
      final repository = context.read<OrderBloc>().repository;
      await repository.completeOrder(
        order.id,
        confirmLowStock: confirmLowStock,
      );

      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.translate('order.complete_success'),
        type: AppSnackBarType.success,
      );

      _refreshOrders();
    } catch (e) {
      if (!mounted) return;

      if (e is OrderConfirmationRequiredException) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.translate('order_create.confirm_continue_title')),
            content: Text(
              '${ApiErrorMessageParser.parse(e)}\n\n${l10n.translate('order_create.confirm_continue_message')}',
            ),
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
          setState(() => _publishingOrderIds.remove(order.id));
          await _completeOrder(order, confirmLowStock: true);
        }
        return;
      }

      AppSnackBar.show(
        context,
        message: ApiErrorMessageParser.parse(e),
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _publishingOrderIds.remove(order.id));
      }
    }
  }

  Future<void> _openDraftForEditing(OrderEntity order) async {
    if (!order.isDraft) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderFormScreen(inputType: 'manual', draftId: order.id),
      ),
    );
    if (!mounted) return;
    _loadDraftOrders();
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
          pendingOrderId: order.id,
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

  Future<void> _openOrderForEditing(OrderEntity order) async {
    if (order.isPublished || order.isCancelled) {
      _openOrderDetail(order);
      return;
    }

    if (order.isDraft) {
      await _openDraftForEditing(order);
      return;
    }

    if (order.isPending) {
      await _openPendingForEditing(order);
      return;
    }

    _openOrderDetail(order);
  }

  @override
  void dispose() {
    SyncStatusController().setManualRefreshCallback(null);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _openOrderDetail(OrderEntity order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
    );
  }

  Future<void> _deleteDraft(OrderEntity order) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('common.delete')),
        content: Text(l10n.translate('order.delete_draft_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.translate('common.delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final storage = await LocalStorage.getInstance();
    final raw = storage.getString(StorageKeys.orderLocalDrafts);
    if (raw == null || raw.trim().isEmpty) {
      _loadDraftOrders();
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      _loadDraftOrders();
      return;
    }

    final drafts = decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    drafts.removeWhere((item) => item['id']?.toString() == order.id);
    await storage.setString(StorageKeys.orderLocalDrafts, jsonEncode(drafts));

    if (!mounted) return;
    AppSnackBar.show(
      context,
      message: l10n.translate('order.delete_draft_success'),
      type: AppSnackBarType.success,
    );
    _loadDraftOrders();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          return true;
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.translate('order.list_title')),
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.pop(context);
              } else {
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
              }
            },
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
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
            child: AppTextField(
              controller: _searchController,
              hintText: l10n.translate('order.search_hint'),
              prefixIcon: const Icon(Icons.search),
              onChanged: _onSearchChanged,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
          Expanded(
            child: BlocConsumer<OrderBloc, OrderState>(
              listener: (context, state) {
          if (state is OrderError) {
            AppSnackBar.show(
              context,
              message: state.message.isNotEmpty
                  ? state.message
                  : l10n.translate('common.error_occurred'),
              type: AppSnackBarType.error,
            );
          } else if (state is OrderCancelled) {
            AppSnackBar.show(
              context,
              message: l10n.translate('order.cancel_success'),
              type: AppSnackBarType.success,
            );
            _refreshOrders();
          }
        },
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<OrderEntity> orders = [];
          if (state is DraftOrdersLoaded) {
            orders = state.orders;
          } else if (state is OrdersLoaded) {
            orders = state.orders;
          } else if (state is OrderError) {
            orders = [];
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
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 120,
              ), // Increased bottom padding for FAB
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderCard(
                  order: order,
                  isPublishing: _publishingOrderIds.contains(order.id),
                  onTap: () {
                    _openOrderForEditing(order);
                  },
                  onEdit: () {
                    _openOrderForEditing(order);
                  },
                  onDeleteDraft: order.isDraft
                      ? () {
                          _deleteDraft(order);
                        }
                      : null,
                  onPublish: () => _completeOrder(order),
                  onCancel: _hideCancelForCompletedOrder(order)
                      ? null
                      : () {
                          _showCancelConfirmDialog(context, order.id);
                        },
                );
              },
            ),
          );
        },
      ),
    ),
  ],
),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.translate('order.action_add'),
        onPressed: () async {
          await _openOrderCreationGuard.run(() async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OrderCreationSelectionScreen(),
              ),
            );
          });
        },
        child: const Icon(Icons.add),
      ),
      ),
    );
  }

  void _showCancelConfirmDialog(BuildContext context, String orderId) {
    final l10n = AppLocalizations.of(context);
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('order.cancel_confirm_title')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.translate('order.cancel_confirm_message')),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return l10n.translate('order.cancel_reason_required');
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: l10n.translate('order.detail_cancel_reason'),
                  hintText: l10n.translate('order.detail_cancel_reason'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('order.cancel_confirm_no')),
          ),
          TextButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }
              final reason = reasonController.text.trim();
              await _cancelOrderGuard.run(() async {
                final allowed = await SubscriptionFeatureGuard.ensureAllowed(
                  context,
                  featureCode: SubscriptionFeatureCodes.orderManagement,
                );
                if (!allowed || !context.mounted) return;
                context.read<OrderBloc>().add(
                  CancelOrderRequested(orderId: orderId, cancelReason: reason),
                );
                Navigator.pop(context);
              });
            },
            child: Text(l10n.translate('order.cancel_confirm_yes')),
          ),
        ],
      ),
    );
  }
}
