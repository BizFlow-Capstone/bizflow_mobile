import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/context/business_context.dart';

import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/routing/app_router.dart';
import '../bloc/employee_bloc.dart';
import '../bloc/employee_event.dart';
import '../bloc/employee_state.dart';
import '../widgets/employee_card_widget.dart';
import '../widgets/employee_action_sheet.dart';
import '../widgets/delete_employee_dialog.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Initial load based on business context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessId = Provider.of<BusinessContext>(context, listen: false).currentBusinessId;
      if (businessId != null) {
        context.read<EmployeeBloc>().add(LoadEmployeesRequested(businessId: businessId));
      }
    });

    // Listen to context changes
    Provider.of<BusinessContext>(context, listen: false).addListener(_onBusinessContextChanged);
  }

  void _onBusinessContextChanged() {
    final businessId = Provider.of<BusinessContext>(context, listen: false).currentBusinessId;
    if (businessId != null) {
      context.read<EmployeeBloc>().add(LoadEmployeesRequested(businessId: businessId));
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      context.read<EmployeeBloc>().add(SelectEmployeeTabRequested(_tabController.index));
    }
  }

  void _showActionSheet(BuildContext context, String employeeId, String employeeName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return EmployeeActionSheet(
          onEdit: () {
            // Navigate to edit page
            Navigator.pushNamed(
              context, 
              AppRoutes.editEmployee, 
              arguments: {'employeeId': employeeId},
            );
          },
          onDelete: () async {
            // Show confirmation dialog
            final confirm = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => DeleteEmployeeDialog(employeeName: employeeName),
            );

            if (confirm == true && context.mounted) {
              context.read<EmployeeBloc>().add(DeleteEmployeeRequested(employeeId));
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    Provider.of<BusinessContext>(context, listen: false).removeListener(_onBusinessContextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.translate('employee.title')), 
        centerTitle: true, 
        backgroundColor: AppColors.white, 
        foregroundColor: AppColors.textPrimary,
        iconTheme: const IconThemeData(color: Colors.black),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: BlocConsumer<EmployeeBloc, EmployeeState>(
          listener: (context, state) {
            if (state is EmployeeFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
              );
            } else if (state is EmployeeActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
              );
            }
          },
          builder: (context, state) {
            if (state is EmployeeLoading || state is EmployeeInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is EmployeeLoaded) {
              return Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AppTextField(
                      controller: _searchController,
                      hintText: t.translate('employee.search_hint'),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),

                  // Tabs
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(text: t.translate('employee.tab_all')),
                        Tab(text: t.translate('employee.tab_active')),
                        Tab(text: t.translate('employee.tab_pending')),
                      ],
                    ),
                  ),

                  // Summary Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    color: AppColors.background,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem(
                          t.translate('employee.total_count'), 
                          state.totalCount.toString(), 
                          theme
                        ),
                        _buildSummaryItem(
                          t.translate('employee.active_count'), 
                          state.activeCount.toString(), 
                          theme, 
                          color: AppColors.success
                        ),
                        _buildSummaryItem(
                          t.translate('employee.pending_count'), 
                          state.pendingCount.toString(), 
                          theme, 
                          color: Colors.orange
                        ),
                      ],
                    ),
                  ),

                  // List
                  Expanded(
                    child: state.filteredEmployees.isEmpty
                        ? Center(
                            child: Text(
                              t.translate('common.no_data'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                              bottom: 120.0, // Added bottom padding for FAB
                            ),
                            itemCount: state.filteredEmployees.length,
                            itemBuilder: (context, index) {
                              final employee = state.filteredEmployees[index];
                              return EmployeeCardWidget(
                                employee: employee,
                                onActionTap: () => _showActionSheet(context, employee.id, employee.name),
                              );
                            },
                          ),
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
      floatingActionButton: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.addEmployee);
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, ThemeData theme, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
