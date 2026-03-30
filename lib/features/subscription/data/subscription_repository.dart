import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/cache/cache_manager.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/subscription_api_service.dart';
import '../data/models/subscription_models.dart';

class SubscriptionRepository {
  final SubscriptionApiService _apiService;
  final CacheManager _cache;

  SubscriptionRepository(this._apiService) : _cache = CacheManager();

  /// SWR: Get Subscription Plans
  Future<void> getSubscriptionPlansSWR({
    required Function(List<SubscriptionPlanDto> data, bool isFromCache) onData,
    Function(dynamic error)? onError,
  }) async {
    const key = 'subscription_plans';

    await _cache.fetchWithSWR<List<SubscriptionPlanDto>>(
      key: key,
      fetcher: ({cancelToken}) async {
        return await _apiService.getSubscriptionPlans(cancelToken: cancelToken);
      },
      onData: (data, isFromCache) {
        onData(data, isFromCache);
      },
      onError: onError,
      toJson: (data) => {'list': data.map((e) => e.toJson()).toList()},
      fromJson: (json) {
        final list = json['list'] as List<dynamic>? ?? [];
        return list.map((e) => SubscriptionPlanDto.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  /// SWR: Get Current Subscription
  Future<void> getCurrentSubscriptionSWR({
    required Function(CurrentSubscriptionDto? data, bool isFromCache) onData,
    Function(dynamic error)? onError,
  }) async {
    const key = 'current_subscription';

    await _cache.fetchWithSWR<CurrentSubscriptionDto?>(
      key: key,
      fetcher: ({cancelToken}) async {
        return await _apiService.getCurrentSubscription(
          cancelToken: cancelToken,
        );
      },
      onData: (data, isFromCache) {
        onData(data, isFromCache);
      },
      onError: onError,
      toJson: (data) => data?.toJson() ?? {},
      fromJson: (json) => json.isEmpty ? null : CurrentSubscriptionDto.fromJson(json),
    );
  }

  /// Call Checkout Endpoint
  Future<CheckoutSessionResponseDto> checkoutSubscription(int planId) async {
    return await _apiService.checkoutSubscription(planId);
  }

  /// Stream Firestore Usage Tracking Document
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUsageTracking() {
    return Stream.fromFuture(_prepareUsageTrackingDocId()).asyncExpand((docId) {
      if (docId == null) {
        return const Stream.empty();
      }
      return FirebaseFirestore.instance
          .collection('usage_tracking')
          .doc(docId)
          .snapshots();
    });
  }

  Future<String?> _prepareUsageTrackingDocId() async {
    final profileId = await _getCurrentProfileId();
    if (profileId == null || profileId.isEmpty) {
      return null;
    }

    await _ensureFirebaseAuthSession(profileId);
    return '${profileId}_active';
  }

  Future<void> _ensureFirebaseAuthSession(String profileId) async {
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    if (currentUser != null && currentUser.uid == profileId) {
      return;
    }

    final customToken = await _apiService.createFirebaseCustomToken();
    await auth.signInWithCustomToken(customToken);
  }

  /// Decode JWT and get profileId
  Future<String?> _getCurrentProfileId() async {
    final token = await SecureStorage().getAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final padding = payload.length % 4;
      if (padding > 0) {
        payload = payload.padRight(payload.length + (4 - padding), '=');
      }

      final payloadJson = utf8.decode(base64.decode(payload));
      final payloadMap = jsonDecode(payloadJson) as Map<String, dynamic>;

      return payloadMap['profileId']?.toString();
    } catch (e) {
      return null;
    }
  }
}
