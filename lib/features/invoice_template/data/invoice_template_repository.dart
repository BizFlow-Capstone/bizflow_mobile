import '../../../core/storage/local_storage.dart';
import '../domain/entities/invoice_template_entity.dart';
import 'models/invoice_template_dto.dart';

abstract class InvoiceTemplateRepository {
  Future<InvoiceTemplateEntity> getInvoiceTemplate();
  Future<InvoiceTemplateEntity> updateInvoiceTemplate(UpdateInvoiceTemplateRequestDto request);
}

class InvoiceTemplateRepositoryMock implements InvoiceTemplateRepository {
  static const String _storageKey = 'mock_invoice_template';

  InvoiceTemplateEntity _mockTemplate = const InvoiceTemplateEntity(
    id: 'tpl_001',
    businessName: '', // Empty initially for auto-fill
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

  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    final storage = await LocalStorage.getInstance();
    final saved = storage.getObject(_storageKey);
    if (saved != null) {
      _mockTemplate = InvoiceTemplateEntity.fromMap(saved);
    }
    _isInitialized = true;
  }

  @override
  Future<InvoiceTemplateEntity> getInvoiceTemplate() async {
    await _ensureInitialized();
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockTemplate;
  }

  @override
  Future<InvoiceTemplateEntity> updateInvoiceTemplate(
      UpdateInvoiceTemplateRequestDto request) async {
    await _ensureInitialized();
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    _mockTemplate = _mockTemplate.copyWith(
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

    final storage = await LocalStorage.getInstance();
    await storage.setObject(_storageKey, _mockTemplate.toMap());

    return _mockTemplate;
  }
}
