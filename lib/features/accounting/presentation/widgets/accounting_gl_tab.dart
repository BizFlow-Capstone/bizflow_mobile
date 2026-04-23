import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/reference/presentation/bloc/reference_bloc.dart';
import '../../../../core/reference/presentation/bloc/reference_event.dart';
import '../../../../core/reference/presentation/bloc/reference_state.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../bloc/gl_bloc/gl_bloc.dart';
import '../bloc/gl_bloc/gl_event.dart';
import '../bloc/gl_bloc/gl_state.dart';
import '../widgets/gl_filter_bottom_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../accounting/data/models/general_ledger_entry_model.dart';
import '../../../accounting/domain/utils/accounting_reference_display.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/presentation/bloc/order_bloc.dart';
import '../../../order/presentation/pages/order_detail_screen.dart';

class AccountingGlTab extends StatefulWidget {
  const AccountingGlTab({super.key});

  @override
  State<AccountingGlTab> createState() => _AccountingGlTabState();
}

class _AccountingGlTabState extends State<AccountingGlTab> {
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;
  bool _isLocationUnavailable = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

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
    _searchController.dispose();
    _searchDebounce?.cancel();
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

  static final RegExp _dateOnlyRegExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  DateTime? _parseApiDateTime(String? value) {
    return DateFormatter.parseApiDateTime(value);
  }

  DateTime? _resolveDisplayDateTime(GeneralLedgerEntryModel entry) {
    final primaryDate = _parseApiDateTime(entry.date);
    final createdAt = _parseApiDateTime(entry.createdAt);

    if (primaryDate == null) {
      return createdAt;
    }

    final rawDate = entry.date.trim();
    final isDateOnly = _dateOnlyRegExp.hasMatch(rawDate);
    if (isDateOnly && createdAt != null) {
      final localCreatedAt = createdAt.toLocal();
      return DateTime(
        primaryDate.year,
        primaryDate.month,
        primaryDate.day,
        localCreatedAt.hour,
        localCreatedAt.minute,
        localCreatedAt.second,
        localCreatedAt.millisecond,
        localCreatedAt.microsecond,
      );
    }

    return primaryDate;
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
    bool resetDates = false,
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

    final effectiveTransactionTypes =
        transactionTypes ?? currentState?.transactionTypes;
    final effectiveReferenceTypes =
        referenceTypes ?? currentState?.referenceTypes;
    final effectiveMoneyChannels = moneyChannels ?? currentState?.moneyChannels;
    // If resetDates is true, use the passed dates (even if null); otherwise fallback to currentState
    final effectiveFromDate = resetDates ? fromDate : (fromDate ?? currentState?.fromDate);
    final effectiveToDate = resetDates ? toDate : (toDate ?? currentState?.toDate);
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

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<GLBloc>().add(SearchGLEntriesRequested(query));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              AppTextField(
                controller: _searchController,
                hintText: context.tr('common.search_hint'),
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(
                      Icons.filter_list,
                      color: AppColors.primary,
                    ),
                    label: Text(context.tr('accounting.gl_filter_data')),
                    onPressed: _showFiltersBottomSheet,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<GLBloc, GLState>(
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

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    AppSnackBar.show(
                      context,
                      message: state.message,
                      type: AppSnackBarType.error,
                    );
                  }
                });

