import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/cache/sync_status_controller.dart';
import '../../../../shared/context/business_context.dart';
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
    SyncStatusController().setManualRefreshCallback(_triggerManualRefresh);
    context.read<LocationBloc>().add(const LoadLocationsRequested());
  }

  @override
  void dispose() {
    SyncStatusController().setManualRefreshCallback(null);
    super.dispose();
  }

  void _triggerManualRefresh() {
    unawaited(_refreshLocationsManually());
  }

  Future<void> _refreshLocationsManually() async {
    if (!mounted) return;
    SyncStatusController().startSync();
    try {
      context.read<LocationBloc>().add(
        const LoadLocationsRequested(useCache: false),
      );
      SyncStatusController().endSync(updatedAt: DateTime.now());
    } catch (_) {
      SyncStatusController().endSync(hasError: true);
    }
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
      title: l10n.translate(
        'product.confirm_delete_title',
      ), // Reusing product confirm delete for now
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
  @override
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
      listener: (context, state) async {
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
          final businessContext = Provider.of<BusinessContext>(
            context,
            listen: false,
          );
          if (businessContext.currentBusinessId == state.locationId) {
            await businessContext.clear();
            // In the next frame, LocationsLoaded will trigger and auto-select a new location.
          }
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
                current is LocationToggleInProgress ||
                current is LocationFailure ||
                current is LocationError ||
                current is LocationInitial;
          },
          builder: (context, state) {
            final cachedLocations = context
                .read<LocationBloc>()
                .currentLocations;
            final togglingLocationId = state is LocationToggleInProgress
                ? state.locationId
                : null;

            List<LocationEntity> locations = [];
            if (state is LocationsLoaded) {
              locations = state.locations;
            } else {
              locations = cachedLocations;
            }

            // Loading state (only when absolutely no local data)
            if (state is LocationLoading && locations.isEmpty) {
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

            if ((state is LocationFailure || state is LocationError) &&
                locations.isEmpty) {
              final message = state is LocationFailure
                  ? state.message
                  : (state as LocationError).message;

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 56,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () {
                          context.read<LocationBloc>().add(
                            const LoadLocationsRequested(),
                          );
                        },
                        child: Text(l10n.translate('common.retry')),
                      ),
                    ],
                  ),
                ),
              );
            }

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
                      final isOwner = Provider.of<BusinessContext>(
                        context,
                        listen: false,
                      ).isOwner;
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
                          // Owner-only actions
                          onToggleStatus: isOwner
                            ? (isActive) =>
                              onToggleStatus(location.id, isActive)
                              : null,
                          isToggleLoading: togglingLocationId == location.id,
                          onEdit: isOwner ? () => onEdit(location) : null,
                          onDelete: isOwner ? () => onDelete(location) : null,
                          activeText: l10n.translate('location.active_status'),
                          inactiveText: l10n.translate(
                            'location.inactive_status',
                          ),
                          onAddManager: () {
                            AppSnackBar.show(
                              context,
                              message: l10n.translate('location.add_manager'),
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
          },
        ),
      ),
    );
  }
}
