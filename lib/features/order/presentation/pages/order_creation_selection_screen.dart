import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../../subscription/data/subscription_repository.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import 'order_audio_upload_screen.dart';
import 'order_form_screen.dart';
import 'order_voice_record_screen.dart';

/// Screen SC-ORD-01: User selects method to create an order
class OrderCreationSelectionScreen extends StatefulWidget {
  const OrderCreationSelectionScreen({super.key});

  @override
  State<OrderCreationSelectionScreen> createState() =>
      _OrderCreationSelectionScreenState();
}

class _OrderCreationSelectionScreenState
    extends State<OrderCreationSelectionScreen> {
  late final Future<List<bool>> _featureAvailabilityFuture;

  @override
  void initState() {
    super.initState();
    final businessContext = context.read<BusinessContext>();
    _featureAvailabilityFuture = Future.wait([
      context.read<SubscriptionRepository>().canUseFeatureCode(
            featureCode: SubscriptionFeatureCodes.orders,
            ownerProfileId: businessContext.currentOwnerProfileId,
          ),
      context.read<SubscriptionRepository>().canUseFeatureCode(
            featureCode: SubscriptionFeatureCodes.ai,
            ownerProfileId: businessContext.currentOwnerProfileId,
          ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order_create.select_method_title')),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: Colors.black,
          ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: const AppSyncStatusText(),
      ),
      body: FutureBuilder<List<bool>>(
        future: _featureAvailabilityFuture,
        builder: (context, snapshot) {
          final availability = snapshot.data ?? const [true, true];
          final canCreateOrders = availability[0];
          final canUseAi = availability[1];
          final warning = l10n.translate('subscription.limit_warning');

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  _buildSelectionCard(
                    context: context,
                    icon: Icons.mic,
                    title: l10n.translate('order_create.method_voice'),
                    subtitle: l10n.translate('order_create.method_voice_subtitle'),
                    color: Colors.blue.shade50,
                    iconColor: Colors.blue,
                    isEnabled: canCreateOrders && canUseAi,
                    warning: (canCreateOrders && canUseAi) ? null : warning,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrderVoiceRecordScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSelectionCard(
                    context: context,
                    icon: Icons.upload_file,
                    title: l10n.translate('order_create.method_audio'),
                    subtitle: null,
                    color: Colors.green.shade50,
                    iconColor: Colors.green,
                    isEnabled: canCreateOrders && canUseAi,
                    warning: (canCreateOrders && canUseAi) ? null : warning,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrderAudioUploadScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSelectionCard(
                    context: context,
                    icon: Icons.edit_document,
                    title: l10n.translate('order_create.method_manual'),
                    subtitle: null,
                    color: Colors.orange.shade50,
                    iconColor: Colors.orange,
                    isEnabled: canCreateOrders,
                    warning: canCreateOrders ? null : warning,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const OrderFormScreen(inputType: 'manual'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required Color iconColor,
    required bool isEnabled,
    String? warning,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: isEnabled ? 2 : 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isEnabled ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? Colors.transparent
                  : AppColors.warning.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled ? color : AppColors.divider,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? iconColor : AppColors.textSecondary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isEnabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (warning != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.workspace_premium_outlined,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                warning,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isEnabled ? Icons.chevron_right : Icons.block_outlined,
                color:
                    isEnabled ? AppColors.textSecondary : AppColors.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
