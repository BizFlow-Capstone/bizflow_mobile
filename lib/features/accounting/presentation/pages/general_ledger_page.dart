import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/accounting_gl_tab.dart';

class GeneralLedgerPage extends StatelessWidget {
  const GeneralLedgerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('accounting.general_ledger')),
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: const AccountingGlTab(),
    );
  }
}
