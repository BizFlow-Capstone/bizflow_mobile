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
    final currentState = locationBloc.state;
    if (currentState is LocationsLoaded) {
      state = currentState;
    } else {
      locationBloc.add(const LoadLocationsRequested());
      state = await locationBloc.stream.firstWhere(
        (s) => s is LocationsLoaded || s is LocationFailure,
      );
    }

    if (!context.mounted) {
      return;
    }

    if (state is LocationFailure) {
      AppRouter.navigateAndClearStack(AppRoutes.home);
      return;
    }

    final loadedState = state as LocationsLoaded;
    final locations = loadedState.locations;
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
