import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/entities/invoice_template_entity.dart';
import 'models/invoice_template_dto.dart';

abstract class InvoiceTemplateRepository {
  Future<InvoiceTemplateEntity> getInvoiceTemplate();
  Future<InvoiceTemplateEntity> updateInvoiceTemplate(
    UpdateInvoiceTemplateRequestDto request,
  );
}

class InvoiceTemplateRepositoryMock implements InvoiceTemplateRepository {
  InvoiceTemplateRepositoryMock({
    AppDatabase? database,
  }) : _database = database ?? AppDatabase();

  final AppDatabase _database;

  static const InvoiceTemplateEntity _defaultTemplate = InvoiceTemplateEntity(
    id: 'tpl_001',
    businessName: '',
    businessAddress: '',
    businessPhone: '',
    businessEmail: '',
    businessTaxCode: '',
    businessLogoUrl: '',
    templateType: 'basic',
    showStt: true,
    showItemName: true,
    showQuantity: true,
    showUnit: true,
    showUnitPrice: true,
    showItemDiscount: false,
    showItemVat: false,
    showItemTotalAmount: true,
    showCustomerName: true,
    showCustomerPhone: true,
    showCustomerAddress: true,
    showCustomerEmail: false,
    showCustomerTaxCode: false,
    showTotalVat: false,
    showTotalDiscount: false,
    showSubTotal: false,
    showFooterNote: true,
    showFooterTerms: false,
    showSignature: false,
    footerNoteText: 'Cảm ơn quý khách và hẹn gặp lại!',
    primaryColor: '#000000',
    secondaryColor: '#000000',
    appliedLocationIds: [],
  );

  Future<String> _resolveAccountScope() async {
    final storage = await LocalStorage.getInstance();
    final email = (storage.getString(StorageKeys.currentUserEmail) ?? '')
        .trim()
        .toLowerCase();
    if (email.isNotEmpty) {
      return 'email:$email';
    }

    final phone = (storage.getString(StorageKeys.currentUserPhone) ?? '').trim();
    if (phone.isNotEmpty) {
      return 'phone:$phone';
    }

    final fullName = (storage.getString(StorageKeys.currentUserFullName) ?? '')
        .trim()
        .toLowerCase();
    if (fullName.isNotEmpty) {
      return 'name:$fullName';
    }

    return 'anonymous';
  }

  @override
  Future<InvoiceTemplateEntity> getInvoiceTemplate() async {
    final accountScope = await _resolveAccountScope();
    final row = await _database.invoiceTemplateSettingsDao.getByAccountScope(
      accountScope,
    );

    if (row == null) {
      return _defaultTemplate;
    }

    try {
      final decoded = jsonDecode(row.payloadJson);
      if (decoded is Map<String, dynamic>) {
        return InvoiceTemplateEntity.fromMap(decoded);
      }
      return _defaultTemplate;
    } catch (_) {
      return _defaultTemplate;
    }
  }

  @override
  Future<InvoiceTemplateEntity> updateInvoiceTemplate(
    UpdateInvoiceTemplateRequestDto request,
  ) async {
    final accountScope = await _resolveAccountScope();
    final current = await getInvoiceTemplate();

    final updatedTemplate = current.copyWith(
      businessName: request.businessName,
      businessAddress: request.businessAddress,
      businessPhone: request.businessPhone,
      businessEmail: request.businessEmail,
      businessTaxCode: request.businessTaxCode,
      businessLogoUrl: request.businessLogoUrl,
      templateType: request.templateType,
      showStt: request.showStt,
      showItemName: request.showItemName,
      showQuantity: request.showQuantity,
      showUnit: request.showUnit,
      showUnitPrice: request.showUnitPrice,
      showItemDiscount: request.showItemDiscount,
      showItemVat: request.showItemVat,
      showItemTotalAmount: request.showItemTotalAmount,
      showCustomerName: request.showCustomerName,
      showCustomerPhone: request.showCustomerPhone,
      showCustomerAddress: request.showCustomerAddress,
      showCustomerEmail: request.showCustomerEmail,
      showCustomerTaxCode: request.showCustomerTaxCode,
      showTotalVat: request.showTotalVat,
      showTotalDiscount: request.showTotalDiscount,
      showSubTotal: request.showSubTotal,
      showFooterNote: request.showFooterNote,
      showFooterTerms: request.showFooterTerms,
      showSignature: request.showSignature,
      footerNoteText: request.footerNoteText,
      primaryColor: request.primaryColor,
      secondaryColor: request.secondaryColor,
      appliedLocationIds: request.appliedLocationIds,
    );

    await _database.invoiceTemplateSettingsDao.upsert(
      accountScope: accountScope,
      payloadJson: jsonEncode(updatedTemplate.toMap()),
      updatedAtEpoch: DateTime.now().millisecondsSinceEpoch,
    );

    return updatedTemplate;
  }
}
