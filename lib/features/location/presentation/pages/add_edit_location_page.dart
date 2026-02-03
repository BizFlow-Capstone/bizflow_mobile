import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../employee/domain/entities/employee_entity.dart';
import '../../domain/domain.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';

/// Add/Edit Location Page
/// SC-LOC-03: Thêm/Sửa địa điểm kinh doanh
class AddEditLocationPage extends StatefulWidget {
  final LocationEntity? location;

  const AddEditLocationPage({super.key, this.location});

  @override
  State<AddEditLocationPage> createState() => _AddEditLocationPageState();
}

class _AddEditLocationPageState extends State<AddEditLocationPage> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _managerNameController;
  late TextEditingController _districtController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;
  late TextEditingController _taxCodeController;
  String? _selectedManagerId;
  List<EmployeeEntity> _availableEmployees = [];
  final List<String> _selectedEmployeeIds = [];
  bool _isLoadingEmployees = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location?.name ?? '');
    _addressController = TextEditingController(
      text: widget.location?.address ?? '',
    );
    _managerNameController = TextEditingController(
      text: widget.location?.ownerName ?? '',
    );
    _districtController = TextEditingController(
      text: widget.location?.district ?? '',
    );
    _cityController = TextEditingController(
      text: widget.location?.city ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.location?.phone ?? '',
    );
    _taxCodeController = TextEditingController(
      text: widget.location?.taxCode ?? '',
    );
    _selectedManagerId = widget.location?.id;
    
    // Pre-populate selected employee IDs when editing
    if (widget.location != null) {
      _selectedEmployeeIds.addAll(widget.location!.employeeIds);
    }
    
    _loadEmployees();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _managerNameController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _taxCodeController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
      final l10n = AppLocalizations.of(context);
      AppSnackBar.show(
        context,
        message: l10n.translate('location.validation_error'),
        type: AppSnackBarType.warning,
      );
      return;
    }

    // Send all selected employees (BLoC will filter out already-assigned ones during edit)
    final employeeIds = List<String>.from(_selectedEmployeeIds);

    if (widget.location != null) {
      // Edit location
      context.read<LocationBloc>().add(
        EditLocationRequested(
          locationId: widget.location!.id,
          name: _nameController.text,
          address: _addressController.text,
          district: _districtController.text,
          city: _cityController.text,
          phone: _phoneController.text,
          taxCode: _taxCodeController.text,
          managerId: _selectedManagerId ?? '',
          managerName: _managerNameController.text,
          employeeIds: employeeIds,
        ),
      );
    } else {
      // Add new location
      context.read<LocationBloc>().add(
        AddLocationRequested(
          name: _nameController.text,
          address: _addressController.text,
          district: _districtController.text,
          city: _cityController.text,
          phone: _phoneController.text,
          taxCode: _taxCodeController.text,
          managerId: _selectedManagerId ?? '',
          managerName: _managerNameController.text,
          employeeIds: employeeIds,
        ),
      );
    }
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoadingEmployees = true;
    });

    try {
      final employees = await context
          .read<LocationBloc>()
          .fetchAvailableEmployees();
      if (!mounted) return;
      setState(() {
        _availableEmployees = employees;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: e.toString(),
          type: AppSnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEmployees = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditMode = widget.location != null;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.black,
        ),
        title: Text(
          isEditMode
              ? l10n.translate('location.edit_location_title')
              : l10n.translate('location.create_location_title'),
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is LocationAddSuccess || state is LocationEditSuccess) {
            Navigator.pop(context);
          } else if (state is LocationFailure) {
            AppSnackBar.show(
              context,
              message: state.message,
              type: AppSnackBarType.error,
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Name
                Text(
                  l10n.translate('location.location_name'),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: l10n.translate('location.location_name_hint'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Address
                Text(
                  l10n.translate('location.location_address'),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: l10n.translate('location.location_address_hint'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: AppSpacing.lg),

                // District
                Text(
                  l10n.translate('location.location_district'),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _districtController,
                  decoration: InputDecoration(
                    hintText: l10n.translate('location.location_district_hint'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // City
                Text(
                  l10n.translate('location.location_city'),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    hintText: l10n.translate('location.location_city_hint'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Phone
                Text(
                  l10n.translate('location.location_phone'),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: l10n.translate('location.location_phone_hint'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Tax Code
                Text(
                  l10n.translate('location.location_tax_code'),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _taxCodeController,
                  decoration: InputDecoration(
                    hintText: l10n.translate('location.location_tax_code_hint'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Owner (only show in edit mode)
                if (isEditMode) ...[
                  Text(
                    l10n.translate('location.location_owner'),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _managerNameController,
                    decoration: InputDecoration(
                      hintText: l10n.translate('location.location_owner_hint'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                    ),
                    readOnly: true,
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],

                // Employees Section
                Text(
                  l10n.translate('location.employee_section_title'),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                if (_isLoadingEmployees)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: const CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (_availableEmployees.isEmpty)
                  Text(
                    l10n.translate('location.employee_no_results'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: l10n.translate(
                            'location.employee_dropdown_hint',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                        ),
                        items: _availableEmployees
                            .map(
                              (employee) => DropdownMenuItem<String>(
                                value: employee.id,
                                child: Text(employee.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            if (!_selectedEmployeeIds.contains(value)) {
                              _selectedEmployeeIds.add(value);
                            }
                          });
                        },
                      ),
                      if (_selectedEmployeeIds.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: _selectedEmployeeIds.map((id) {
                            final employee = _availableEmployees.firstWhere(
                              (item) => item.id == id,
                              orElse: () => EmployeeEntity(id: id, name: id),
                            );
                            return InputChip(
                              label: Text(employee.name),
                              onDeleted: () {
                                setState(() {
                                  _selectedEmployeeIds.remove(id);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                SizedBox(height: AppSpacing.xl),

                // Submit Button
                BlocBuilder<LocationBloc, LocationState>(
                  builder: (context, state) {
                    final isLoading =
                        state is LocationAddInProgress ||
                        state is LocationEditInProgress;

                    return AppButton(
                      label: isEditMode
                          ? l10n.translate('location.update_button')
                          : l10n.translate('location.create_button'),
                      isFullWidth: true,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _handleSubmit,
                      type: AppButtonType.secondary,
                      size: AppButtonSize.large,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
