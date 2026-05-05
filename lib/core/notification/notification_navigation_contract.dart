import 'dart:convert';

import '../routing/app_router.dart';

class NotificationNavigationResolution {
  final String? internalRoute; // Đường dẫn internal nếu có
  final String? externalUrl;   // URL bên ngoài nếu có
  final String? notificationType;

  NotificationNavigationResolution({
    this.internalRoute,
    this.externalUrl,
    this.notificationType,
  });

  bool get hasExternalUrl => externalUrl != null && externalUrl!.isNotEmpty && 
      (externalUrl!.startsWith('http://') || externalUrl!.startsWith('https://'));
  
  bool get hasInternalRoute => internalRoute != null && internalRoute!.isNotEmpty;
}

class NotificationNavigationContract {
  NotificationNavigationContract._();

  static const String actionNavigate = 'NAVIGATE';
  static const String actionNavigateToScreen = 'NAVIGATE_TO_SCREEN';

  /// Legacy method for backward compatibility - returns only internal route
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

  /// New method - returns resolution with both internal route and external URL
  static NotificationNavigationResolution resolveDetailed({
    String? actionType,
    String? targetScreen,
    String? actionPayloadJson,
    String? type,
  }) {
    final normalizedAction = actionType?.trim().toUpperCase();
    if (normalizedAction != null &&
        normalizedAction != actionNavigate &&
        normalizedAction != actionNavigateToScreen) {
      return NotificationNavigationResolution(notificationType: type);
    }

    String? externalUrl;
    String? internalRoute;

    // Check if payload is external URL or internal route
    if (actionPayloadJson != null && actionPayloadJson.isNotEmpty) {
      final rawPayload = actionPayloadJson.trim();
      if (rawPayload.startsWith('http://') || rawPayload.startsWith('https://')) {
        externalUrl = rawPayload;
      } else {
        try {
          final decoded = jsonDecode(actionPayloadJson);
          if (decoded is Map<String, dynamic>) {
            final route = decoded['route']?.toString();
            if (route != null && route.isNotEmpty) {
              internalRoute = route;
            }
          }
        } catch (_) {
          // Ignore malformed payload.
        }
      }
    }

    // Resolve target screen to internal route
    final normalizedTarget = targetScreen?.trim().toLowerCase();
    if (normalizedTarget == 'employeeinvitations' ||
        normalizedTarget == 'employeeinvitationspage') {
      internalRoute = AppRoutes.employeeInvitations;
    } else if (normalizedTarget == 'subscriptionplans' ||
        normalizedTarget == 'subscriptionplanspage' ||
        normalizedTarget == 'premiumpaymentpage' ||
        normalizedTarget == 'buypackagepage') {
      internalRoute = AppRoutes.subscriptionPlans;
    }

    // For EMPLOYEE_INVITE type, should navigate to invitations page
    final normalizedType = type?.trim().toLowerCase();
    if ((normalizedType == 'employee_invite' || normalizedType == 'employee_invite_accepted') 
        && internalRoute == null) {
      internalRoute = AppRoutes.notifications;
    }

    return NotificationNavigationResolution(
      internalRoute: internalRoute,
      externalUrl: externalUrl,
      notificationType: type,
    );
  }

  /// Legacy method for backward compatibility - returns only internal route
  static String? resolve({
    String? actionType,
    String? targetScreen,
    String? actionPayloadJson,
    String? type,
  }) {
    final resolution = resolveDetailed(
      actionType: actionType,
      targetScreen: targetScreen,
      actionPayloadJson: actionPayloadJson,
      type: type,
    );
    return resolution.internalRoute;
  }
}
