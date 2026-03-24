import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/reference/presentation/bloc/reference_bloc.dart';
import '../../../../core/reference/presentation/bloc/reference_event.dart';
import '../../../../core/reference/presentation/bloc/reference_state.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../bloc/gl_bloc/gl_bloc.dart';
import '../bloc/gl_bloc/gl_event.dart';
import '../bloc/gl_bloc/gl_state.dart';
import '../widgets/gl_filter_bottom_sheet.dart';
import '../../../accounting/data/models/general_ledger_entry_model.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/presentation/bloc/order_bloc.dart';

class GeneralLedgerPage extends StatefulWidget {
  const GeneralLedgerPage({super.key});

  @override
  State<GeneralLedgerPage> createState() => _GeneralLedgerPageState();
}

class _GeneralLedgerPageState extends State<GeneralLedgerPage> {
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;
  bool _isLocationUnavailable = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final refState = context.read<ReferenceBloc>().state;
      if (refState is! ReferenceLoaded && refState is! ReferenceLoading) {
        context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
      }
      _loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final state = context.read<GLBloc>().state;
      if (state is GLLoaded && !state.hasReachedMax && !state.isLoadMore) {
        _loadData(isLoadMore: true, pageNumber: state.pageNumber + 1);
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _loadData({
    bool isLoadMore = false,
    int pageNumber = 1,
    List<String>? transactionTypes,
    List<String>? referenceTypes,
    List<String>? moneyChannels,
    DateTime? fromDate,
    DateTime? toDate,
    String? viewMode,
  }) async {
    var locationId = context.read<BusinessContext>().currentBusinessId;
    if (locationId == null || locationId.trim().isEmpty) {
      await BusinessContext().init();
      locationId = BusinessContext().currentBusinessId;
    }

    final parsedLocationId = int.tryParse(locationId ?? '');
    if (parsedLocationId == null || parsedLocationId <= 0) {
      if (mounted) {
        setState(() => _isLocationUnavailable = true);
      }
      return;
    }

    if (_isLocationUnavailable && mounted) {
      setState(() => _isLocationUnavailable = false);
    }

    final state = context.read<GLBloc>().state;
    GLLoaded? currentState;
    if (state is GLLoaded) currentState = state;

    final effectiveTransactionTypes = transactionTypes ?? currentState?.transactionTypes;
    final effectiveReferenceTypes = referenceTypes ?? currentState?.referenceTypes;
    final effectiveMoneyChannels = moneyChannels ?? currentState?.moneyChannels;
    final effectiveFromDate = fromDate ?? currentState?.fromDate;
    final effectiveToDate = toDate ?? currentState?.toDate;
    final effectiveViewMode = viewMode ?? currentState?.viewMode ?? 'audit';

    context.read<GLBloc>().add(
      LoadGLEntriesRequested(
        businessLocationId: parsedLocationId,
        pageNumber: pageNumber,
        pageSize: _pageSize,
        isLoadMore: isLoadMore,
        transactionTypes: effectiveTransactionTypes,
        referenceTypes: effectiveReferenceTypes,
        moneyChannels: effectiveMoneyChannels,
        fromDate: effectiveFromDate,
        toDate: effectiveToDate,
        viewMode: effectiveViewMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.tr('accounting.general_ledger', params: {})),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        bottom: const AppSyncStatusText(),
         leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: AppColors.textPrimary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.primary),
            onPressed: _showFiltersBottomSheet,
          ),
        ],
      ),
      body: BlocBuilder<GLBloc, GLState>(
        builder: (context, state) {
          if (_isLocationUnavailable) {
            return _buildMissingLocationState();
          }

          if (state is GLInitial || state is GLLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GLError) {
            final hasData =
                state.previousEntries != null &&
                state.previousEntries!.isNotEmpty;
            if (!hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadData(),
                        child: Text(context.tr('common.retry')),
                      ),
                    ],
                  ),
                ),
              );
            }
            // If it has data, just show the snackbar for error and continue displaying data.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            });
            return _buildListView(state.previousEntries!, true);
          }

          if (state is GLLoaded) {
            if (state.entries.isEmpty) {
              return _buildEmptyState();
            }
            return _buildListView(
              state.entries,
              state.hasReachedMax,
              isLoadMore: state.isLoadMore,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('accounting.gl_empty'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('accounting.gl_empty_sub'),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(
    List<GeneralLedgerEntryModel> entries,
    bool hasReachedMax, {
    bool isLoadMore = false,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: entries.length + (hasReachedMax ? 0 : 1),
        itemBuilder: (context, index) {
          if (index >= entries.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final entry = entries[index];
          return _buildEntryCard(entry);
        },
      ),
    );
  }

  Widget _buildMissingLocationState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.store_mall_directory_outlined,
              size: 48,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('accounting.gl_location_required'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadData(),
              child: Text(context.tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(GeneralLedgerEntryModel entry) {
    // Parse date safely
    DateTime? dateObj;
    try {
      dateObj = DateTime.parse(entry.date);
    } catch (_) {}

    final dateStr = dateObj != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dateObj.toLocal())
        : entry.date;
    final formatter = NumberFormat.currency(locale: 'vi', symbol: 'đ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      surfaceTintColor: Colors.white,
      child: InkWell(
        onTap: () {
          _showEntryDetail(entry);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.documentNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    formatter.format(entry.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: entry.amount >= 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.note,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.transactionType,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if ((entry.moneyChannel ?? '').isNotEmpty ||
                  (entry.referenceType.isNotEmpty && entry.referenceId != null))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((entry.moneyChannel ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Channel: ${entry.moneyChannel}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      if (entry.referenceType.isNotEmpty && entry.referenceId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.referenceType.toUpperCase()}-${entry.referenceId}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<OrderEntity?> _loadLinkedOrder(GeneralLedgerEntryModel entry) async {
    final entityType = entry.entityType?.toLowerCase();
    final entityId = entry.entityId;
    if (entityType != 'order' || entityId == null || entityId <= 0) {
      return null;
    }

    try {
      return await context.read<OrderBloc>().repository.getOrder(entityId.toString());
    } catch (_) {
      return null;
    }
  }

  void _showEntryDetail(GeneralLedgerEntryModel entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('GL-${entry.entryId}'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Chứng từ: ${entry.documentNumber}'),
                const SizedBox(height: 6),
                Text('Ngày: ${entry.date}'),
                const SizedBox(height: 6),
                Text('Nội dung: ${entry.note}'),
                const SizedBox(height: 6),
                Text('Loại giao dịch: ${entry.transactionType}'),
                const SizedBox(height: 6),
                Text('Kênh tiền: ${entry.moneyChannel ?? '-'}'),
                const SizedBox(height: 6),
                Text('Reference: ${entry.referenceType.isNotEmpty ? entry.referenceType : '-'} ${entry.referenceId ?? ''}'),
                const SizedBox(height: 6),
                Text('Entity: ${entry.entityType ?? '-'} ${entry.entityId ?? ''}'),
                if ((entry.entityType ?? '').toLowerCase() == 'order' &&
                    (entry.entityId ?? 0) > 0) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Order detail',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<OrderEntity?>(
                    future: _loadLinkedOrder(entry),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final order = snapshot.data;
                      if (order == null) {
                        return const Text('Không tải được chi tiết đơn hàng');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order ID: ${order.id}'),
                          const SizedBox(height: 4),
                          Text('Trạng thái: ${order.status}'),
                          const SizedBox(height: 4),
                          Text('Tổng tiền: ${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(order.totalAmount)}'),
                          const SizedBox(height: 8),
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('• ${item.productName} x${item.quantity}'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('common.close')),
          ),
        ],
      ),
    );
  }

  void _showFiltersBottomSheet() async {
    final currentState = context.read<GLBloc>().state;
    final refState = context.read<ReferenceBloc>().state;
    if (refState is! ReferenceLoaded && refState is! ReferenceLoading) {
      context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
    }

    final transactionTypes = currentState is GLLoaded
        ? currentState.transactionTypes
        : <String>[];
    final referenceTypes = currentState is GLLoaded
        ? currentState.referenceTypes
        : <String>[];
    final moneyChannels = currentState is GLLoaded
        ? currentState.moneyChannels
        : <String>[];
    final fromDate = currentState is GLLoaded ? currentState.fromDate : null;
    final toDate = currentState is GLLoaded ? currentState.toDate : null;
    final viewMode = currentState is GLLoaded ? currentState.viewMode : 'audit';

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
          ),
          child: GLFilterBottomSheet(
            currentTransactionTypes: transactionTypes,
            currentReferenceTypes: referenceTypes,
            currentMoneyChannels: moneyChannels,
            currentFromDate: fromDate,
            currentToDate: toDate,
            currentViewMode: viewMode,
          ),
        ),
      ),
    );

    if (result != null) {
      if (!mounted) return;
      await _loadData(
        pageNumber: 1,
        isLoadMore: false,
        transactionTypes: (result['transactionTypes'] as List?)
            ?.whereType<String>()
            .toList(),
        referenceTypes: (result['referenceTypes'] as List?)
            ?.whereType<String>()
            .toList(),
        moneyChannels: (result['moneyChannels'] as List?)
            ?.whereType<String>()
            .toList(),
        fromDate: result['fromDate'] as DateTime?,
        toDate: result['toDate'] as DateTime?,
        viewMode: result['viewMode'] as String?,
      );
    }
  }
}
