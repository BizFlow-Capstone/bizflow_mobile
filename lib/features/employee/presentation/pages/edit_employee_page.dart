import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_event.dart';
import '../../../location/presentation/bloc/location_state.dart';
import '../../domain/entities/employee_entity.dart';
import '../bloc/employee_bloc.dart';
import '../bloc/employee_event.dart';
import '../bloc/employee_state.dart';

enum EmployeeEditMode { detail, assign, unassign }

class EditEmployeePage extends StatefulWidget {
  final String employeeId;
  final EmployeeEditMode mode;

  const EditEmployeePage({
    super.key,
    required this.employeeId,
    this.mode = EmployeeEditMode.assign,
  });

  @override
  State<EditEmployeePage> createState() => _EditEmployeePageState();
}

class _EditEmployeePageState extends State<EditEmployeePage> {
  EmployeeEntity? _employee;
  List<String> _selectedLocationIds = [];
  Set<String> _originalLocationIds = const <String>{};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.mode != EmployeeEditMode.detail) {
      final locationState = context.read<LocationBloc>().state;
      if (locationState is! LocationsLoaded && locationState is! LocationLoading) {
        context.read<LocationBloc>().add(const LoadLocationsRequested());
      }
    }

    final employeeState = context.read<EmployeeBloc>().state;
    if (employeeState is EmployeeLoaded) {
      try {
        _employee = employeeState.allEmployees.firstWhere((e) => e.id == widget.employeeId);
        _selectedLocationIds = List.from(_employee!.assignedLocationIds);
        _originalLocationIds = _employee!.assignedLocationIds.toSet();
      } catch (_) {}
    }
  }

  void _onSave() {
    if (_employee == null || widget.mode == EmployeeEditMode.detail) return;

    final updatedEmployee = _employee!.copyWith(
      assignedLocationIds: _selectedLocationIds,
    );

    context.read<EmployeeBloc>().add(UpdateEmployeeRequested(updatedEmployee));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pageTitle = _getPageTitle(t);

    if (_employee == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(pageTitle),
          centerTitle: true,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          iconTheme: const IconThemeData(color: Colors.black),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        body: Center(child: Text(t.translate('employee.not_found'))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(pageTitle),
        centerTitle: true,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        iconTheme: const IconThemeData(color: Colors.black),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: BlocListener<EmployeeBloc, EmployeeState>(
          listener: (context, state) {
            if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
              return;
            }

            if (state is EmployeeActionInProgress) {
              setState(() => _isLoading = true);
            } else {
              setState(() => _isLoading = false);

              if (state is EmployeeActionSuccess) {
                _employee = _employee!.copyWith(
                  assignedLocationIds: List.from(_selectedLocationIds),
                );
                Navigator.pop(context);
              } else if (state is EmployeeFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
                );
              }
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translate('employee.personal_info'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildReadOnlyField(
                  t.translate('employee.name_label'),
                  _employee!.name,
                  Icons.person_outline,
                  theme,
                ),
                const SizedBox(height: 12),
                if (_employee!.email.isNotEmpty) ...[
                  _buildReadOnlyField(
                    t.translate('employee.email_label'),
                    _employee!.email,
                    Icons.email_outlined,
                    theme,
                  ),
                  const SizedBox(height: 12),
                ],
                _buildReadOnlyField(
                  t.translate('employee.phone_label'),
                  _employee!.phone,
                  Icons.phone_outlined,
                  theme,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      t.translate('employee.cannot_edit_info'),
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  t.translate('employee.assigned_warehouses'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildAssignmentSection(theme, t),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.mode == EmployeeEditMode.detail
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
                child: AppButton(
                  onPressed: _isLoading ? null : _onSave,
                  label: _getSaveButtonTitle(t),
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
              ),
            ),
    );
  }

  String _getPageTitle(AppLocalizations t) {
    switch (widget.mode) {
      case EmployeeEditMode.detail:
        return t.translate('employee.view_employee_detail');
      case EmployeeEditMode.assign:
        return t.translate('employee.assign_employee');
      case EmployeeEditMode.unassign:
        return t.translate('employee.unassign_employee');
    }
  }

  String _getSaveButtonTitle(AppLocalizations t) {
    switch (widget.mode) {
      case EmployeeEditMode.detail:
        return '';
      case EmployeeEditMode.assign:
        return t.translate('employee.assign_employee');
      case EmployeeEditMode.unassign:
        return t.translate('employee.unassign_employee');
    }
  }

  Widget _buildAssignmentSection(ThemeData theme, AppLocalizations t) {
    if (widget.mode == EmployeeEditMode.detail) {
      final assignedNames = _employee!.assignedLocationNames;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          assignedNames.isEmpty
              ? t.translate('employee.assignment_unassigned')
              : assignedNames.join(', '),
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          if (state is! LocationsLoaded) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final isAssignMode = widget.mode == EmployeeEditMode.assign;
          final candidateLocations = state.locations.where((location) {
            if (isAssignMode) {
              return !_originalLocationIds.contains(location.id);
            }
            return _originalLocationIds.contains(location.id);
          }).toList();

          if (candidateLocations.isEmpty) {
            final emptyText = isAssignMode
                ? t.translate('employee.no_location_available_for_assign')
                : t.translate('employee.no_location_available_for_unassign');
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                emptyText,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: candidateLocations.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, index) {
              final location = candidateLocations[index];
              final isSelected = _selectedLocationIds.contains(location.id);

              return CheckboxListTile(
                title: Text(
                  location.name,
                  style: theme.textTheme.bodyLarge,
                ),
                value: isSelected,
                activeColor: AppColors.primary,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedLocationIds.add(location.id);
                    } else {
                      _selectedLocationIds.remove(location.id);
                    }
                  });
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}
