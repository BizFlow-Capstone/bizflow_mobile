import 'package:bizflow_mobile/core/theme/app_colors.dart';
import 'package:bizflow_mobile/core/theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/cache/swr_builder.dart';
import '../../../../core/routing/app_router.dart';
import '../../data/subscription_repository.dart';
import '../../data/models/subscription_models.dart';
import '../../data/subscription_api_service.dart';

import '../../../../shared/context/business_context.dart';

class CurrentSubscriptionPage extends StatelessWidget {
  final bool fromCheckoutResult;

  const CurrentSubscriptionPage({
    super.key,
    this.fromCheckoutResult = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final apiService = context.read<SubscriptionApiService>();
    final repo = context.read<SubscriptionRepository>();
    final businessContext = Provider.of<BusinessContext>(context);
    final isOwner = businessContext.isOwner;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
         elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (fromCheckoutResult) {
              AppRouter.navigateAndClearStack(AppRoutes.home);
              return;
            }
            Navigator.pop(context);
          },
          color: Colors.black,
        ),
        title: Text(
          l10n.translate('subscription.my_current_plan'),
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SwrBuilder<CurrentSubscriptionDto?>(
        cacheKey: 'current_subscription',
        fetcher: ({cancelToken}) => apiService.getCurrentSubscription(
          cancelToken: cancelToken,
        ),
        fromJson: (json) => CurrentSubscriptionDto.fromJson(json),
        toJson: (data) => data?.toJson() ?? {},
        builder: (context, currentSub, isLoading, error) {
          if (isLoading && currentSub == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (error != null && currentSub == null) {
            return Center(child: Text(error.toString()));
          }

          final ownerProfileId = isOwner
              ? null
              : businessContext.currentOwnerProfileId;
          final repoStream = repo.streamUsageTracking(
            ownerProfileId: ownerProfileId,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isOwner) ...[
                  _buildEmployeeBanner(context),
                  const SizedBox(height: 16),
                ],
                _buildCurrentPlanCard(context, currentSub),
                if (currentSub?.isActive == true) ...[
                  const SizedBox(height: 24),
                  _buildUsageStats(context, repoStream, currentSub!),
                ],
                if (isOwner) ...[
                  const SizedBox(height: 24),
                  _buildActions(context),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bạn đang xem gói đăng ký của chủ cơ sở cho địa điểm này.',
              style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(BuildContext context, CurrentSubscriptionDto? currentSub) {
    final l10n = AppLocalizations.of(context);
    final isInactive = currentSub == null || !currentSub.isActive;

    if (isInactive) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Column(
          children: [
            const Icon(Icons.info_outline, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(l10n.translate('subscription.no_active_plan'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]
        )
      );
    }

    final planName = currentSub.plan?.name ?? 'Plan';
    final endDateStr = currentSub.endDate != null ? DateTime.tryParse(currentSub.endDate!) : null;
    final formattedDate = endDateStr != null ? '${endDateStr.day.toString().padLeft(2, '0')}/${endDateStr.month.toString().padLeft(2, '0')}/${endDateStr.year}' : 'N/A';
    final expiryText = l10n.translate('subscription.active_until').replaceAll('{date}', formattedDate);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
         borderRadius: BorderRadius.circular(16),
         boxShadow: [
           BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
         ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
             padding: const EdgeInsets.all(20),
             decoration: const BoxDecoration(
               gradient: LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF9800)]),
               borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))
             ),
             child: Row(
               children: [
                 const Icon(Icons.workspace_premium, color: Colors.white, size: 40),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         planName,
                         style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         expiryText,
                         style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                       ),
                     ],
                   ),
                 ),
               ],
             ),
          ),
        ]
      )
    );
  }

  Widget _buildUsageStats(BuildContext context, Stream<DocumentSnapshot<Map<String, dynamic>>>? stream, CurrentSubscriptionDto currentSub) {
    final l10n = AppLocalizations.of(context);
    final planFeatures = currentSub.plan?.features ?? [];

    if (stream == null) {
      return _buildUsageSection(
        context: context,
        l10n: l10n,
        planFeatures: planFeatures,
        featuresUsage: const {},
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Text(
                  'Khong the doc thong tin su dung tu Firestore. Dang hien han muc theo goi hien tai.',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
              _buildUsageSection(
                context: context,
                l10n: l10n,
                planFeatures: planFeatures,
                featuresUsage: const {},
              ),
            ],
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return _buildUsageSection(
            context: context,
            l10n: l10n,
            planFeatures: planFeatures,
            featuresUsage: const {},
          );
        }

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return _buildUsageSection(
            context: context,
            l10n: l10n,
            planFeatures: planFeatures,
            featuresUsage: const {},
          );
        }

        final data = snapshot.data!.data()!;
        final featuresUsage = data['features'] as Map<String, dynamic>? ?? {};

        return _buildUsageSection(
          context: context,
          l10n: l10n,
          planFeatures: planFeatures,
          featuresUsage: featuresUsage,
        );
      },
    );
  }

  Widget _buildUsageSection({
    required BuildContext context,
    required AppLocalizations l10n,
    required List<PlanFeatureDto> planFeatures,
    required Map<String, dynamic> featuresUsage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('subscription.usage_limits'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...planFeatures.map((pf) {
          final fsData = featuresUsage[pf.featureCode] as Map<String, dynamic>? ?? {};
          final used = (fsData['used'] as num?)?.toInt() ?? 0;
          final limit = (fsData['limit'] as num?)?.toInt() ?? pf.usageLimit;
          return _buildUsageBar(context, pf.featureName, used, limit);
        }),
      ],
    );
  }

  Widget _buildUsageBar(BuildContext context, String featureName, int used, int limit) {
    final l10n = AppLocalizations.of(context);
    final isUnlimited = limit == -1;
    final ratio = isUnlimited ? 0.0 : (used / limit).clamp(0.0, 1.0);
    
    final valueText = isUnlimited 
       ? l10n.translate('subscription.unlimited') 
       : l10n.translate('subscription.used_format').replaceAll('{used}', used.toString()).replaceAll('{limit}', limit.toString());

    Color progressColor = Colors.blue;
    if (!isUnlimited) {
       if (ratio > 0.9) {
         progressColor = Colors.red;
       } else if (ratio > 0.75) {
         progressColor = Colors.orange;
       }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(featureName, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(valueText, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          if (!isUnlimited)
            LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE65100),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            AppRouter.navigateTo(AppRoutes.subscriptionPlans);
          },
          child: Text(
            l10n.translate('subscription.manage_plan'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Color(0xFFE65100)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            AppRouter.navigateTo(AppRoutes.subscriptionTransactions);
          },
          icon: const Icon(
            Icons.receipt_long_outlined,
            color: Color(0xFFE65100),
          ),
          label: Text(
            l10n.translate('subscription.transactions_title'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE65100),
            ),
          ),
        ),
      ],
    );
  }
}
