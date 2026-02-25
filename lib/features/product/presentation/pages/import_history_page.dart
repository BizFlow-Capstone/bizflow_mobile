import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../data/import_repository.dart';
import '../bloc/import_history/import_history_bloc.dart';
import '../bloc/import_history/import_history_event.dart';
import '../bloc/import_history/import_history_state.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_state.dart';
import 'stock_import_page.dart';

class ImportHistoryPage extends StatelessWidget {
  const ImportHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Attempt to get the selected location from LocationBloc
    int? locationId;
    final locationState = context.read<LocationBloc>().state;
    if (locationState is LocationsLoaded &&
        locationState.locations.isNotEmpty) {
      locationId = int.tryParse(locationState.locations.first.id ?? '');
    }

    final importRepo = context.read<ImportRepository>();
    return BlocProvider(
      create: (context) =>
          ImportHistoryBloc(repository: importRepo)
            ..add(UpdateFilters(businessLocationId: locationId)),
      child: const _ImportHistoryView(),
    );
  }
}

class _ImportHistoryView extends StatefulWidget {
  const _ImportHistoryView();

  @override
  State<_ImportHistoryView> createState() => _ImportHistoryViewState();
}

class _ImportHistoryViewState extends State<_ImportHistoryView> {
  final ScrollController _scrollController = ScrollController();
  bool _needsRefresh = false;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ImportHistoryBloc>().add(const LoadMoreImportHistory());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 200);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _needsRefresh) {
          // Since we already popped, we might need a different way to return the value if not through Navigator.pop
          // But usually, standard back button doesn't return value easily in older Flutter.
          // In latest Flutter, we can try to use result if possible or just handle it.
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _needsRefresh),
            color: Colors.black,
          ),
          title: Text(
            l10n.translate('stock_import.history_title'),
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterBottomSheet,
            ),
          ],
        ),
        body: BlocBuilder<ImportHistoryBloc, ImportHistoryState>(
          builder: (context, state) {
            if (state.status == ImportHistoryStatus.initial ||
                state.status == ImportHistoryStatus.loading &&
                    state.items.isEmpty) {
              return const Center(child: AppLoadingIndicator());
            }

            if (state.status == ImportHistoryStatus.failure &&
                state.items.isEmpty) {
              return Center(
                child: Text(
                  state.errorMessage ?? l10n.translate('common.error'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              );
            }

            if (state.items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: AppColors.textDisabled,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.translate('stock_import.no_history'),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ImportHistoryBloc>().add(
                  const RefreshImportHistory(),
                );
              },
              child: ListView.separated(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  bottom: 80,
                ),
                itemCount: state.hasReachedMax
                    ? state.items.length
                    : state.items.length + 1,
                separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return const Center(child: AppLoadingIndicator());
                  }

                  final item = state.items[index];
                  return _ImportHistoryCard(
                    item: item,
                    onTap: () {
                      // Navigate to StockImportPage to view or edit
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StockImportPage(
                            locationId: item.businessLocationId.toString(),
                            importId: item
                                .importId, // We will update StockImportPage to accept this
                          ),
                        ),
                      ).then((result) {
                        if (result == true && context.mounted) {
                          context.read<ImportHistoryBloc>().add(
                            const RefreshImportHistory(),
                          );
                          // Store the fact that something changed to return it to ProductManagementPage
                          setState(() => _needsRefresh = true);
                        }
                      });
                    },
                  );
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          onPressed: () {
            // Nav to create new import
            final locState = context.read<LocationBloc>().state;
            String currentLocId = '0';
            if (locState is LocationsLoaded && locState.locations.isNotEmpty) {
              currentLocId = locState.locations.first.id ?? '0';
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockImportPage(locationId: currentLocId),
              ),
            ).then((result) {
              if (result == true && context.mounted) {
                context.read<ImportHistoryBloc>().add(
                  const RefreshImportHistory(),
                );
                // Store the fact that something changed
                setState(() => _needsRefresh = true);
              }
            });
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            l10n.translate('stock_import.add_new'),
            style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    // Optionally implement a bottom sheet to set filters (Status, Date range)
  }
}

class _ImportHistoryCard extends StatelessWidget {
  final dynamic item; // ImportHistoryItemModel
  final VoidCallback onTap;

  _ImportHistoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color statusColor;
    String statusText;

    switch (item.status) {
      case 'DRAFT':
        statusColor = AppColors.warning;
        statusText = l10n.translate('stock_import.status_draft');
        break;
      case 'CONFIRMED':
        statusColor = AppColors.success;
        statusText = l10n.translate('stock_import.status_imported');
        break;
      case 'CANCELLED':
        statusColor = AppColors.error;
        statusText = l10n.translate('order.status_cancelled');
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = item.status;
    }

    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final formatDate = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.importCode,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.storefront,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      item.businessLocationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    formatDate.format(item.createdAt),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Divider(color: AppColors.divider),
              SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.translate('stock_import.receipt_total')}:',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    formatCurrency.format(item.totalAmount),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
