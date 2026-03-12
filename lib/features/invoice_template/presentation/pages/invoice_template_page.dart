import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/invoice_template_bloc.dart';
import '../bloc/invoice_template_event.dart';
import '../bloc/invoice_template_state.dart';
import '../widgets/invoice_preview_widget.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_state.dart';
import '../../data/models/invoice_template_dto.dart';
import '../../../../shared/dialogs/app_snackbar.dart';

class InvoiceTemplatePage extends StatefulWidget {
  const InvoiceTemplatePage({super.key});

  @override
  State<InvoiceTemplatePage> createState() => _InvoiceTemplatePageState();
}

class _InvoiceTemplatePageState extends State<InvoiceTemplatePage> {
  // Form controllers
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _businessTaxController = TextEditingController();
  final _businessLogoController = TextEditingController();

  String _selectedTemplate = 'basic';
  List<String> _appliedLocations = [];

  // Hidden values for simple mode
  final _noteTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<InvoiceTemplateBloc>().add(const LoadInvoiceTemplateRequested());
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    _businessTaxController.dispose();
    _businessLogoController.dispose();
    _noteTextController.dispose();
    super.dispose();
  }

  void _populateData(InvoiceTemplateLoaded state) {
    if (_businessNameController.text.isEmpty && state.template.businessName.isNotEmpty) {
      final tpl = state.template;
      _businessNameController.text = tpl.businessName;
      _businessAddressController.text = tpl.businessAddress;
      _businessPhoneController.text = tpl.businessPhone;
      _businessEmailController.text = tpl.businessEmail;
      _businessTaxController.text = tpl.businessTaxCode;
      _businessLogoController.text = tpl.businessLogoUrl;
      _noteTextController.text = tpl.footerNoteText;
      
      _selectedTemplate = tpl.templateType;
      _appliedLocations = List.from(tpl.appliedLocationIds);
    }
  }

  void _onSave(InvoiceTemplateLoaded currentState) {
    // Keep all the existing complex booleans from the state, just update the basic fields
    final tpl = currentState.template;
    final req = UpdateInvoiceTemplateRequestDto(
      businessName: _businessNameController.text,
      businessAddress: _businessAddressController.text,
      businessPhone: _businessPhoneController.text,
      businessEmail: _businessEmailController.text,
      businessTaxCode: _businessTaxController.text,
      businessLogoUrl: _businessLogoController.text,
      templateType: _selectedTemplate,
      showStt: tpl.showStt,
      showItemName: tpl.showItemName,
      showQuantity: tpl.showQuantity,
      showUnit: tpl.showUnit,
      showUnitPrice: tpl.showUnitPrice,
      showItemDiscount: tpl.showItemDiscount,
      showItemVat: tpl.showItemVat,
      showItemTotalAmount: tpl.showItemTotalAmount,
      showCustomerName: tpl.showCustomerName,
      showCustomerPhone: tpl.showCustomerPhone,
      showCustomerAddress: tpl.showCustomerAddress,
      showCustomerEmail: tpl.showCustomerEmail,
      showCustomerTaxCode: tpl.showCustomerTaxCode,
      showTotalVat: tpl.showTotalVat,
      showTotalDiscount: tpl.showTotalDiscount,
      showSubTotal: tpl.showSubTotal,
      showFooterNote: tpl.showFooterNote,
      showFooterTerms: tpl.showFooterTerms,
      showSignature: tpl.showSignature,
      footerNoteText: tpl.footerNoteText,
      primaryColor: tpl.primaryColor,
      secondaryColor: tpl.secondaryColor,
      appliedLocationIds: _appliedLocations,
    );

    context.read<InvoiceTemplateBloc>().add(SaveInvoiceTemplateRequested(request: req));
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        title: Text(
          l10n.translate('invoice_template.title'),
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<InvoiceTemplateBloc, InvoiceTemplateState>(
        listener: (context, state) {
          if (state is InvoiceTemplateSaveSuccess) {
            AppSnackBar.show(context, message: l10n.translate('invoice_template.save_success'), type: AppSnackBarType.success);
          } else if (state is InvoiceTemplateFailure) {
            AppSnackBar.show(context, message: state.message, type: AppSnackBarType.error);
          }
        },
        builder: (context, state) {
          if (state is InvoiceTemplateInitial || state is InvoiceTemplateLoading && _businessNameController.text.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InvoiceTemplateLoaded) {
            _populateData(state);
          }

          InvoiceTemplateLoaded? loadedState;
          if (state is InvoiceTemplateLoaded) loadedState = state;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Template Choices
                    Text(l10n.translate('invoice_template.select_template'), style: AppTextStyles.titleMedium),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildTemplateCard('basic', Icons.description_outlined, l10n.translate('invoice_template.tpl_basic')),
                          _buildTemplateCard('professional', Icons.business_center_outlined, l10n.translate('invoice_template.tpl_prof')),
                          _buildTemplateCard('retail', Icons.storefront_outlined, l10n.translate('invoice_template.tpl_retail')),
                          _buildTemplateCard('fnb', Icons.restaurant_menu_outlined, l10n.translate('invoice_template.tpl_fnb')),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 1.5: Live Preview
                    Text(l10n.translate('invoice_template.live_preview'), style: AppTextStyles.titleMedium),
                    ListenableBuilder(
                      listenable: Listenable.merge([
                        _businessNameController,
                        _businessAddressController,
                        _businessPhoneController,
                        _noteTextController,
                      ]),
                      builder: (context, _) {
                        return InvoicePreviewWidget(
                          businessName: _businessNameController.text,
                          businessAddress: _businessAddressController.text,
                          businessPhone: _businessPhoneController.text,
                          footerNoteText: _noteTextController.text,
                          showStt: loadedState?.template.showStt ?? true,
                          showItemName: loadedState?.template.showItemName ?? true,
                          showQuantity: loadedState?.template.showQuantity ?? true,
                          showUnit: loadedState?.template.showUnit ?? true,
                          showUnitPrice: loadedState?.template.showUnitPrice ?? true,
                          showItemDiscount: loadedState?.template.showItemDiscount ?? false,
                          showItemVat: loadedState?.template.showItemVat ?? false,
                          showItemTotalAmount: loadedState?.template.showItemTotalAmount ?? true,
                          showCustomerName: loadedState?.template.showCustomerName ?? true,
                          showCustomerPhone: loadedState?.template.showCustomerPhone ?? true,
                          showCustomerAddress: loadedState?.template.showCustomerAddress ?? true,
                          showTotalVat: loadedState?.template.showTotalVat ?? false,
                          showTotalDiscount: loadedState?.template.showTotalDiscount ?? false,
                          showSubTotal: loadedState?.template.showSubTotal ?? false,
                          showFooterNote: loadedState?.template.showFooterNote ?? false,
                          showSignature: loadedState?.template.showSignature ?? false,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 2: Business Info
                    ExpansionTile(
                      title: Text(l10n.translate('invoice_template.business_info'), style: AppTextStyles.titleMedium),
                      initiallyExpanded: true,
                      childrenPadding: const EdgeInsets.all(16),
                      children: [
                        _buildTextField(l10n.translate('invoice_template.business_name'), _businessNameController),
                        _buildTextField(l10n.translate('invoice_template.business_address'), _businessAddressController),
                        _buildTextField(l10n.translate('invoice_template.business_phone'), _businessPhoneController),
                        _buildTextField(l10n.translate('invoice_template.business_email'), _businessEmailController),
                        _buildTextField(l10n.translate('invoice_template.business_tax_code'), _businessTaxController),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Section 3: Apply to Locations
                    ExpansionTile(
                      title: Text(l10n.translate('invoice_template.applied_locations'), style: AppTextStyles.titleMedium),
                      initiallyExpanded: true,
                      children: [
                        BlocBuilder<LocationBloc, LocationState>(
                          builder: (context, locState) {
                            if (locState is LocationsLoaded) {
                              return Wrap(
                                spacing: 8,
                                children: locState.locations.map((loc) {
                                  final isSelected = _appliedLocations.contains(loc.id);
                                  return FilterChip(
                                    label: Text(loc.name),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _appliedLocations.add(loc.id);
                                        } else {
                                          _appliedLocations.remove(loc.id);
                                        }
                                      });
                                    },
                                    selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                                    checkmarkColor: AppColors.secondary,
                                  );
                                }).toList(),
                              );
                            }
                            return const Center(child: CircularProgressIndicator());
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                    const SizedBox(height: 100), // padding for bottom bar
                  ],
                ),
              ),
              
              // Bottom Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (state is InvoiceTemplateSaveInProgress || loadedState == null) 
                        ? null 
                        : () => _onSave(loadedState!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: state is InvoiceTemplateSaveInProgress
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(l10n.translate('invoice_template.save'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ));
  }

  Widget _buildTemplateCard(String id, IconData icon, String title) {
    bool isSelected = _selectedTemplate == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedTemplate = id),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.secondary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isSelected ? AppColors.secondary : Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.secondary : Colors.grey.shade800,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
