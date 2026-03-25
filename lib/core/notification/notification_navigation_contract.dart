import 'dart:convert';

import '../routing/app_router.dart';

class NotificationNavigationContract {
  NotificationNavigationContract._();

  static const String actionNavigate = 'NAVIGATE';
  static const String actionNavigateToScreen = 'NAVIGATE_TO_SCREEN';

  static String? resolveFromPushData(Map<String, dynamic> data) {
    final route = data['route']?.toString();
    if (route != null && route.isNotEmpty) {
      return route;
    }

    return resolve(
      actionType: data['actionType']?.toString(),
      targetScreen: data['targetScreen']?.toString(),
      actionPayloadJson: data['actionPayloadJson']?.toString(),
      type: data['type']?.toString(),
    );
  }

  static String? resolve({
    String? actionType,
    String? targetScreen,
    String? actionPayloadJson,
    String? type,
  }) {
    final normalizedAction = actionType?.trim().toUpperCase();
    if (normalizedAction != null &&
        normalizedAction != actionNavigate &&
        normalizedAction != actionNavigateToScreen) {
      return null;
    }

    if (actionPayloadJson != null && actionPayloadJson.isNotEmpty) {
      final rawPayload = actionPayloadJson.trim();
      if (rawPayload.startsWith('http://') || rawPayload.startsWith('https://')) {
        return rawPayload;
      }

      try {
        final decoded = jsonDecode(actionPayloadJson);
        if (decoded is Map<String, dynamic>) {
          final route = decoded['route']?.toString();
          if (route != null && route.isNotEmpty) {
            return route;
          }
        }
      } catch (_) {
        // Ignore malformed payload.
      }
    }

    final normalizedTarget = targetScreen?.trim().toLowerCase();
    if (normalizedTarget == 'employeeinvitations' ||
        normalizedTarget == 'employeeinvitationspage') {
      return AppRoutes.employeeInvitations;
    }

    if (normalizedTarget == 'subscriptionplans' ||
        normalizedTarget == 'subscriptionplanspage' ||
        normalizedTarget == 'premiumpaymentpage' ||
        normalizedTarget == 'buypackagepage') {
      return AppRoutes.subscriptionPlans;
    }

    final normalizedType = type?.trim().toLowerCase();
    if (normalizedType == 'employee_invite') {
      return AppRoutes.employeeInvitations;
    }

    return null;
  }
}
