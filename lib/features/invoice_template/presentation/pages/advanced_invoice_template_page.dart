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
import '../../../location/domain/entities/location_entity.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import 'dart:async';
import '../../../../shared/context/business_context.dart';

class AdvancedInvoiceTemplatePage extends StatefulWidget {
  const AdvancedInvoiceTemplatePage({super.key});

  @override
  State<AdvancedInvoiceTemplatePage> createState() =>
      _AdvancedInvoiceTemplatePageState();
}

class _AdvancedInvoiceTemplatePageState
    extends State<AdvancedInvoiceTemplatePage> {
  // Form controllers
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _businessTaxController = TextEditingController();
  final _businessLogoController = TextEditingController();
  final _noteTextController = TextEditingController();

  String _selectedTemplate = 'basic';
  String _primaryColor = '#000000';
  String _secondaryColor = '#000000';
  List<String> _appliedLocations = [];

  // Toggles
  bool showStt = true;
  bool showItemName = true;
  bool showQuantity = true;
  bool showUnit = true;
  bool showUnitPrice = true;
  bool showItemDiscount = false;
  bool showItemVat = false;
  bool showItemTotalAmount = true;

  bool showCustomerName = true;
  bool showCustomerPhone = true;
  bool showCustomerAddress = true;
  bool showCustomerEmail = false;
  bool showCustomerTaxCode = false;

  bool showTotalVat = false;
  bool showTotalDiscount = false;
  bool showSubTotal = false;
  bool showFooterNote = false;
  bool showFooterTerms = false;
  bool showSignature = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<InvoiceTemplateBloc>().add(
      const LoadInvoiceTemplateRequested(),
    );
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
    _debounce?.cancel();
    super.dispose();
  }

  void _populateData(InvoiceTemplateLoaded state) {
    final tpl = state.template;

    bool isBrandNew = tpl.businessName.isEmpty ||
        tpl.businessName == 'Hộ Kinh Doanh TNHH ABC';

    if (_businessNameController.text.isEmpty) {
      if (!isBrandNew) {
        _businessNameController.text = tpl.businessName;
        _businessAddressController.text = tpl.businessAddress;
        _businessPhoneController.text = tpl.businessPhone;
        _businessEmailController.text = tpl.businessEmail;
        _businessTaxController.text = tpl.businessTaxCode;
        _businessLogoController.text = tpl.businessLogoUrl;
        _noteTextController.text = tpl.footerNoteText;
      } else {
        // Auto-fill from current location if template is empty/default
        final locationState = context.read<LocationBloc>().state;
        if (locationState is LocationsLoaded) {
          final activeLocations = locationState.locations
              .where((location) => location.isActive)
              .toList();
          final currentId = BusinessContext().currentBusinessId;
          final currentLocation = activeLocations.cast<LocationEntity?>().firstWhere(
                (l) => l?.id == currentId,
                orElse: () => activeLocations.isNotEmpty ? activeLocations.first : null,
              );

          if (currentLocation != null) {
            _businessNameController.text = currentLocation.name;
            _businessAddressController.text = currentLocation.fullAddress;
            _businessPhoneController.text = currentLocation.phone;
            _businessTaxController.text = currentLocation.taxCode ?? '';
          }
        }
      }

      _selectedTemplate = tpl.templateType;
      _primaryColor = tpl.primaryColor;
      _secondaryColor = tpl.secondaryColor;
      _appliedLocations = List.from(tpl.appliedLocationIds);

      showStt = tpl.showStt;
      showItemName = tpl.showItemName;
      showQuantity = tpl.showQuantity;
      showUnit = tpl.showUnit;
      showUnitPrice = tpl.showUnitPrice;
      showItemDiscount = tpl.showItemDiscount;
      showItemVat = tpl.showItemVat;
      showItemTotalAmount = tpl.showItemTotalAmount;

      showCustomerName = tpl.showCustomerName;
      showCustomerPhone = tpl.showCustomerPhone;
      showCustomerAddress = tpl.showCustomerAddress;
      showCustomerEmail = tpl.showCustomerEmail;
      showCustomerTaxCode = tpl.showCustomerTaxCode;

      showTotalVat = tpl.showTotalVat;
      showTotalDiscount = tpl.showTotalDiscount;
      showSubTotal = tpl.showSubTotal;
      showFooterNote = tpl.showFooterNote;
      showFooterTerms = tpl.showFooterTerms;
      showSignature = tpl.showSignature;
    }
  }

  void _onSave() {
    final req = UpdateInvoiceTemplateRequestDto(
      businessName: _businessNameController.text,
      businessAddress: _businessAddressController.text,
      businessPhone: _businessPhoneController.text,
      businessEmail: _businessEmailController.text,
      businessTaxCode: _businessTaxController.text,
      businessLogoUrl: _businessLogoController.text,
      templateType: _selectedTemplate,
      showStt: showStt,
      showItemName: showItemName,
      showQuantity: showQuantity,
      showUnit: showUnit,
      showUnitPrice: showUnitPrice,
      showItemDiscount: showItemDiscount,
      showItemVat: showItemVat,
      showItemTotalAmount: showItemTotalAmount,
      showCustomerName: showCustomerName,
      showCustomerPhone: showCustomerPhone,
      showCustomerAddress: showCustomerAddress,
      showCustomerEmail: showCustomerEmail,
      showCustomerTaxCode: showCustomerTaxCode,
      showTotalVat: showTotalVat,
      showTotalDiscount: showTotalDiscount,
      showSubTotal: showSubTotal,
      showFooterNote: showFooterNote,
      showFooterTerms: showFooterTerms,
      showSignature: showSignature,
      footerNoteText: _noteTextController.text,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      appliedLocationIds: _appliedLocations,
    );

    context.read<InvoiceTemplateBloc>().add(
      SaveInvoiceTemplateRequested(request: req),
    );
  }

  Widget _buildToggleItem(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.bodyMedium),
            Icon(
              value ? Icons.visibility : Icons.visibility_off,
              color: value ? AppColors.secondary : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
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
          l10n.translate('invoice_template.advanced_title'),
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
              AppSnackBar.show(
                context,
                message: l10n.translate('invoice_template.save_success'),
                type: AppSnackBarType.success,
              );
            } else if (state is InvoiceTemplateFailure) {
              AppSnackBar.show(
                context,
                message: state.message,
                type: AppSnackBarType.error,
              );
            }
          },
          builder: (context, state) {
            if (state is InvoiceTemplateInitial ||
                state is InvoiceTemplateLoading &&
                    _businessNameController.text.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is InvoiceTemplateLoaded) {
              _populateData(state);
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header text
                      Text(
                        l10n.translate('invoice_template.advanced_subtitle'),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Section 1: Template Choices (Horizontal Scroll)
                      Text(
                        l10n.translate('invoice_template.select_template'),
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildTemplateCard(
                              'basic',
                              Icons.description_outlined,
                              l10n.translate('invoice_template.tpl_basic'),
                            ),
                            _buildTemplateCard(
                              'professional',
                              Icons.business_center_outlined,
                              l10n.translate('invoice_template.tpl_prof'),
                            ),
                            _buildTemplateCard(
                              'retail',
                              Icons.storefront_outlined,
                              l10n.translate('invoice_template.tpl_retail'),
                            ),
                            _buildTemplateCard(
                              'fnb',
                              Icons.restaurant_menu_outlined,
                              l10n.translate('invoice_template.tpl_fnb'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Section 1.5: Live Preview
                      Text(
                        l10n.translate('invoice_template.live_preview'),
                        style: AppTextStyles.titleMedium,
                      ),
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
                            showStt: showStt,
                            showItemName: showItemName,
                            showQuantity: showQuantity,
                            showUnit: showUnit,
                            showUnitPrice: showUnitPrice,
                            showItemDiscount: showItemDiscount,
                            showItemVat: showItemVat,
                            showItemTotalAmount: showItemTotalAmount,
                            showCustomerName: showCustomerName,
                            showCustomerPhone: showCustomerPhone,
                            showCustomerAddress: showCustomerAddress,
                            showCustomerEmail: showCustomerEmail,
                            showCustomerTaxCode: showCustomerTaxCode,
                            showTotalVat: showTotalVat,
                            showTotalDiscount: showTotalDiscount,
                            showSubTotal: showSubTotal,
                            showFooterNote: showFooterNote,
                            footerNoteText: _noteTextController.text,
                            showSignature: showSignature,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Section 2: Business Info
                      ExpansionTile(
                        shape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        collapsedShape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        title: Text(
                          l10n.translate('invoice_template.business_info'),
                          style: AppTextStyles.titleMedium,
                        ),
                        initiallyExpanded: true,
                        childrenPadding: const EdgeInsets.all(16),
                        children: [
                          _buildTextField(
                            l10n.translate('invoice_template.business_name'),
                            _businessNameController,
                          ),
                          _buildTextField(
                            l10n.translate('invoice_template.business_address'),
                            _businessAddressController,
                          ),
                          _buildTextField(
                            l10n.translate('invoice_template.business_phone'),
                            _businessPhoneController,
                          ),
                          _buildTextField(
                            l10n.translate('invoice_template.business_email'),
                            _businessEmailController,
                          ),
                          _buildTextField(
                            l10n.translate(
                              'invoice_template.business_tax_code',
                            ),
                            _businessTaxController,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Section 3: Table Columns (Eye toggles)
                      ExpansionTile(
                        shape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        collapsedShape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        title: Text(
                          l10n.translate('invoice_template.table_config'),
                          style: AppTextStyles.titleMedium,
                        ),
                        children: [
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_stt'),
                            showStt,
                            (v) => setState(() => showStt = v),
                          ),
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_item_name'),
                            showItemName,
                            (v) => setState(() => showItemName = v),
                          ),
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_qty'),
                            showQuantity,
                            (v) => setState(() => showQuantity = v),
                          ),
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_unit'),
                            showUnit,
                            (v) => setState(() => showUnit = v),
                          ),
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_price'),
                            showUnitPrice,
                            (v) => setState(() => showUnitPrice = v),
                          ),
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_discount'),
                            showItemDiscount,
                            (v) => setState(() => showItemDiscount = v),
                          ),
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_vat'),
                            showItemVat,
                            (v) => setState(() => showItemVat = v),
                          ),
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_amount'),
                            showItemTotalAmount,
                            (v) => setState(() => showItemTotalAmount = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Section 4: Customer Info
                      ExpansionTile(
                        shape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        collapsedShape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        title: Text(
                          l10n.translate('invoice_template.customer_config'),
                          style: AppTextStyles.titleMedium,
                        ),
                        children: [
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_cus_name'),
                            showCustomerName,
                            (v) => setState(() => showCustomerName = v),
                          ),
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_cus_phone'),
                            showCustomerPhone,
                            (v) => setState(() => showCustomerPhone = v),
                          ),
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_cus_address'),
                            showCustomerAddress,
                            (v) => setState(() => showCustomerAddress = v),
                          ),
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_cus_email'),
                            showCustomerEmail,
                            (v) => setState(() => showCustomerEmail = v),
                          ),
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_cus_tax'),
                            showCustomerTaxCode,
                            (v) => setState(() => showCustomerTaxCode = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Section 5: Display Specs
                      ExpansionTile(
                        shape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        collapsedShape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        title: Text(
                          l10n.translate('invoice_template.display_config'),
                          style: AppTextStyles.titleMedium,
                        ),
                        children: [
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_total_vat'),
                            showTotalVat,
                            (v) => setState(() => showTotalVat = v),
                          ),
                          _buildToggleItem(
                            l10n.translate(
                              'invoice_template.show_total_discount',
                            ),
                            showTotalDiscount,
                            (v) => setState(() => showTotalDiscount = v),
                          ),
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_subtotal'),
                            showSubTotal,
                            (v) => setState(() => showSubTotal = v),
                          ),
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_note'),
                            showFooterNote,
                            (v) => setState(() => showFooterNote = v),
                          ),
                          if (showFooterNote)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: TextField(
                                controller: _noteTextController,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  labelText: l10n.translate(
                                    'invoice_template.note',
                                  ),
                                  hintText: l10n.translate(
                                    'invoice_template.note_hint',
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          _buildToggleItem(
                            l10n.translate('invoice_template.show_signature'),
                            showSignature,
                            (v) => setState(() => showSignature = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Section 6: Apply to Locations
                      ExpansionTile(
                        shape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        collapsedShape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        title: Text(
                          l10n.translate('invoice_template.applied_locations'),
                          style: AppTextStyles.titleMedium,
                        ),
                        children: [
                          BlocBuilder<LocationBloc, LocationState>(
                            builder: (context, locState) {
                              if (locState is LocationsLoaded) {
                                return Wrap(
                                  spacing: 8,
                                  children: locState.locations.map((loc) {
                                    final isSelected = _appliedLocations
                                        .contains(loc.id);
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
                                      selectedColor: AppColors.secondary
                                          .withValues(alpha: 0.2),
                                      checkmarkColor: AppColors.secondary,
                                    );
                                  }).toList(),
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
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
                        onPressed: state is InvoiceTemplateSaveInProgress
                            ? null
                            : _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: state is InvoiceTemplateSaveInProgress
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                l10n.translate('invoice_template.save'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTemplateCard(String id, IconData icon, String title) {
    bool isSelected = _selectedTemplate == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedTemplate = id),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.secondary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.secondary : Colors.grey.shade600,
            ),
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
