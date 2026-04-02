import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/context/business_context.dart';

import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/dialogs/app_snackbar.dart';

import '../../domain/entities/employee_entity.dart';
import '../bloc/employee_bloc.dart';
import '../bloc/employee_event.dart';
import '../bloc/employee_state.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';

class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final TextEditingController _searchController = TextEditingController();

  final List<EmployeeEntity> _selectedEmployees = [];
  List<EmployeeEntity> _searchResults = const [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();
    if (_selectedEmployees.isEmpty) {
      AppSnackBar.error(context, 'Vui lòng tìm và chọn ít nhất một nhân viên để gửi lời mời.');
      return;
    }

    final allowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.employees,
    );
    if (!allowed) return;

    final businessId = Provider.of<BusinessContext>(context, listen: false).currentBusinessId ?? '';
    final employeeIds = _selectedEmployees.map((e) => e.id).toList();
    context.read<EmployeeBloc>().add(AddMultipleEmployeesRequested(businessId: businessId, employeeIds: employeeIds));
  }

  void _selectSearchResult(EmployeeEntity employee) {
    if (employee.status == EmployeeStatus.active) {
      AppSnackBar.warning(context, 'Người này đã là nhân viên.');
      return;
    }

    if (_selectedEmployees.any((e) => e.id == employee.id)) {
      AppSnackBar.warning(context, 'Đã chọn người này rồi.');
      return;
    }

    setState(() {
      _selectedEmployees.add(employee);
      _searchController.text = '';
      _searchResults = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.translate('employee.add_employee')), 
        centerTitle: true, 
        backgroundColor: AppColors.white, 
        foregroundColor: AppColors.textPrimary,
        iconTheme: const IconThemeData(color: Colors.black),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: BlocListener<EmployeeBloc, EmployeeState>(
          listener: (context, state) {
            if (state is EmployeeActionInProgress) {
              setState(() => _isLoading = true);
            } else {
              setState(() => _isLoading = false);
              
              if (state is EmployeeActionSuccess) {
                AppSnackBar.success(context, 'Gửi lời mời thành công');
                Navigator.pop(context);
              } else if (state is EmployeeSearchLoaded) {
                setState(() {
                  _searchResults = state.results;
                });
              } else if (state is EmployeeFailure) {
                final isAlreadyInvited = state.message.contains('đã được mời') || state.message.contains('409');
                AppSnackBar.show(
                  context,
                  message: state.message,
                  type: isAlreadyInvited ? AppSnackBarType.warning : AppSnackBarType.error,
                );
              }
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Section
                Text(
                  t.translate('employee.personal_info'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Search Input
                AppTextField(
                  controller: _searchController,
                  hintText: t.translate('employee.email_or_phone_hint'),
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (value) {
                    context.read<EmployeeBloc>().add(SearchEmployeesRequested(value));
                  },
                ),
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(item.phone.isNotEmpty ? item.phone : item.email),
                          onTap: () => _selectSearchResult(item),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Hiển thị danh sách nhân viên đã chọn
                if (_selectedEmployees.isNotEmpty) ...[
                  Text(
                    'Đã chọn (${_selectedEmployees.length})',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedEmployees.length,
                    itemBuilder: (context, index) {
                      final emp = _selectedEmployees[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            emp.name, 
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                          ),
                          subtitle: Text(
                            emp.phone.isNotEmpty ? emp.phone : emp.email,
                            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: AppColors.error),
                            onPressed: () {
                              setState(() {
                                _selectedEmployees.removeWhere((e) => e.id == emp.id);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
          child: AppButton(
            onPressed: _isLoading ? null : _onSave,
            label: t.translate('common.confirm'),
            isLoading: _isLoading,
            isFullWidth: true,
          ),
        ),
      ),
    );
  }
}
