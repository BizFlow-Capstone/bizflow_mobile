import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/reference/presentation/bloc/reference_bloc.dart';
import '../../../../core/reference/presentation/bloc/reference_event.dart';
import '../../../../core/reference/presentation/bloc/reference_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/services/permission_service.dart';
import '../../../../shared/utils/action_guard.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_text_field.dart';

import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';
import '../../domain/entities/debtor_entity.dart';
import '../bloc/debtor_bloc.dart';
import '../bloc/debtor_event.dart';
import '../bloc/debtor_state.dart';
import 'debt_detail_page.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_state.dart';

class DebtListPage extends StatefulWidget {
  const DebtListPage({super.key});

  @override
  State<DebtListPage> createState() => _DebtListPageState();
}

class _DebtListPageState extends State<DebtListPage> {
  final Set<int> _expandedCards = {};
  final TextEditingController _searchController = TextEditingController();
  final ActionGuard _debtorActionGuard = ActionGuard();
  int? _selectedLocationId;
  Completer<void>? _debtorActionCompleter;
  bool _isPermissionChecking = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final refState = context.read<ReferenceBloc>().state;
    if (refState is! ReferenceLoaded && refState is! ReferenceLoading) {
      context.read<ReferenceBloc>().add(LoadAllReferencesRequested());
    }
    _loadDebtors();
  }

  List<String> _paymentMethodsFromReference() {
    final state = context.read<ReferenceBloc>().state;
    if (state is ReferenceLoaded) {
      final methods = (state.references['paymentMethods'] ?? const <String>[])
          .where((m) => m.trim().isNotEmpty)
          .toSet()
          .toList();
      if (methods.isNotEmpty) return methods;
    }
    return const <String>['CASH', 'BANK_TRANSFER'];
  }

  @override
  void dispose() {
    _completeDebtorAction();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _completeDebtorAction() {
    final completer = _debtorActionCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _debtorActionCompleter = null;
  }

  Future<void> _runDebtorAction(VoidCallback action) async {
    await _debtorActionGuard.run(() async {
      final completer = Completer<void>();
      _debtorActionCompleter = completer;
      action();
      await completer.future;
    });
  }

  void _setPermissionChecking(bool value) {
    if (!mounted) return;
    if (_isPermissionChecking == value) return;
    setState(() {
      _isPermissionChecking = value;
    });
  }

  void _loadDebtors({
    String? search,
    bool? isActive,
    int? locationId,
    bool clearLocation = false,
  }) {
    final businessContext = context.read<BusinessContext>();
    final isOwner = businessContext.isOwner;
    final currentLocationId = int.tryParse(
      businessContext.currentBusinessId ?? '',
    );
    final int? locId;
    if (!isOwner && currentLocationId != null && currentLocationId > 0) {
      locId = currentLocationId;
    } else if (clearLocation) {
      locId = null;
    } else {
      locId = locationId ?? _selectedLocationId;
    }
    context.read<DebtorBloc>().add(
      LoadDebtorsRequested(
        search: search,
        isActive: isActive,
        businessLocationIds: locId != null ? [locId] : null,
      ),
    );
  }

  /// Shows filter bottom sheet and applies the selected filters.
  void _showFilterSheet(DebtorState state, List<dynamic> locations) {
    bool? tempIsActive = state.isActive;
    int? tempLocationId = _selectedLocationId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(context);
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('debt.filter_title'),
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            tempIsActive = null;
                            tempLocationId = null;
                          });
                        },
                        child: Text(l10n.translate('debt.filter_reset')),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  // --- Status filter ---
                  Text(
                    l10n.translate('debt.filter_status'),
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.translate('debt.filter_all')),
                        selected: tempIsActive == null,
                        onSelected: (_) =>
                            setSheetState(() => tempIsActive = null),
                      ),
                      ChoiceChip(
                        label: Text(l10n.translate('debt.filter_active')),
                        selected: tempIsActive == true,
                        onSelected: (_) =>
                            setSheetState(() => tempIsActive = true),
                      ),
                      ChoiceChip(
                        label: Text(l10n.translate('debt.filter_inactive')),
                        selected: tempIsActive == false,
                        onSelected: (_) =>
                            setSheetState(() => tempIsActive = false),
                      ),
                    ],
                  ),
                  // --- Location filter (only if > 1 location) ---
                  if (locations.length > 1) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.translate('debt.filter_location'),
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.translate('debt.filter_all')),
                          selected: tempLocationId == null,
                          onSelected: (_) =>
                              setSheetState(() => tempLocationId = null),
                        ),
                        ...locations.map((loc) {
                          final locId = int.tryParse(loc.id.toString());
                          return ChoiceChip(
                            label: Text(loc.name),
                            selected: tempLocationId == locId,
                            onSelected: (_) => setSheetState(
                              () => tempLocationId = tempLocationId == locId
                                  ? null
                                  : locId,
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (_selectedLocationId != tempLocationId) {
                          setState(() => _selectedLocationId = tempLocationId);
                          _loadDebtors(
                            isActive: tempIsActive,
                            locationId: tempLocationId,
                          );
                        } else if (state.isActive != tempIsActive) {
                          context.read<DebtorBloc>().add(
                                FilterDebtorsRequested(tempIsActive),
                              );
                        }
                      },
                      child: Text(l10n.translate('debt.filter_apply')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';
    final isOwner = context.watch<BusinessContext>().isOwner;
    final canCreateDebtor = PermissionService.canCreateDebtor(isOwner);
    final canDeleteDebtor = PermissionService.canDeleteDebtor(isOwner);

    final canManageDebt = true;
    final disableActions = _isPermissionChecking;

    return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.textPrimary,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            elevation: 0,
            title: Text(
              isVietnamese
                  ? l10n.translate('debt.title_vi')
                  : l10n.translate('debt.title'),
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
              color: Colors.black,
            ),
            actions: [
              if (canCreateDebtor)
                IconButton(
                  onPressed: (canManageDebt && !disableActions)
                      ? () => _showDebtorForm()
                      : null,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                ),
            ],
          ),
          body: SafeArea(
            child: BlocConsumer<DebtorBloc, DebtorState>(
              listener: (context, state) {
                if (_debtorActionCompleter != null && !state.isSubmitting) {
                  _completeDebtorAction();
                }
                if (state.lastMessageCode == 'DEBTOR_DELETED') {
                  AppSnackBar.show(
                    context,
                    message: l10n.translate('debt.delete_success'),
                    type: AppSnackBarType.success,
                  );
                }
                if (state.lastMessageCode == 'DEBTOR_STATUS_ACTIVATED' ||
                    state.lastMessageCode == 'DEBTOR_STATUS_DEACTIVATED') {
                  AppSnackBar.show(
                    context,
                    message: l10n.translate('debt.status_updated'),
                    type: AppSnackBarType.success,
                  );
                }
                if (state.lastMessageCode == 'DEBTOR_CREATED') {
                  AppSnackBar.show(
                    context,
                    message: l10n.translate('debt.create_success'),
                    type: AppSnackBarType.success,
                  );
                }
                if (state.lastMessageCode == 'DEBTOR_UPDATED') {
                  AppSnackBar.show(
                    context,
                    message: l10n.translate('debt.update_success'),
                    type: AppSnackBarType.success,
                  );
                }
                if (state.lastMessageCode == 'DEBT_ADJUSTMENT_RECORDED') {
                  AppSnackBar.show(
                    context,
                    message: l10n.translate('debt.adjust_success'),
                    type: AppSnackBarType.success,
                  );
                }
                if (state.status == DebtorStatus.failure &&
                    state.errorMessage != null &&
                    state.errorMessage!.isNotEmpty) {
                  AppSnackBar.show(
                    context,
                    message: state.errorMessage!,
                    type: AppSnackBarType.error,
                  );
                }
              },
              builder: (context, state) {
                final customers = state.debtors;
                final totalDebt = customers.fold<double>(
                  0,
                  (sum, c) => sum + c.currentBalance,
                );

                return Column(
                  children: [
                    // ---- Search + Filter button row ----
                    BlocBuilder<LocationBloc, LocationState>(
                      builder: (context, locationState) {
                        final locations =
                            isOwner && locationState is LocationsLoaded
                            ? locationState.locations
                                  .where((l) => l.isActive)
                                  .toList()
                            : <dynamic>[];

                        // Count active filters for badge
                        final activeFilterCount =
                            (state.isActive != null ? 1 : 0) +
                            (_selectedLocationId != null ? 1 : 0);

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  textInputAction: TextInputAction.search,
                                  onChanged: (value) {
                                    _searchDebounce?.cancel();
                                    _searchDebounce = Timer(
                                      const Duration(milliseconds: 300),
                                      () {
                                        context.read<DebtorBloc>().add(
                                              SearchDebtorsRequested(value),
                                            );
                                      },
                                    );
                                  },
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search),
                                    hintText: l10n.translate(
                                      'common.search_hint',
                                    ),
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                        ? IconButton(
                                            onPressed: () {
                                              _searchController.clear();
                                              context.read<DebtorBloc>().add(
                                                    const SearchDebtorsRequested(
                                                      '',
                                                    ),
                                                  );
                                              setState(() {});
                                            },
                                            icon: const Icon(Icons.close),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              // Filter button with badge
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton.outlined(
                                    onPressed: () =>
                                        _showFilterSheet(state, locations),
                                    icon: const Icon(Icons.tune_rounded),
                                    style: IconButton.styleFrom(
                                      foregroundColor: activeFilterCount > 0
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : null,
                                      side: activeFilterCount > 0
                                          ? BorderSide(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              width: 1.5,
                                            )
                                          : null,
                                    ),
                                  ),
                                  if (activeFilterCount > 0)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$activeFilterCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              title: l10n.translate('debt.total_debt'),
                              value: CurrencyFormatter.formatVND(totalDebt),
                              bgColor: AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildSummaryCard(
                              title: l10n.translate('debt.customer_count'),
                              value:
                                  '${customers.length} ${l10n.translate('debt.customers')}',
                              bgColor: const Color(0xFF2C2C2C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.status == DebtorStatus.loading &&
                        customers.isEmpty)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (customers.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                l10n.translate('debt.no_debt'),
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.translate('debt.no_debt_sub'),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async => _loadDebtors(
                            search: _searchController.text,
                            isActive: state.isActive,
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.md,
                              right: AppSpacing.md,
                              bottom: 40,
                            ),
                            itemCount: customers.length,
                            itemBuilder: (context, index) {
                              return _buildCustomerCard(
                                context,
                                customers[index],
                                index,
                                l10n,
                                canManageDebt,
                                canDeleteDebtor,
                                disableActions,
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          floatingActionButton: canCreateDebtor
              ? FloatingActionButton(
                  tooltip: l10n.translate('debt.create_customer'),
                  onPressed: !disableActions ? () => _showDebtorForm() : null,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add),
                )
              : null,
        );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    DebtorEntity customer,
    int index,
    AppLocalizations l10n,
    bool canManageDebt,
    bool canDeleteDebtor,
    bool disableActions,
  ) {
    final isExpanded = _expandedCards.contains(index);
    final locationDisplay = customer.businessLocationName.trim().isNotEmpty
        ? customer.businessLocationName.trim()
        : ((customer.address ?? '').trim().isNotEmpty
              ? (customer.address ?? '').trim()
              : l10n.translate('common.no_data'));

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCards.remove(index);
                } else {
                  _expandedCards.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.name,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: customer.isActive
                              ? AppColors.success.withValues(alpha: 0.15)
                              : AppColors.textHint.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          customer.isActive
                              ? l10n.translate('debt.status_active')
                              : l10n.translate('debt.status_inactive'),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: customer.isActive
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customer.phone,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _buildDebtColumn(
                        l10n.translate('debt.total_owed'),
                        CurrencyFormatter.formatVND(customer.currentBalance),
                        AppColors.danger,
                      ),
                      _buildDebtColumn(
                        l10n.translate('debt.location'),
                        locationDisplay,
                        AppColors.textPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((customer.address ?? '').isNotEmpty &&
                      (customer.address ?? '').trim() != locationDisplay) ...[
                    Text(
                      '${l10n.translate('debt.address')}: ${customer.address}',
                      style: AppTextStyles.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  if ((customer.notes ?? '').isNotEmpty) ...[
                    Text(
                      '${l10n.translate('debt.note')}: ${customer.notes}',
                      style: AppTextStyles.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DebtDetailPage(debtorId: customer.debtorId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: Text(l10n.translate('debt.view_detail')),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (canManageDebt && !disableActions)
                              ? () => _showDebtAdjustmentDialog(customer)
                              : null,
                          icon: const Icon(Icons.swap_vert_circle_outlined),
                          label: Text(l10n.translate('debt.adjust_debt')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 420) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        (canManageDebt && !disableActions)
                                        ? () => _showDebtorForm(
                                            existing: customer,
                                          )
                                        : null,
                                    icon: const Icon(Icons.edit_outlined),
                                    label: Text(l10n.translate('common.edit')),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        (canManageDebt && !disableActions)
                                        ? () {
                                            _runDebtorAction(() {
                                              context.read<DebtorBloc>().add(
                                                ToggleDebtorStatusRequested(
                                                  debtorId: customer.debtorId,
                                                  isActive: !customer.isActive,
                                                ),
                                              );
                                            });
                                          }
                                        : null,
                                    icon: Icon(
                                      customer.isActive
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    label: Text(
                                      customer.isActive
                                          ? l10n.translate('debt.deactivate')
                                          : l10n.translate('debt.activate'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (canDeleteDebtor) ...[
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      (canManageDebt &&
                                          canDeleteDebtor &&
                                          !disableActions)
                                      ? () => _confirmDelete(customer)
                                      : null,
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(l10n.translate('common.delete')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.danger,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (canManageDebt && !disableActions)
                                  ? () => _showDebtorForm(existing: customer)
                                  : null,
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(l10n.translate('common.edit')),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (canManageDebt && !disableActions)
                                  ? () {
                                      _runDebtorAction(() {
                                        context.read<DebtorBloc>().add(
                                          ToggleDebtorStatusRequested(
                                            debtorId: customer.debtorId,
                                            isActive: !customer.isActive,
                                          ),
                                        );
                                      });
                                    }
                                  : null,
                              icon: Icon(
                                customer.isActive
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              label: Text(
                                customer.isActive
                                    ? l10n.translate('debt.deactivate')
                                    : l10n.translate('debt.activate'),
                              ),
                            ),
                          ),
                          if (canDeleteDebtor) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    (canManageDebt &&
                                        canDeleteDebtor &&
                                        !disableActions)
                                    ? () => _confirmDelete(customer)
                                    : null,
                                icon: const Icon(Icons.delete_outline),
                                label: Text(l10n.translate('common.delete')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebtColumn(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(DebtorEntity customer) async {
    final l10n = AppLocalizations.of(context);

    final normalDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.translate('debt.delete_confirm_title')),
          content: Text(
            l10n
                .translate('debt.delete_confirm_message')
                .replaceAll('{name}', customer.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.translate('common.delete')),
            ),
          ],
        );
      },
    );

    if (normalDelete != true || !mounted) return;

    _setPermissionChecking(true);
    final allowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.debtManagement,
    );
    _setPermissionChecking(false);
    if (!allowed) return;

    try {
      await _runDebtorAction(() {
        context.read<DebtorBloc>().add(
          DeleteDebtorRequested(debtorId: customer.debtorId, force: false),
        );
      });
    } catch (_) {
      if (!mounted) return;
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final state = context.read<DebtorBloc>().state;
    final errorText = state.errorMessage?.toLowerCase() ?? '';
    final needsForce =
        errorText.contains('nợ') ||
        errorText.contains('debt') ||
        errorText.contains('cannot delete') ||
        errorText.contains('force');

    if (!needsForce) return;

    final forceDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.translate('debt.force_delete_title')),
          content: Text(l10n.translate('debt.force_delete_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.translate('debt.force_delete')),
            ),
          ],
        );
      },
    );

    if (forceDelete == true && mounted) {
      await _runDebtorAction(() {
        context.read<DebtorBloc>().add(
          DeleteDebtorRequested(debtorId: customer.debtorId, force: true),
        );
      });
    }
  }

  Future<void> _showDebtorForm({DebtorEntity? existing}) async {
    final l10n = AppLocalizations.of(context);
    final isOwner = context.read<BusinessContext>().isOwner;
    if (existing == null && !PermissionService.canCreateDebtor(isOwner)) {
      AppSnackBar.show(
        context,
        message: l10n.translate('common.permission_denied'),
        type: AppSnackBarType.warning,
      );
      return;
    }

    // Check subscription limit BEFORE showing the form.
    if (existing == null) {
      final allowed = await SubscriptionFeatureGuard.ensureAllowed(
        context,
        featureCode: SubscriptionFeatureCodes.debtManagement,
      );
      if (!allowed || !mounted) return;
    }
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final addressController = TextEditingController(
      text: existing?.address ?? '',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final creditLimitController = TextEditingController(
      text: existing == null
          ? ''
          : CurrencyFormatter.formatNumber(existing.creditLimit),
    );

    final nameFocusNode = FocusNode();
    final phoneFocusNode = FocusNode();

    String? nameError;
    String? phoneError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? l10n.translate('debt.create_title')
                    : l10n.translate('debt.edit_title'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      focusNode: nameFocusNode,
                      decoration: InputDecoration(
                        labelText: '${l10n.translate('order_create.customer_name')} *',
                        errorText: nameError,
                      ),
                      onChanged: (_) {
                        if (nameError != null) setState(() => nameError = null);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: phoneController,
                      focusNode: phoneFocusNode,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: '${l10n.translate('order_create.customer_phone')} *',
                        errorText: phoneError,
                      ),
                      onChanged: (_) {
                        if (phoneError != null) setState(() => phoneError = null);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: l10n.translate('debt.address'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: l10n.translate('debt.note'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: creditLimitController,
                      keyboardType: TextInputType.number,
                      inputFormatters: AppInputFormatters.withSqlInjectionGuard(
                        inputFormatters: [CurrencyInputFormatter()],
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.translate('debt.credit_limit'),
                        suffixText: 'đ',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.translate('common.cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();

                    setState(() {
                      nameError = name.isEmpty ? l10n.translate('common.required_field') : null;
                      phoneError = phone.isEmpty ? l10n.translate('common.required_field') : null;
                    });

                    if (name.isEmpty) {
                      nameFocusNode.requestFocus();
                      return;
                    }

                    if (phone.isEmpty) {
                      phoneFocusNode.requestFocus();
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(l10n.translate('common.save')),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      nameFocusNode.dispose();
      phoneFocusNode.dispose();
    });

    if (confirmed != true || !mounted) return;

    final name = nameController.text.trim();

    final creditLimit = double.tryParse(
      creditLimitController.text.replaceAll(',', ''),
    );

    if (existing == null) {
      final locationId = int.tryParse(
        BusinessContext().currentBusinessId ?? '',
      );
      if (locationId == null || locationId <= 0) {
        if (!mounted) return;
        AppSnackBar.show(
          context,
          message: l10n.translate('debt.location_required'),
          type: AppSnackBarType.warning,
        );
        return;
      }
      await _runDebtorAction(() {
        context.read<DebtorBloc>().add(
          CreateDebtorRequested(
            businessLocationId: locationId,
            name: name,
            phone: phoneController.text.trim().isEmpty
                ? null
                : phoneController.text.trim(),
            address: addressController.text.trim().isEmpty
                ? null
                : addressController.text.trim(),
            notes: notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
            creditLimit: creditLimit,
          ),
        );
      });
    } else {
      await _runDebtorAction(() {
        context.read<DebtorBloc>().add(
          UpdateDebtorRequested(
            debtorId: existing.debtorId,
            name: name,
            phone: phoneController.text.trim().isEmpty
                ? null
                : phoneController.text.trim(),
            address: addressController.text.trim().isEmpty
                ? null
                : addressController.text.trim(),
            notes: notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
            creditLimit: creditLimit,
          ),
        );
      });
    }
  }

  Future<void> _showDebtAdjustmentDialog(DebtorEntity customer) async {
    final l10n = AppLocalizations.of(context);
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String direction = 'increase';
    final paymentMethods = _paymentMethodsFromReference();
    String paymentMethod = paymentMethods.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.translate('debt.adjust_title')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: direction,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      decoration: InputDecoration(
                        labelText: l10n.translate('debt.adjust_type'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'increase',
                          child: Text(l10n.translate('debt.adjust_increase')),
                        ),
                        DropdownMenuItem(
                          value: 'decrease',
                          child: Text(l10n.translate('debt.adjust_reduce')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => direction = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: AppInputFormatters.withSqlInjectionGuard(
                        inputFormatters: [CurrencyInputFormatter()],
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.translate('debt.adjust_amount'),
                        suffixText: 'đ',
                      ),
                    ),
                    if (direction == 'decrease') ...[
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: paymentMethod,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        items: paymentMethods
                            .map(
                              (method) => DropdownMenuItem(
                                value: method,
                                child: Text(method),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => paymentMethod = value);
                        },
                        decoration: InputDecoration(
                          labelText: l10n.translate('debt.payment_method'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: l10n.translate('debt.note'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.translate('common.cancel')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(l10n.translate('common.confirm')),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    _setPermissionChecking(true);
    final allowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.debtManagement,
    );
    _setPermissionChecking(false);
    if (!allowed) return;

    final rawAmount = double.tryParse(
      amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (rawAmount == null || rawAmount <= 0) return;

    final signedAmount = direction == 'decrease' ? -rawAmount : rawAmount;

    // Check if debt increase exceeds credit limit
    if (direction == 'increase' &&
        customer.creditLimit > 0 &&
        (customer.currentBalance + rawAmount) > customer.creditLimit) {
      final confirmExceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.translate('debt.credit_limit_warning_title')),
          content: Text(l10n.translate('debt.credit_limit_warning_message')),
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
      if (confirmExceed != true || !mounted) return;
    }

    await _runDebtorAction(() {
      context.read<DebtorBloc>().add(
        RecordDebtAdjustmentRequested(
          debtorId: customer.debtorId,
          amount: signedAmount,
          paymentMethod: paymentMethod,
          notes: noteController.text.trim().isEmpty
              ? null
              : noteController.text.trim(),
        ),
      );
    });
  }
}
