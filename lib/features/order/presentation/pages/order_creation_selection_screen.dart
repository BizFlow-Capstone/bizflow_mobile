import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import 'order_audio_upload_screen.dart';
import 'order_form_screen.dart';
import 'order_voice_record_screen.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';

/// Screen SC-ORD-01: User selects method to create an order
class OrderCreationSelectionScreen extends StatefulWidget {
  const OrderCreationSelectionScreen({super.key});

  @override
  State<OrderCreationSelectionScreen> createState() =>
      _OrderCreationSelectionScreenState();
}

class _OrderCreationSelectionScreenState
    extends State<OrderCreationSelectionScreen> {
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
      body: SafeArea(
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
                onTap: () async {
                  final allowed = await SubscriptionFeatureGuard.ensureAllowed(
                    context,
                    featureCode: SubscriptionFeatureCodes.orders,
                  );
                  if (!allowed || !context.mounted) return;
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
                onTap: () async {
                  final allowed = await SubscriptionFeatureGuard.ensureAllowed(
                    context,
                    featureCode: SubscriptionFeatureCodes.orders,
                  );
                  if (!allowed || !context.mounted) return;
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
                onTap: () async {
                  final allowed = await SubscriptionFeatureGuard.ensureAllowed(
                    context,
                    featureCode: SubscriptionFeatureCodes.orders,
                  );
                  if (!allowed || !context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrderFormScreen(inputType: 'manual'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
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
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
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
                        color: AppColors.textPrimary,
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
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