                if (!hasData) {
                  return _buildEmptyState();
                }

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
        ),
      ],
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
    final dateObj = _resolveDisplayDateTime(entry);

    final languageCode = Localizations.localeOf(context).languageCode;
    final displayDocument = AccountingReferenceDisplay.displayDocument(
      documentNumber: entry.documentNumber,
      referenceType: entry.referenceType,
      referenceId: entry.referenceId,
      referenceCode: entry.documentNumber,
      languageCode: languageCode,
    );
    final displayNote = AccountingReferenceDisplay.displayDescriptionValue(
      description: entry.note,
      referenceType: entry.referenceType,
      referenceId: entry.referenceId,
      referenceCode: entry.documentNumber,
      languageCode: languageCode,
    );
    final displayReference = AccountingReferenceDisplay.displayReference(
      referenceType: entry.referenceType,
      referenceId: entry.referenceId,
      referenceCode: entry.documentNumber,
      languageCode: languageCode,
    );

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
                  Expanded(
                    child: Text(
                      displayDocument,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                displayNote,
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
                      entry.transactionTypeLabel ?? entry.transactionType,
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
                            context.tr(
                              'accounting.gl_detail_channel_chip',
                              params: {
                                'channel':
                                    entry.moneyChannelLabel ??
                                    entry.moneyChannel ??
                                    '-',
                              },
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      if (entry.referenceType.isNotEmpty &&
                          entry.referenceId != null)
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
                            displayReference,
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
      return await context.read<OrderBloc>().repository.getOrder(
        entityId.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  void _showEntryDetail(GeneralLedgerEntryModel entry) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final displayDocument = AccountingReferenceDisplay.displayDocument(
      documentNumber: entry.documentNumber,
      referenceType: entry.referenceType,
      referenceId: entry.referenceId,
      referenceCode: entry.documentNumber,
      languageCode: languageCode,
    );
    final displayNote = AccountingReferenceDisplay.displayDescriptionValue(
      description: entry.note,
      referenceType: entry.referenceType,
      referenceId: entry.referenceId,
      referenceCode: entry.documentNumber,
      languageCode: languageCode,
    );
    final displayReference = AccountingReferenceDisplay.displayReference(
      referenceType: entry.referenceType,
      referenceId: entry.referenceId,
      referenceCode: entry.documentNumber,
      languageCode: languageCode,
      fallback: '-',
    );

    final entityType = (entry.entityType ?? '').toLowerCase();
    final entityId = entry.entityId ?? 0;

    if (entityType == 'order' && entityId > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(orderId: entityId.toString()),
        ),
      );
      return;
    }

    if ((entityType == 'import' || entityType == 'inventoryimport') &&
        entityId > 0) {
      final locationId = context.read<BusinessContext>().currentBusinessId;
      AppRouter.navigateTo(
        AppRoutes.stockImport,
        arguments: {'locationId': locationId, 'importId': entityId},
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.tr(
            'accounting.gl_detail_title',
            params: {'id': entry.entryId.toString()},
          ),
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr(
                    'accounting.gl_detail_document',
                    params: {'value': displayDocument},
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'accounting.gl_detail_document_date',
                    params: {'value': entry.documentDate ?? '-'},
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'accounting.gl_detail_date',
                    params: {'value': entry.date},
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'accounting.gl_detail_note',
                    params: {'value': displayNote},
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'accounting.gl_detail_transaction_type',
                    params: {
                      'value': entry.transactionTypeLabel ?? entry.transactionType,
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'accounting.gl_detail_money_channel',
                    params: {
                      'value':
                          entry.moneyChannelLabel ?? entry.moneyChannel ?? '-',
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'accounting.gl_detail_reference',
                    params: {'type': displayReference, 'id': ''},
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'accounting.gl_detail_entity',
                    params: {
                      'type': entry.entityType ?? '-',
                      'id': (entry.entityId ?? '').toString(),
                    },
                  ),
                ),
                if ((entry.entityType ?? '').toLowerCase() == 'order' &&
                    (entry.entityId ?? 0) > 0) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('accounting.linked_order_detail'),
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
                        return Text(
                          context.tr('accounting.order_detail_unavailable'),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              'accounting.gl_detail_order_id',
                              params: {'value': order.id.toString()},
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(
                              'accounting.gl_detail_order_status',
                              params: {'value': order.status},
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(
                              'accounting.gl_detail_order_total',
                              params: {
                                'value': NumberFormat.currency(
                                  locale: 'vi',
                                  symbol: 'đ',
                                ).format(order.totalAmount),
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '• ${item.productName} x${item.quantity}',
                              ),
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
        resetDates: result['resetDates'] as bool? ?? false,
      );
    }
  }
}
