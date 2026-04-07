import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/context/business_context.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_event.dart';
import '../../../location/presentation/bloc/location_state.dart';
import '../../../../core/services/firebase_messaging_service.dart';

class PostAuthNavigation {
  PostAuthNavigation._();

  static Future<void> route(BuildContext context) async {
    final locationBloc = context.read<LocationBloc>();

    LocationState state;
    // Always force a fresh fetch after auth/switch-account.
    // This avoids using stale in-memory/cache location lists from a previous account.
    locationBloc.add(const LoadLocationsRequested(useCache: false));
    try {
      state = await locationBloc.stream.firstWhere(
        (s) => s is LocationsLoaded || s is LocationFailure,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('PostAuthNavigation: Timeout waiting for locations, proceeding to home.');
      // Fallback to currently loaded state or empty
      state = locationBloc.state;
    }

    if (!context.mounted) {
      return;
    }

    if (state is LocationFailure) {
      AppRouter.navigateAndClearStack(AppRoutes.home);
      return;
    }

    final loadedState = state as LocationsLoaded;
    final locations = loadedState.locations
      .where((location) => location.isActive)
      .toList();
    final businessContext = BusinessContext();

    if (locations.isEmpty) {
      await businessContext.clear();
      if (!context.mounted) {
        return;
      }
      AppRouter.navigateAndClearStack(AppRoutes.noLocation);
      return;
    }

    final selectedId = businessContext.currentBusinessId;
    final isSelectedValid =
        selectedId != null &&
        locations.any((location) => location.id == selectedId);

    if (!isSelectedValid) {
      final firstLocation = locations.first;
      await businessContext.switchBusinessLocation(
        firstLocation.id,
        firstLocation.name,
        isOwner: firstLocation.isOwner,
        ownerProfileId: firstLocation.ownerProfileId,
      );
    }

    if (!context.mounted) {
      return;
    }

    // Keep Home as root route to avoid empty stack/black screen when users press back
    // after opening app from a notification deep-link.
    final pendingRoute = await FirebaseMessagingService.consumePendingRoute();
    AppRouter.navigateAndClearStack(AppRoutes.home);

    if (pendingRoute != null && pendingRoute != AppRoutes.home) {
      Future<void>.delayed(Duration.zero, () {
        AppRouter.navigateFromNotificationTarget(pendingRoute);
      });
    }
  }
}
