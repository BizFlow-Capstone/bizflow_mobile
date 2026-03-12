import '../domain/entities/invoice_template_entity.dart';
import 'models/invoice_template_dto.dart';

abstract class InvoiceTemplateRepository {
  Future<InvoiceTemplateEntity> getInvoiceTemplate();
  Future<InvoiceTemplateEntity> updateInvoiceTemplate(UpdateInvoiceTemplateRequestDto request);
}

class InvoiceTemplateRepositoryMock implements InvoiceTemplateRepository {
  // In-memory mock storage
  InvoiceTemplateEntity _mockTemplate = const InvoiceTemplateEntity(
    id: 'tpl_001',
    businessName: 'Hộ Kinh Doanh TNHH ABC',
    businessAddress: '123 Đường Lê Lợi, Quận 1, TP.HCM',
    businessPhone: '0900123456',
    businessEmail: 'info@abc.com',
    businessTaxCode: '0123456789',
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
    footerNoteText: 'Cảm ơn quý khách...',
    primaryColor: '#000000',
    secondaryColor: '#000000',
    appliedLocationIds: [], // Empty initially
  );

  @override
  Future<InvoiceTemplateEntity> getInvoiceTemplate() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockTemplate;
  }

  @override
  Future<InvoiceTemplateEntity> updateInvoiceTemplate(UpdateInvoiceTemplateRequestDto request) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
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

    return _mockTemplate;
  }
}
