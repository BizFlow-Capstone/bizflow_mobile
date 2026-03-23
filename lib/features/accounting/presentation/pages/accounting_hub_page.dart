import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:bizflow_mobile/features/revenue/presentation/bloc/revenue_bloc.dart';
import 'package:bizflow_mobile/features/revenue/domain/entities/revenue_entity.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/dialogs/app_dialog.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../bloc/accounting_period_bloc.dart';
import '../models/accounting_mock_models.dart';
import '../widgets/accounting_books_reports_tab.dart';
import '../widgets/accounting_cost_revenue_tab.dart';
import '../widgets/accounting_gl_tab.dart';
import '../widgets/accounting_period_tab.dart';

class AccountingHubPage extends StatefulWidget {
  const AccountingHubPage({super.key});

  @override
  State<AccountingHubPage> createState() => _AccountingHubPageState();
}

class _AccountingHubPageState extends State<AccountingHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Period BLoC data is managed by AccountingPeriodBloc
  // Other tabs still use local/mock state for now
  DateTime _reportFromDate = DateTime(2026, 1, 1);
  DateTime _reportToDate = DateTime(2026, 3, 31);
  String _reportFormat = 'pdf';

  final List<AccountingItemModel> _costs = [
    AccountingItemModel(
      code: 'COST-2026-019',
      date: DateTime(2026, 2, 24),
      description: 'Electricity bill',
      amount: 1500000,
      type: 'utilities',
    ),
  ];

  final List<BookItemModel> _books = const [
    BookItemModel(code: 'S1a', name: 'Sổ chi tiết bán hàng', group: 'Nhóm 1'),
    BookItemModel(
      code: 'S2a',
      name: 'Sổ doanh thu bán hàng hóa, dịch vụ',
      group: 'Nhóm 2 - Cách 1',
    ),
    BookItemModel(
      code: 'S2b',
      name: 'Sổ doanh thu bán hàng hóa, dịch vụ',
      group: 'Nhóm 2/3/4 - Cách 2',
    ),
  ];

  final List<TaxPaymentItemModel> _taxPayments = [
    TaxPaymentItemModel(
      taxType: 'VAT',
      amount: 6200000,
      date: DateTime(2026, 2, 28),
      reference: 'NSNN-2026-0012',
    ),
  ];

  AppLocalizations get l10n => AppLocalizations.of(context);


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Trigger load of accounting periods from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationId = context.read<BusinessContext>().currentBusinessId;
      if (locationId != null) {
        context.read<AccountingPeriodBloc>().add(
              LoadPeriodsRequested(locationId),
            );
        context.read<RevenueBloc>().add(
              LoadRevenuesRequested(businessLocationId: locationId),
            );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  Future<bool> _confirmAction({
    required String title,
    required String message,
  }) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: title,
      message: message,
      confirmText: l10n.translate('common.confirm'),
      cancelText: l10n.translate('common.cancel'),
    );
    return confirmed == true;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }




  Future<void> _editAccountingItem({
    required AccountingItemModel item,
    required bool isRevenue,
  }) async {
    final descriptionController = TextEditingController(text: item.description);
    final amountController = TextEditingController(
      text: CurrencyFormatter.formatNumber(item.amount),
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isRevenue
              ? l10n.translate('accounting.edit_revenue')
              : l10n.translate('accounting.edit_cost'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: l10n.translate('accounting.description'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: InputDecoration(
                labelText: l10n.translate('accounting.amount'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount =
                  (CurrencyFormatter.parse(amountController.text) ?? 0)
                      .toDouble();
              if (descriptionController.text.trim().isEmpty || amount <= 0) {
                return;
              }

              final ok = await _confirmAction(
                title: l10n.translate('accounting.confirm_title'),
                message: l10n.translate('accounting.confirm_update_item'),
              );
              if (!ok) return;

              setState(() {
                item.description = descriptionController.text.trim();
                item.amount = amount;
              });

              if (context.mounted) {
                Navigator.pop(ctx);
                _showSuccess(l10n.translate('accounting.updated_success'));
              }
            },
            child: Text(l10n.translate('common.save')),
          ),
        ],
      ),
    );

    descriptionController.dispose();
    amountController.dispose();
  }

  Future<void> _editTaxPayment(TaxPaymentItemModel item) async {
    final amountController = TextEditingController(
      text: CurrencyFormatter.formatNumber(item.amount),
    );
    final refController = TextEditingController(text: item.reference);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('accounting.edit_tax_payment')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: InputDecoration(
                labelText: l10n.translate('accounting.amount'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: refController,
              decoration: InputDecoration(
                labelText: l10n.translate('accounting.reference_number'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount =
                  (CurrencyFormatter.parse(amountController.text) ?? 0)
                      .toDouble();
              if (amount <= 0 || refController.text.trim().isEmpty) return;

              final ok = await _confirmAction(
                title: l10n.translate('accounting.confirm_title'),
                message: l10n.translate(
                  'accounting.confirm_update_tax_payment',
                ),
              );
              if (!ok) return;

              setState(() {
                item.amount = amount;
                item.reference = refController.text.trim();
              });

              if (context.mounted) {
                Navigator.pop(ctx);
                _showSuccess(l10n.translate('accounting.updated_success'));
              }
            },
            child: Text(l10n.translate('common.save')),
          ),
        ],
      ),
    );

    amountController.dispose();
    refController.dispose();
  }

  Future<void> _exportBook(BookItemModel book) async {
    final ok = await _confirmAction(
      title: l10n.translate('accounting.confirm_title'),
      message: l10n.translate('accounting.confirm_export_book'),
    );
    if (!ok) return;
    _showSuccess(l10n.translate('accounting.export_success'));
  }

  Future<void> _generateReport() async {
    final ok = await _confirmAction(
      title: l10n.translate('accounting.confirm_title'),
      message: l10n.translate('accounting.confirm_generate_report'),
    );
    if (!ok) return;

    _showSuccess(l10n.translate('accounting.report_generated_success'));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RevenueBloc, RevenueState>(
      listener: (context, state) {
        if (state is RevenueCreated) {
          _showSuccess(l10n.translate('accounting.revenue_created_success'));
          final locationId = context.read<BusinessContext>().currentBusinessId;
          if (locationId != null) {
            context.read<RevenueBloc>().add(
                  LoadRevenuesRequested(businessLocationId: locationId),
                );
          }
        } else if (state is RevenueError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
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
          onPressed: () => Navigator.pop(context),
          color: AppColors.textPrimary,
        ),
        title: Text(
          l10n.translate('accounting.title'),
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const AppSyncStatusText(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.secondary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.secondary,
              tabs: [
                Tab(text: l10n.translate('accounting.tab_period')),
                Tab(text: l10n.translate('accounting.tab_gl')),
                Tab(text: l10n.translate('accounting.tab_cost_revenue')),
                Tab(text: l10n.translate('accounting.tab_books_reports')),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab Period: real API via BLoC
                  Builder(
                    builder: (context) {
                      final locationId = context
                          .watch<BusinessContext>()
                          .currentBusinessId;
                      if (locationId == null) {
                        return Center(
                          child: Text(
                            l10n.translate(
                              'home.please_select_location',
                            ),
                          ),
                        );
                      }
                      return AccountingPeriodTab(locationId: locationId);
                    },
                  ),
                  const AccountingGlTab(),
                  BlocBuilder<RevenueBloc, RevenueState>(
                    builder: (context, state) {
                      List<RevenueEntity> revenueEntities = [];
                      if (state is RevenuesLoaded) {
                        revenueEntities = state.revenues;
                      }

                      return AccountingCostRevenueTab(
                        revenues: revenueEntities,
                        costs: _costs,
                        onAddRevenue: _showAddRevenueDialog,
                        onAddCost: () {
                          // Placeholder for cost
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add Cost feature coming soon'),
                            ),
                          );
                        },
                        onEditRevenue: (item) {
                          // Handle edit revenue entity
                        },
                        onEditCost: (item) =>
                            _editAccountingItem(item: item, isRevenue: false),
                      );
                    },
                  ),
                  AccountingBooksReportsTab(
                    books: _books,
                    taxPayments: _taxPayments,
                    fromDate: _reportFromDate,
                    toDate: _reportToDate,
                    reportFormat: _reportFormat,
                    onExportBook: _exportBook,
                    onEditTaxPayment: _editTaxPayment,
                    onFromDateChanged: (value) =>
                        setState(() => _reportFromDate = value),
                    onToDateChanged: (value) =>
                        setState(() => _reportToDate = value),
                    onReportFormatChanged: (value) =>
                        setState(() => _reportFormat = value),
                    onGenerateReport: _generateReport,
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

  void _showAddRevenueDialog() {
    final l10n = AppLocalizations.of(context);
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.translate('accounting.add_revenue')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.revenue_amount'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('accounting.revenue_description'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.translate('accounting.revenue_date')),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final amountString = amountController.text.replaceAll(',', '');
                final amount = double.tryParse(amountString) ?? 0;
                if (amount <= 0) return;

                final locationId =
                    context.read<BusinessContext>().currentBusinessId;

                context.read<RevenueBloc>().add(
                  CreateManualRevenueRequested(
                    body: {
                      'amount': amount,
                      'description': descriptionController.text,
                      'recognitionDate': selectedDate.toIso8601String(),
                      'businessLocationId': int.tryParse(locationId ?? ''),
                    },
                  ),
                );
                Navigator.pop(context);
              },
              child: Text(l10n.translate('common.save')),
            ),
          ],
        ),
      ),
    );
  }
}
