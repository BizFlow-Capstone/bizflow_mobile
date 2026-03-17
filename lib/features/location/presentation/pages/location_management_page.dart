import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/sidebar_widget.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';
import '../widgets/location_card.dart';
import 'add_edit_location_page.dart';
import '../../../../shared/dialogs/app_dialog.dart';
import '../../../product/presentation/pages/product_management_page.dart';
import '../../domain/entities/location_entity.dart';

/// Location Management Page
/// SC-LOC-01: Quản lý địa điểm kinh doanh
class LocationManagementPage extends StatefulWidget {
  final Function(Locale)? onLocaleChange;

  const LocationManagementPage({super.key, this.onLocaleChange});

  @override
  State<LocationManagementPage> createState() => _LocationManagementPageState();
}

class _LocationManagementPageState extends State<LocationManagementPage> {
  LocationItem? _selectedLocation;

  @override
  void initState() {
    super.initState();
    context.read<LocationBloc>().add(const LoadLocationsRequested());
  }

  void _handleLocationToggleStatus(String locationId, bool isActive) {
    if (!mounted) return;
    context.read<LocationBloc>().add(
      ToggleLocationStatusRequested(locationId: locationId, isActive: isActive),
    );
  }

  void _handleLocationEdit(LocationEntity location) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditLocationPage(location: location),
      ),
    ).then((_) {
      if (mounted) {
        context.read<LocationBloc>().add(const RestoreLocationsRequested());
      }
    });
  }

  void _handleLocationDelete(LocationEntity location) async {
    final confirmed = await AppDialog.delete(
      context,
      title: l10n.translate('product.confirm_delete_title'), // Reusing product confirm delete for now
      message: l10n.translate('product.confirm_delete_message'),
      confirmText: l10n.translate('common.delete'),
    );

    if (confirmed == true && mounted) {
      context.read<LocationBloc>().add(
        DeleteLocationRequested(locationId: location.id),
      );
    }
  }

  late AppLocalizations l10n;
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);

    // Return a wrapper widget that contains both body and drawer
    // _GlobalAppBarShell will wrap this with Scaffold
    return WillPopScope(
      onWillPop: () async {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
          return false;
        }

        AppRouter.replaceTo(AppRoutes.home);
        return false;
      },
      child: _LocationPageContent(
        l10n: l10n,
        selectedLocation: _selectedLocation,
        onLocationSelected: (location) {
          setState(() {
            _selectedLocation = location;
          });
        },
        onToggleStatus: _handleLocationToggleStatus,
        onEdit: _handleLocationEdit,
        onDelete: _handleLocationDelete,
      ),
    );
  }
}

/// Wrapper widget that provides body content
/// Drawer will be managed by _GlobalAppBarShell
class _LocationPageContent extends StatelessWidget {
  final AppLocalizations l10n;
  final LocationItem? selectedLocation;
  final Function(LocationItem) onLocationSelected;
  final Function(String, bool) onToggleStatus;
  final Function(LocationEntity) onEdit;
  final Function(LocationEntity) onDelete;

  const _LocationPageContent({
    required this.l10n,
    required this.selectedLocation,
    required this.onLocationSelected,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationBloc, LocationState>(
      listener: (context, state) {
        if (state is LocationToggleSuccess) {
          AppSnackBar.show(
            context,
            message: l10n.translate('location.status_updated'),
            type: AppSnackBarType.success,
          );
        } else if (state is LocationAddSuccess) {
          AppSnackBar.show(
            context,
            message: l10n.translate('location.location_added'),
            type: AppSnackBarType.success,
          );
        } else if (state is LocationEditSuccess) {
          AppSnackBar.show(
            context,
            message: l10n.translate('location.location_updated'),
            type: AppSnackBarType.success,
          );
        } else if (state is LocationDeleteSuccess) {
          AppSnackBar.show(
            context,
            message: l10n.translate('location.location_deleted'),
            type: AppSnackBarType.success,
          );
        } else if (state is LocationFailure || state is LocationError) {
          final message = state is LocationFailure
              ? state.message
              : (state as LocationError).message;
          AppSnackBar.show(
            context,
            message: message,
            type: AppSnackBarType.error,
          );
        }
      },
      child: SafeArea(
        child: BlocBuilder<LocationBloc, LocationState>(
          buildWhen: (previous, current) {
            // Only rebuild for states relevant to the location list page
            // Ignore employee tab states (LocationEmployeesLoaded, AddEmployeeToLocationSuccess, etc.)
            return current is LocationsLoaded ||
                current is LocationLoading ||
                current is LocationFailure ||
                current is LocationError ||
                current is LocationInitial;
          },
          builder: (context, state) {
            // Loading state
            if (state is LocationLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF23C4C1)),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.translate('location.loading_locations'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Error state
            if (state is LocationFailure || state is LocationError) {
              final message = state is LocationFailure
                  ? state.message
                  : (state as LocationError).message;

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Text(
                        l10n.translate('common.error_occurred'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<LocationBloc>().add(
                          const LoadLocationsRequested(),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.translate('common.retry')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is LocationsLoaded) {
              final locations = state.locations;

              if (locations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_city_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.translate('location.no_locations'),
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l10n.translate('location.search_placeholder'),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),
                  ),
                  // Location List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        top: AppSpacing.sm,
                        bottom: 80.0,
                      ),
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        final location = locations[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: LocationCard(
                            location: location,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductManagementPage(
                                    locationId: location.id,
                                    locationName: location.name,
                                    locationAddress: location.address,
                                  ),
                                ),
                              );
                            },
                            onToggleStatus: (isActive) =>
                                onToggleStatus(location.id, isActive),
                            onEdit: () => onEdit(location),
                            onDelete: () => onDelete(location),
                            onAddManager: () {
                              AppSnackBar.show(
                                context,
                                message: 'Thêm nhân viên quản lý',
                                type: AppSnackBarType.info,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
