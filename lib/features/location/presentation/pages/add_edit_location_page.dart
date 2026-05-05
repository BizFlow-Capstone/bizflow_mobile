import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/context/user_profile_context.dart';
import '../../../../shared/utils/action_guard.dart';

import '../../domain/domain.dart';
import '../../../subscription/data/subscription_repository.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';
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
  final ActionGuard _submitGuard = ActionGuard();
  final ActionGuard _employeeMutationGuard = ActionGuard();
  Completer<void>? _submitCompleter;
  final ScrollController _formScrollController = ScrollController();
  final GlobalKey _nameFieldKey = GlobalKey();
  final GlobalKey _addressFieldKey = GlobalKey();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  String? _nameError;
  String? _addressError;
  bool _showRequiredValidation = false;
  bool _isSubmitting = false;

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
    if (_taxCodeController.text.trim().isNotEmpty) return;

    final profileTaxCode = UserProfileContext().taxCode?.trim();
    if ((profileTaxCode ?? '').isNotEmpty && mounted) {
      setState(() {
        _taxCodeController.text = profileTaxCode!;
      });
      return;
    }

    final savedTaxCode = await SecureStorage().getRegisterTaxCode();
    if (!mounted) return;
    if ((savedTaxCode ?? '').isEmpty) return;

    setState(() {
      _taxCodeController.text = savedTaxCode!.trim();
    });
  }

  void _completeSubmitGuard() {
    final completer = _submitCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _submitCompleter = null;
    if (_isSubmitting && mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _runEmployeeMutation(Future<void> Function() action) async {
    if (_employeeMutationGuard.isRunning) return;
    if (mounted) setState(() {});
    await _employeeMutationGuard.run(action);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _completeSubmitGuard();
    _tabController.dispose();
    _formScrollController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _managerNameController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _addressFocusNode.dispose();
    _taxCodeController.dispose();
    super.dispose();
  }

  String _requiredLabel(String label) => '$label *';

  String? _requiredFieldError(String value) {
    if (value.trim().isEmpty) {
      return AppLocalizations.of(context).translate('common.required_field');
    }
    return null;
  }

  bool _validateRequiredFields({required bool shouldFocus}) {
    final nameError = _requiredFieldError(_nameController.text);
    final addressError = _requiredFieldError(_addressController.text);

    setState(() {
      _showRequiredValidation = true;
      _nameError = nameError;
      _addressError = addressError;
    });

    if (nameError == null && addressError == null) {
      return true;
    }

    if (shouldFocus) {
      _scrollToFirstInvalidField(
        nameError: nameError,
        addressError: addressError,
      );
    }
    return false;
  }

  void _scrollToField(GlobalKey key) {
    final contextForKey = key.currentContext;
    if (contextForKey == null) return;
    Scrollable.ensureVisible(
      contextForKey,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: 0.1,
    );
  }

  void _scrollToFirstInvalidField({
    required String? nameError,
    required String? addressError,
  }) {
    if (nameError != null) {
      _scrollToField(_nameFieldKey);
      _nameFocusNode.requestFocus();
      return;
    }
    if (addressError != null) {
      _scrollToField(_addressFieldKey);
      _addressFocusNode.requestFocus();
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) {
      return;
    }

    if (!_validateRequiredFields(shouldFocus: true)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    var hasDispatchedSubmitEvent = false;

    await _submitGuard.run(() async {
      if (widget.location == null) {
        final allowed = await SubscriptionFeatureGuard.ensureAllowed(
          context,
          featureCode: SubscriptionFeatureCodes.locations,
        );
        if (!allowed || !mounted) return;
      }

      final completer = Completer<void>();
      _submitCompleter = completer;
      hasDispatchedSubmitEvent = true;

      if (widget.location != null) {
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

      await completer.future;
    });

    if (!hasDispatchedSubmitEvent && mounted) {
      setState(() {
        _isSubmitting = false;
      });
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
        listener: (context, state) async {
          if (state is LocationAddSuccess) {
            _completeSubmitGuard();
            await BusinessContext().switchBusinessLocation(
              state.newLocation.id,
              state.newLocation.name,
              isOwner: true, // Creating a location → always owner
            );
            if (!mounted) {
              return;
            }
            AppRouter.navigateAndClearStack(AppRoutes.home);
          } else if (state is LocationEditSuccess) {
            _completeSubmitGuard();
            final businessContext = Provider.of<BusinessContext>(
              context,
              listen: false,
            );
            final navigator = Navigator.of(context);
            if (businessContext.currentBusinessId == state.updatedLocation.id) {
              await businessContext.switchBusinessLocation(
                state.updatedLocation.id,
                state.updatedLocation.name,
                isOwner:
                    true, // Editing a location → must be owner to have reached this screen
              );
            }
            if (!mounted) return;
            navigator.pop();
          } else if (state is AddEmployeeToLocationSuccess) {
            AppSnackBar.show(
              context,
              message: l10n.translate('location.employee_add_success'),
              type: AppSnackBarType.success,
            );
          } else if (state is LocationFailure) {
            _completeSubmitGuard();
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
        controller: _formScrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Name
            Text(
              _requiredLabel(l10n.translate('location.location_name')),
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Container(
              key: _nameFieldKey,
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                onChanged: (_) {
                  if (_showRequiredValidation) {
                    setState(() {
                      _nameError = _requiredFieldError(_nameController.text);
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: l10n.translate('location.location_name_hint'),
                  errorText: _showRequiredValidation ? _nameError : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Address
            Text(
              _requiredLabel(l10n.translate('location.location_address')),
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Container(
              key: _addressFieldKey,
              child: TextField(
                controller: _addressController,
                focusNode: _addressFocusNode,
                onChanged: (_) {
                  if (_showRequiredValidation) {
                    setState(() {
                      _addressError = _requiredFieldError(
                        _addressController.text,
                      );
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: l10n.translate('location.location_address_hint'),
                  errorText: _showRequiredValidation ? _addressError : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                maxLines: 3,
              ),
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
                    _isSubmitting ||
                    state is LocationAddInProgress ||
                    state is LocationEditInProgress;

                if (isEditMode) {
                  return AppButton(
                    label: l10n.translate('location.update_button'),
                    isFullWidth: true,
                    isLoading: isLoading,
                    isDisabled: _submitGuard.isRunning,
                    onPressed: (isLoading || _submitGuard.isRunning)
                        ? null
                        : _handleSubmit,
                    type: AppButtonType.secondary,
                    size: AppButtonSize.large,
                  );
                }

                return AppButton(
                  label: l10n.translate('location.create_button'),
                  isFullWidth: true,
                  isLoading: isLoading,
                  isDisabled: _submitGuard.isRunning,
                  onPressed: (isLoading || _submitGuard.isRunning)
                      ? null
                      : _handleSubmit,
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
                      onPressed: _employeeMutationGuard.isRunning
                          ? null
                          : () async {
                              await _runEmployeeMutation(() async {
                                final confirmed = await AppDialog.delete(
                                  context,
                                  title: l10n.translate(
                                    'product.confirm_delete_title',
                                  ),
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
                              });
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
                      onPressed: _employeeMutationGuard.isRunning
                          ? null
                          : () async {
                              await _runEmployeeMutation(() async {
                                context.read<LocationBloc>().add(
                                  AddEmployeeToLocationFromTabRequested(
                                    locationId: widget.location!.id,
                                    employeeId: employee.id,
                                  ),
                                );
                              });
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
