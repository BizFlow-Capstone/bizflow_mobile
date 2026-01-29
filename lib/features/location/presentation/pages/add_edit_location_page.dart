import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/domain.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';

/// Add/Edit Location Page
/// SC-LOC-03: Thêm/Sửa địa điểm kinh doanh
class AddEditLocationPage extends StatefulWidget {
  final LocationEntity? location;

  const AddEditLocationPage({
    super.key,
    this.location,
  });

  @override
  State<AddEditLocationPage> createState() => _AddEditLocationPageState();
}

class _AddEditLocationPageState extends State<AddEditLocationPage> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _managerNameController;
  String? _selectedManagerId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location?.name ?? '');
    _addressController = TextEditingController(text: widget.location?.address ?? '');
    _managerNameController = TextEditingController(text: widget.location?.managerName ?? '');
    _selectedManagerId = widget.location?.managerId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _managerNameController.dispose();
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
      // Edit location
      context.read<LocationBloc>().add(
        EditLocationRequested(
          locationId: widget.location!.id,
          name: _nameController.text,
          address: _addressController.text,
          managerId: _selectedManagerId ?? '',
          managerName: _managerNameController.text,
        ),
      );
    } else {
      // Add new location
      context.read<LocationBloc>().add(
        AddLocationRequested(
          name: _nameController.text,
          address: _addressController.text,
          managerId: _selectedManagerId ?? '',
          managerName: _managerNameController.text,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary,),
          onPressed: () => Navigator.pop(context),
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

                // Manager
                Text(
                  l10n.translate('location.location_manager'),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _managerNameController,
                  decoration: InputDecoration(
                    hintText: l10n.translate('location.location_manager_hint'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),

                // Submit Button
                BlocBuilder<LocationBloc, LocationState>(
                  builder: (context, state) {
                    final isLoading = state is LocationAddInProgress ||
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
