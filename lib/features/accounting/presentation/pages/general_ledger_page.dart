import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/gl_bloc/gl_bloc.dart';
import '../bloc/gl_bloc/gl_event.dart';
import '../bloc/gl_bloc/gl_state.dart';
import '../widgets/gl_filter_bottom_sheet.dart';
import '../../../accounting/data/models/general_ledger_entry_model.dart';

class GeneralLedgerPage extends StatefulWidget {
  const GeneralLedgerPage({super.key});

  @override
  State<GeneralLedgerPage> createState() => _GeneralLedgerPageState();
}

class _GeneralLedgerPageState extends State<GeneralLedgerPage> {
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  void _loadData({bool isLoadMore = false, int pageNumber = 1}) {
    final locationId = context.read<BusinessContext>().currentBusinessId;
    if (locationId == null) return;

    final state = context.read<GLBloc>().state;
    GLLoaded? currentState;
    if (state is GLLoaded) currentState = state;

    context.read<GLBloc>().add(LoadGLEntriesRequested(
          businessLocationId: int.parse(locationId),
          pageNumber: pageNumber,
          pageSize: _pageSize,
          isLoadMore: isLoadMore,
          transactionTypes: currentState?.transactionTypes,
          referenceTypes: currentState?.referenceTypes,
          moneyChannels: currentState?.moneyChannels,
          fromDate: currentState?.fromDate,
          toDate: currentState?.toDate,
          viewMode: currentState?.viewMode ?? 'audit',
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.tr('accounting.general_ledger', params: {})),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.primary),
            onPressed: _showFiltersBottomSheet,
          ),
        ],
      ),
      body: BlocBuilder<GLBloc, GLState>(
        builder: (context, state) {
          if (state is GLInitial || state is GLLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GLError) {
            final hasData = state.previousEntries != null && state.previousEntries!.isNotEmpty;
            if (!hasData) {
               return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(state.message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: Text(context.tr('common.retry')),
                      ),
                    ],
                  ),
                ),
              );
            }
            // If it has data, just show the snackbar for error and continue displaying data.
            WidgetsBinding.instance.addPostFrameCallback((_) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            });
            return _buildListView(state.previousEntries!, true);
          }

          if (state is GLLoaded) {
             if (state.entries.isEmpty) {
               return _buildEmptyState();
             }
             return _buildListView(state.entries, state.hasReachedMax, isLoadMore: state.isLoadMore);
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
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            context.tr('accounting.gl_empty'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('accounting.gl_empty_sub'),
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<GeneralLedgerEntryModel> entries, bool hasReachedMax, {bool isLoadMore = false}) {
     return RefreshIndicator(
       onRefresh: () async {
         _loadData();
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

  Widget _buildEntryCard(GeneralLedgerEntryModel entry) {
    // Parse date safely
    DateTime? dateObj;
    try {
      dateObj = DateTime.parse(entry.date);
    } catch (_) {}
    
    final dateStr = dateObj != null ? DateFormat('dd/MM/yyyy HH:mm').format(dateObj.toLocal()) : entry.date;
    final formatter = NumberFormat.currency(locale: 'vi', symbol: 'đ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      surfaceTintColor: Colors.white,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to Details base on ReferenceType and ReferenceId
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
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                   ),
                   Text(
                     formatter.format(entry.amount),
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 16,
                       color: entry.amount >= 0 ? AppColors.success : AppColors.error,
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 8),
               Text(
                 entry.note,
                 style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
               ),
               const SizedBox(height: 8),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(
                     dateStr,
                     style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                   ),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: Colors.grey.shade100,
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(
                       entry.transactionType,
                       style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                     ),
                   )
                 ],
               )
             ],
          ),
        ),
      ),
    );
  }

  void _showFiltersBottomSheet() async {
    final currentState = context.read<GLBloc>().state;
    if (currentState is! GLLoaded) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: MediaQuery.of(context).padding.top + kToolbarHeight,
        ),
        child: GLFilterBottomSheet(
          currentTransactionTypes: currentState.transactionTypes,
          currentReferenceTypes: currentState.referenceTypes,
          currentMoneyChannels: currentState.moneyChannels,
          currentFromDate: currentState.fromDate,
          currentToDate: currentState.toDate,
          currentViewMode: currentState.viewMode,
        ),
      ),
    );

    if (result != null) {
      if (!mounted) return;
      context.read<GLBloc>().add(ChangeGLFiltersRequested(
            transactionTypes: result['transactionTypes'],
            referenceTypes: result['referenceTypes'],
            moneyChannels: result['moneyChannels'],
            fromDate: result['fromDate'],
            toDate: result['toDate'],
            viewMode: result['viewMode'],
          ));
      // Triggers load immediately following filter change
      _loadData(pageNumber: 1, isLoadMore: false);
    }
  }
}
