import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../../debt/presentation/bloc/debtor_bloc.dart';
import '../../../debt/presentation/bloc/debtor_event.dart';
import '../../../debt/presentation/bloc/debtor_state.dart';
import '../../../debt/domain/entities/debtor_entity.dart';
import 'order_payment_option_screen.dart';

class OrderFormScreen extends StatefulWidget {
  final String inputType; // 'audio', 'voice', or 'manual'

  const OrderFormScreen({super.key, required this.inputType});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  String _customerType = 'walkin'; // walkin | debtor
  DebtorEntity? _selectedDebtor;
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  bool _isCreatingDebtorProfile = false;

  static const int _phoneLength = 10;

  // Example dummy products obtained from voice/audio processing
  final List<Map<String, dynamic>> _mockProducts = [
    {"name": "iPhone 15 Pro Max", "price": 30000000.0, "quantity": 1},
    {"name": "Ốp lưng iPhone", "price": 150000.0, "quantity": 1},
  ];

  @override
  void initState() {
    super.initState();
    final locationId = int.tryParse(BusinessContext().currentBusinessId ?? '');
    if (locationId != null && locationId > 0) {
      context.read<DebtorBloc>().add(
        LoadActiveDebtorsByLocationRequested(locationId: locationId),
      );
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLocationName =
        BusinessContext().currentBusinessName ??
        l10n.translate('common.no_data');

    double subTotal = _mockProducts.fold(
      0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );
    double tax = subTotal * 0.1;
    double total = subTotal + tax;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('order_create.form_title')),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () {
              // Save as draft and pop to home
              Navigator.popUntil(context, ModalRoute.withName('/home'));
              // In real app, we'd trigger Bloc action here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.translate('order_create.save_draft')),
                ),
              );
            },
            child: Text(
              l10n.translate('order_create.save_draft'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
        bottom: const AppSyncStatusText(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Business Location
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.store, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.translate('order_create.business_location'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[800],
                              ),
                            ),
                            Text(
                              currentLocationName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Customer Info Section
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('order_create.customer_type'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: Text(
                                  l10n.translate(
                                    'order_create.customer_walkin',
                                  ),
                                ),
                                selected: _customerType == 'walkin',
                                onSelected: (_) {
                                  setState(() {
                                    _customerType = 'walkin';
                                    _selectedDebtor = null;
                                    _customerNameController.clear();
                                    _customerPhoneController.clear();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: Text(
                                  l10n.translate('order_create.customer_loyal'),
                                ),
                                selected: _customerType == 'debtor',
                                onSelected: (_) {
                                  setState(() {
                                    _customerType = 'debtor';
                                  });

                                  final locationId = int.tryParse(
                                    BusinessContext().currentBusinessId ?? '',
                                  );
                                  if (locationId != null && locationId > 0) {
                                    context.read<DebtorBloc>().add(
                                      LoadActiveDebtorsByLocationRequested(
                                        locationId: locationId,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_customerType == 'debtor')
                          BlocBuilder<DebtorBloc, DebtorState>(
                            builder: (context, debtState) {
                              final debtors = debtState.activeDebtorsByLocation;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _openDebtorPicker(debtors),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: l10n.translate(
                                          'debt.select_debtor',
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.person_search,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _selectedDebtor == null
                                                  ? l10n.translate(
                                                      'debt.select_debtor',
                                                    )
                                                  : '${_selectedDebtor!.name} - ${_selectedDebtor!.phone}',
                                              style: TextStyle(
                                                color: _selectedDebtor == null
                                                    ? Colors.grey[600]
                                                    : Colors.black,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_selectedDebtor != null) ...[
                                    const SizedBox(height: 12),
                                    _buildReadOnlyCustomerField(
                                      label: l10n.translate(
                                        'order_create.customer_name',
                                      ),
                                      icon: Icons.person,
                                      value: _selectedDebtor!.name,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildReadOnlyCustomerField(
                                      label: l10n.translate(
                                        'order_create.customer_phone',
                                      ),
                                      icon: Icons.phone,
                                      value: _selectedDebtor!.phone,
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        if (_customerType == 'walkin') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isCreatingDebtorProfile
                                  ? null
                                  : _showCreateDebtProfileDialog,
                              icon: _isCreatingDebtorProfile
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.person_add_alt_1),
                              label: Text(
                                l10n.translate(
                                  'order_create.create_debt_profile',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Product Info Section
                Text(
                  l10n.translate('order_create.form_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                ..._mockProducts.map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(p['name']),
                    subtitle: Text(
                      '${CurrencyFormatter.formatVND((p['price'] as num).toDouble())} x ${p['quantity']}',
                    ),
                    trailing: Text(
                      CurrencyFormatter.formatVND(
                        ((p['price'] as num).toDouble()) *
                            ((p['quantity'] as num).toDouble()),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: Text(l10n.translate('order_create.add_product')),
                ),

                const SizedBox(height: 24),

                // Summary Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.translate('order_create.sub_total')),
                    Text(CurrencyFormatter.formatVND(subTotal)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.translate('order_create.tax')),
                    Text(CurrencyFormatter.formatVND(tax)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.translate('order_create.total'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatVND(total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              if (_customerType == 'debtor' && _selectedDebtor == null) {
                AppSnackBar.show(
                  context,
                  message: l10n.translate(
                    'order_create.select_debtor_required',
                  ),
                  type: AppSnackBarType.warning,
                );
                return;
              }

              final customerName = _customerType == 'debtor'
                  ? (_selectedDebtor?.name ?? '')
                  : '';
              final customerPhone = _customerType == 'debtor'
                  ? (_selectedDebtor?.phone ?? '')
                  : '';

              final locationId = int.tryParse(
                BusinessContext().currentBusinessId ?? '',
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderPaymentOptionScreen(
                    totalAmount: total,
                    debtorId: _customerType == 'debtor'
                        ? _selectedDebtor?.debtorId
                        : null,
                    debtorName: _customerType == 'debtor'
                        ? _selectedDebtor?.name
                        : null,
                    customerName: customerName,
                    customerPhone: customerPhone,
                    locationId: locationId,
                    locationName: BusinessContext().currentBusinessName,
                  ),
                ),
              );
            },
            child: Text(
              l10n.translate('order_create.proceed_payment'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateDebtProfileDialog() async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();
    final creditLimitController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.translate('debt.create_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('order_create.customer_name'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_phoneLength),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.translate('order_create.customer_phone'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('debt.address'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('debt.note'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: creditLimitController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.translate('debt.credit_limit'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.translate('common.save')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _createDebtProfile(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      notes: notesController.text.trim(),
      creditLimitText: creditLimitController.text.trim(),
    );
  }

  Future<void> _createDebtProfile({
    required String name,
    required String phone,
    required String address,
    required String notes,
    required String creditLimitText,
  }) async {
    final l10n = AppLocalizations.of(context);
    final locationId = int.tryParse(BusinessContext().currentBusinessId ?? '');
    final customerName = name;
    final customerPhone = phone;
    final creditLimit = creditLimitText.isEmpty
        ? null
        : double.tryParse(creditLimitText.replaceAll(',', ''));

    if (locationId == null || locationId <= 0) {
      AppSnackBar.show(
        context,
        message: l10n.translate('debt.location_required'),
        type: AppSnackBarType.warning,
      );
      return;
    }

    if (customerName.isEmpty) {
      AppSnackBar.show(
        context,
        message: l10n.translate('order_create.customer_name_required'),
        type: AppSnackBarType.warning,
      );
      return;
    }

    if (customerPhone.isNotEmpty && customerPhone.length != _phoneLength) {
      AppSnackBar.show(
        context,
        message: l10n.translate('order_create.phone_invalid'),
        type: AppSnackBarType.warning,
      );
      return;
    }

    setState(() => _isCreatingDebtorProfile = true);
    try {
      final repository = context.read<DebtorBloc>().repository;
      final createdDebtor = await repository.createDebtor(
        businessLocationId: locationId,
        name: customerName,
        phone: customerPhone.isEmpty ? null : customerPhone,
        address: address.isEmpty ? null : address,
        notes: notes.isEmpty ? null : notes,
        creditLimit: creditLimit,
      );

      if (!mounted) return;
      if (createdDebtor == null || createdDebtor.debtorId <= 0) {
        AppSnackBar.show(
          context,
          message: l10n.translate('debt.create_failed'),
          type: AppSnackBarType.error,
        );
        return;
      }

      context.read<DebtorBloc>().add(
        LoadActiveDebtorsByLocationRequested(locationId: locationId),
      );

      setState(() {
        _customerType = 'debtor';
        _selectedDebtor = createdDebtor;
        _customerNameController.text = createdDebtor.name;
        _customerPhoneController.text = createdDebtor.phone;
      });

      AppSnackBar.show(
        context,
        message: l10n.translate('order_create.debt_profile_created'),
        type: AppSnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isCreatingDebtorProfile = false);
    }
  }

  Widget _buildReadOnlyCustomerField({
    required String label,
    required IconData icon,
    required String value,
  }) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      child: Text(value),
    );
  }

  Future<void> _openDebtorPicker(List<DebtorEntity> debtors) async {
    final l10n = AppLocalizations.of(context);
    final searchController = TextEditingController();

    final DebtorEntity? picked = await showModalBottomSheet<DebtorEntity>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final keyword = searchController.text.trim();
            final filtered = keyword.isEmpty
                ? debtors
                : debtors
                      .where((debtor) => debtor.phone.contains(keyword))
                      .toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('debt.select_debtor'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: l10n.translate(
                            'order_create.search_debtor_phone_dropdown',
                          ),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    setSheetState(() {});
                                  },
                                  icon: const Icon(Icons.close),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(l10n.translate('common.no_data')),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final debtor = filtered[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(debtor.name),
                                    subtitle: Text(debtor.phone),
                                    onTap: () =>
                                        Navigator.pop(sheetContext, debtor),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || picked == null) return;

    setState(() {
      _selectedDebtor = picked;
      _customerNameController.text = picked.name;
      _customerPhoneController.text = picked.phone;
    });
  }
}
