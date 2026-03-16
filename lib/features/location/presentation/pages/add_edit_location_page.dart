import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/context/business_context.dart';

import '../../domain/domain.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';
import '../../../../shared/dialogs/app_dialog.dart';

/// Add/Edit Location Page
/// SC-LOC-03: Thêm/Sửa địa điểm kinh doanh
/// Now with TabBar: Tab 1 = Location Info, Tab 2 = Employee Management
class AddEditLocationPage extends StatefulWidget {
  final LocationEntity? location;

  const AddEditLocationPage({super.key, this.location});

  @override
  State<AddEditLocationPage> createState() => _AddEditLocationPageState();
}

class _AddEditLocationPageState extends State<AddEditLocationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _managerNameController;
  late TextEditingController _districtController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;
  late TextEditingController _taxCodeController;
  String? _selectedManagerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    _cityController = TextEditingController(text: widget.location?.city ?? '');
    _phoneController = TextEditingController(
      text: widget.location?.phone ?? '',
    );
    _taxCodeController = TextEditingController(
      text: widget.location?.taxCode ?? '',
    );
    _selectedManagerId = widget.location?.id;

    if (widget.location == null) {
      _prefillTaxCodeFromRegister();
    }

    // Load location employees for employee tab (edit mode only)
    if (widget.location != null) {
      context.read<LocationBloc>().add(
        LoadLocationEmployeesRequested(
          locationId: widget.location!.id,
          currentEmployeeIds: widget.location!.employeeIds,
        ),
      );
    }
  }

  Future<void> _prefillTaxCodeFromRegister() async {
    final savedTaxCode = await SecureStorage().getRegisterTaxCode();
    if (!mounted) return;
    if ((savedTaxCode ?? '').isEmpty) return;
    if (_taxCodeController.text.trim().isEmpty) {
      setState(() {
        _taxCodeController.text = savedTaxCode!.trim();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    if (widget.location != null) {
      // Edit location - employee mgmt via Tab 2
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
          employeeIds: widget.location!.employeeIds,
        ),
      );
    } else {
      // Add new location - no employees (assign via Tab 2 after creation)
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
          employeeIds: [],
        ),
      );
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
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: AppTextStyles.labelLarge,
          tabs: [
            Tab(text: l10n.translate('location.tab_info')),
            Tab(text: l10n.translate('location.tab_employees')),
          ],
        ),
      ),
      body: BlocListener<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is LocationAddSuccess) {
            BusinessContext()
                .switchBusinessLocation(
                  state.newLocation.id,
                  state.newLocation.name,
                )
                .then((_) {
                  if (!mounted) {
                    return;
                  }
                  AppRouter.navigateAndClearStack(AppRoutes.home);
                });
          } else if (state is LocationEditSuccess) {
            Navigator.pop(context);
          } else if (state is AddEmployeeToLocationSuccess) {
            AppSnackBar.show(
              context,
              message: l10n.translate('location.employee_add_success'),
              type: AppSnackBarType.success,
            );
          } else if (state is LocationFailure) {
            AppSnackBar.show(
              context,
              message: state.message,
              type: AppSnackBarType.error,
            );
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLocationForm(l10n, isEditMode),
            _buildEmployeeTab(l10n, isEditMode),
          ],
        ),
      ),
    );
  }

  /// Tab 1: Location information form
  Widget _buildLocationForm(AppLocalizations l10n, bool isEditMode) {
    return SafeArea(
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: AppSpacing.lg),
            ],

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
            const SafeArea(top: false, child: SizedBox(height: AppSpacing.md)),
          ],
        ),
      ),
    );
  }

  /// Tab 2: Employee management tab
  Widget _buildEmployeeTab(AppLocalizations l10n, bool isEditMode) {
    if (!isEditMode) {
      // For new locations, show info message
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                l10n.translate('location.employee_create_first'),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        if (state is LocationLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is LocationEmployeesLoaded) {
          return _buildEmployeeContent(l10n, state);
        }

        // Default: show loading or trigger load
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
    );
  }

  Widget _buildEmployeeContent(
    AppLocalizations l10n,
    LocationEmployeesLoaded state,
  ) {
    final assignedEmployees = state.locationEmployees;
    final unassignedEmployees = state.unassignedEmployees;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assigned employees section
            Text(
              l10n.translate('location.employee_assigned'),
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.sm),

            if (assignedEmployees.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  l10n.translate('location.employee_no_results'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: assignedEmployees.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final employee = assignedEmployees[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        employee.name.isNotEmpty
                            ? employee.name[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      employee.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: employee.phone.isNotEmpty
                        ? Text(
                            '${l10n.translate('location.employee_phone')}: ${employee.phone}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red,
                      onPressed: () async {
                        final confirmed = await AppDialog.delete(
                          context,
                          title: l10n.translate('product.confirm_delete_title'),
                          message: l10n.translate(
                            'product.confirm_delete_message',
                          ),
                          confirmText: l10n.translate('common.delete'),
                        );

                        if (!context.mounted || confirmed != true) {
                          return;
                        }

                        context.read<LocationBloc>().add(
                          RemoveEmployeeFromLocationRequested(
                            locationId: widget.location!.id,
                            employeeId: employee.id,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

            SizedBox(height: AppSpacing.xl),

            // Add employee section
            Text(
              l10n.translate('location.employee_add'),
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.sm),

            if (unassignedEmployees.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  l10n.translate('location.employee_all_assigned'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: unassignedEmployees.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final employee = unassignedEmployees[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.textSecondary.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        employee.name.isNotEmpty
                            ? employee.name[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    title: Text(employee.name, style: AppTextStyles.bodyLarge),
                    subtitle: employee.phone.isNotEmpty
                        ? Text(
                            '${l10n.translate('location.employee_phone')}: ${employee.phone}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                      onPressed: () {
                        context.read<LocationBloc>().add(
                          AddEmployeeToLocationFromTabRequested(
                            locationId: widget.location!.id,
                            employeeId: employee.id,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

            SizedBox(height: AppSpacing.xl),

            // Update employees button
            BlocListener<LocationBloc, LocationState>(
              listener: (context, state) {
                if (state is SaveLocationEmployeesSuccess) {
                  AppSnackBar.success(
                    context,
                    l10n.translate('location.employee_update_success'),
                  );
                } else if (state is RemoveEmployeeFromLocationSuccess) {
                  AppSnackBar.success(
                    context,
                    l10n.translate('location.employee_remove_success'),
                  );
                } else if (state is LocationFailure) {
                  AppSnackBar.error(context, state.message);
                }
              },
              child: BlocBuilder<LocationBloc, LocationState>(
                builder: (context, btnState) {
                  final isLoading = btnState is LocationLoading;
                  return AppButton(
                    label: l10n.translate('location.employee_update_button'),
                    isFullWidth: true,
                    isLoading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () {
                            context.read<LocationBloc>().add(
                              SaveLocationEmployeesRequested(
                                locationId: widget.location!.id,
                              ),
                            );
                          },
                    type: AppButtonType.secondary,
                    size: AppButtonSize.large,
                  );
                },
              ),
            ),
            const SafeArea(top: false, child: SizedBox(height: AppSpacing.md)),
          ],
        ),
      ),
    );
  }
}
