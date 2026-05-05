import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/cache/cache_manager.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/subscription_api_service.dart';
import '../data/models/subscription_models.dart';

class SubscriptionRepository extends ChangeNotifier {
  final SubscriptionApiService _apiService;
  final CacheManager _cache;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _usageTrackingSubscription;
  String? _activeUsageTrackingDocId;
  Map<String, int> _latestUsageByFeatureCode = const {};
  // Preserve last valid snapshot when network error occurs
  Map<String, int> _lastValidUsageSnapshot = const {};

  // In-memory current subscription — updated every time fresh API data arrives.
  // This is the single source of truth for instant UI reads; no serialization needed.
  CurrentSubscriptionDto? _currentSubscription;

  /// Synchronous read — always returns the most recent known subscription.
  /// Safe to call from initState / build without await.
  CurrentSubscriptionDto? get currentSubscriptionSnapshot =>
      _currentSubscription;

  /// Called by any service that fetches fresh subscription data (Home prefetch,
  /// checkout result, etc.) to keep the in-memory value up-to-date.
  void updateCurrentSubscription(CurrentSubscriptionDto? dto) {
    _currentSubscription = dto;
    notifyListeners();
  }

  // Persistent feature-limit flags.
  // Key: featureCode (lowercase). Value: true = at-or-over limit (blocked).
  // Persisted to cache so the flag survives app restart.
  // Rule: once blocked, stays blocked until realtime confirms used < limit.
  static const _flagsCacheKey = 'feature_limit_flags';
  Map<String, bool> _featureLimitFlags = {};

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
        return list
            .map((e) => SubscriptionPlanDto.fromJson(e as Map<String, dynamic>))
            .toList();
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
        // Keep in-memory snapshot synchronized for instant UI reads.
        updateCurrentSubscription(data);
        onData(data, isFromCache);
      },
      onError: onError,
      toJson: (data) => data?.toJson() ?? {},
      fromJson: (json) =>
          json.isEmpty ? null : CurrentSubscriptionDto.fromJson(json),
    );
  }

  /// Call Checkout Endpoint
  Future<CheckoutSessionResponseDto> checkoutSubscription(int planId) async {
    return await _apiService.checkoutSubscription(planId);
  }

  /// Best-effort mobile pre-check before calling backend protected features.
  /// Backend is still the final authority for limit enforcement.
  Future<bool> canUseFeatureCode({
    required String featureCode,
    String? ownerProfileId,
  }) async {
    final normalizedCode = featureCode.trim();
    if (normalizedCode.isEmpty) return true;

    try {
      final currentSub = await _apiService.getCurrentSubscription();
      final plan = currentSub?.plan;
      if (plan == null) {
        return true;
      }

      PlanFeatureDto? feature;
      for (final item in plan.features) {
        if (item.featureCode.toLowerCase() == normalizedCode.toLowerCase()) {
          feature = item;
          break;
        }
      }

      // If feature is not listed in plan, treat as not limited on mobile side.
      if (feature == null) {
        return true;
      }

      final limit = feature.usageLimit;
      if (limit < 0) return true; // unlimited
      if (limit == 0) return false;

      await _ensureUsageTrackingListener(ownerProfileId: ownerProfileId);

      final realtimeUsed = _readUsedCountFromRealtimeCache(normalizedCode);
      if (realtimeUsed != null) {
        return realtimeUsed < limit;
      }

      final used = await _getFeatureUsedCount(
        featureCode: feature.featureCode,
        ownerProfileId: ownerProfileId,
      );

      // Fail-open on missing usage snapshot; backend check still runs.
      if (used == null) return true;

      return used < limit;
    } catch (_) {
      // Pre-check should never block user when local check cannot resolve.
      return true;
    }
  }

  Future<void> _ensureUsageTrackingListener({String? ownerProfileId}) async {
    final docId = await _prepareUsageTrackingDocId(
      ownerProfileId: ownerProfileId,
    );
    if (docId == null) {
      await _clearUsageTrackingListener();
      return;
    }

    if (_activeUsageTrackingDocId == docId &&
        _usageTrackingSubscription != null) {
      return;
    }

    await _clearUsageTrackingListener();

    // Load persisted flags before starting the stream so the flag state is
    // correct even before the first Firestore event arrives.
    await _loadFlagsFromCache();

    _activeUsageTrackingDocId = docId;
    _usageTrackingSubscription = FirebaseFirestore.instance
        .collection('usage_tracking')
        .doc(docId)
        .snapshots()
        .listen(
          (snapshot) {
            final extracted = _extractUsageMap(snapshot.data());
            _latestUsageByFeatureCode = extracted;
            // Always preserve as last valid snapshot (even if empty doc)
            if (extracted.isNotEmpty) {
              _lastValidUsageSnapshot = extracted;
              // Realtime update: recompute and persist limit flags.
              _updateFeatureLimitFlags(extracted);
            }
          },
          onError: (error) {
            //FIX: On network error, keep using last valid snapshot
            // Don't reset to empty - this prevents UI from showing wrong state
            if (_lastValidUsageSnapshot.isNotEmpty) {
              _latestUsageByFeatureCode = _lastValidUsageSnapshot;
            }
          },
        );
  }

  int? _readUsedCountFromRealtimeCache(String featureCode) {
    if (_latestUsageByFeatureCode.isEmpty) {
      return null;
    }

    final normalized = featureCode.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    return _latestUsageByFeatureCode[normalized];
  }

  Map<String, int> _extractUsageMap(Map<String, dynamic>? documentData) {
    if (documentData == null) {
      return const {};
    }

    final features = documentData['features'];
    if (features is! Map) {
      return const {};
    }

    final result = <String, int>{};
    for (final entry in features.entries) {
      final key = entry.key?.toString().trim().toLowerCase();
      if (key == null || key.isEmpty) {
        continue;
      }

      final value = entry.value;
      if (value is! Map) {
        continue;
      }

      final used = value['used'];
      if (used is num) {
        result[key] = used.toInt();
      }
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Feature-limit flag helpers
  // ---------------------------------------------------------------------------

  /// Synchronous check — safe to call from build() or anywhere without await.
  /// Returns true if the feature has reached (or exceeded) its plan limit.
  /// Stays true until Firestore confirms used < limit again.
  bool isFeatureLimitReached(String featureCode) {
    final key = featureCode.trim().toLowerCase();
    return _featureLimitFlags[key] ?? false;
  }

  Future<void> _loadFlagsFromCache() async {
    try {
      // Try synchronous read first (SharedPreferences already in RAM).
      final raw =
          _cache.tryGetSync(_flagsCacheKey) ?? await _cache.get(_flagsCacheKey);
      if (raw != null) {
        _featureLimitFlags = raw.map((k, v) => MapEntry(k, v == true));
      }
    } catch (_) {}
  }

  Future<void> _saveFlagsToCache() async {
    try {
      final json = _featureLimitFlags.map((k, v) => MapEntry(k, v));
      await _cache.set(_flagsCacheKey, json);
    } catch (_) {}
  }

  void _updateFeatureLimitFlags(Map<String, int> usageMap) {
    // Read plan limits synchronously from the subscription cache.
    Map<String, int> planLimits = {};
    try {
      final raw = _cache.tryGetSync('current_subscription');
      if (raw != null) {
        final sub = CurrentSubscriptionDto.fromJson(
          Map<String, dynamic>.from(raw),
        );
        for (final f in sub.plan?.features ?? []) {
          planLimits[f.featureCode.toLowerCase()] = f.usageLimit;
        }
      }
    } catch (_) {}

    if (planLimits.isEmpty) return;

    bool changed = false;
    for (final entry in usageMap.entries) {
      final code = entry.key; // already lowercased by _extractUsageMap
      final used = entry.value;
      final limit = planLimits[code];
      if (limit == null) continue;
      // limit == -1 means unlimited — never block.
      final blocked = limit >= 0 && used >= limit;
      if (_featureLimitFlags[code] != blocked) {
        _featureLimitFlags[code] = blocked;
        changed = true;
      }
    }

    if (changed) {
      unawaited(_saveFlagsToCache());
    }
  }

  // ---------------------------------------------------------------------------

  Future<void> _clearUsageTrackingListener() async {
    await _usageTrackingSubscription?.cancel();
    _usageTrackingSubscription = null;
    _activeUsageTrackingDocId = null;
    _latestUsageByFeatureCode = const {};
  }

  Future<void> dispose() async {
    await _clearUsageTrackingListener();
  }

  /// Stream Firestore Usage Tracking Document
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUsageTracking({
    String? ownerProfileId,
  }) {
    return Stream.fromFuture(
      _prepareUsageTrackingDocId(ownerProfileId: ownerProfileId),
    ).asyncExpand((docId) {
      if (docId == null) {
        return const Stream.empty();
      }
      return FirebaseFirestore.instance
          .collection('usage_tracking')
          .doc(docId)
          .snapshots();
    });
  }

  Future<String?> _prepareUsageTrackingDocId({String? ownerProfileId}) async {
    final currentProfileId = await _getCurrentProfileId();
    if (currentProfileId == null || currentProfileId.isEmpty) {
      return null;
    }

    await _ensureFirebaseAuthSession(currentProfileId);
    final scopeProfileId = (ownerProfileId ?? '').trim().isNotEmpty
        ? ownerProfileId!.trim()
        : currentProfileId;
    return '${scopeProfileId}_active';
  }

  Future<int?> _getFeatureUsedCount({
    required String featureCode,
    String? ownerProfileId,
  }) async {
    final docId = await _prepareUsageTrackingDocId(
      ownerProfileId: ownerProfileId,
    );
    if (docId == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('usage_tracking')
        .doc(docId)
        .get();
    final data = snapshot.data();
    if (data == null) return null;

    final features = data['features'] as Map<String, dynamic>?;
    if (features == null || features.isEmpty) return null;

    Map<String, dynamic>? featureData =
        features[featureCode] as Map<String, dynamic>?;

    if (featureData == null) {
      for (final entry in features.entries) {
        if (entry.key.toLowerCase() == featureCode.toLowerCase()) {
          featureData = entry.value as Map<String, dynamic>?;
          break;
        }
      }
    }

    return (featureData?['used'] as num?)?.toInt();
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
