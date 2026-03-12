class UpdateInvoiceTemplateRequestDto {
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessEmail;
  final String businessTaxCode;
  final String businessLogoUrl;
  
  final String templateType;

  final bool showStt;
  final bool showItemName;
  final bool showQuantity;
  final bool showUnit;
  final bool showUnitPrice;
  final bool showItemDiscount;
  final bool showItemVat;
  final bool showItemTotalAmount;

  final bool showCustomerName;
  final bool showCustomerPhone;
  final bool showCustomerAddress;
  final bool showCustomerEmail;
  final bool showCustomerTaxCode;

  final bool showTotalVat;
  final bool showTotalDiscount;
  final bool showSubTotal;
  final bool showFooterNote;
  final bool showFooterTerms;
  final bool showSignature;
  
  final String footerNoteText;
  final String primaryColor;
  final String secondaryColor;

  final List<String> appliedLocationIds;

  UpdateInvoiceTemplateRequestDto({
    required this.businessName,
    required this.businessAddress,
    required this.businessPhone,
    required this.businessEmail,
    required this.businessTaxCode,
    required this.businessLogoUrl,
    required this.templateType,
    required this.showStt,
    required this.showItemName,
    required this.showQuantity,
    required this.showUnit,
    required this.showUnitPrice,
    required this.showItemDiscount,
    required this.showItemVat,
    required this.showItemTotalAmount,
    required this.showCustomerName,
    required this.showCustomerPhone,
    required this.showCustomerAddress,
    required this.showCustomerEmail,
    required this.showCustomerTaxCode,
    required this.showTotalVat,
    required this.showTotalDiscount,
    required this.showSubTotal,
    required this.showFooterNote,
    required this.showFooterTerms,
    required this.showSignature,
    required this.footerNoteText,
    required this.primaryColor,
    required this.secondaryColor,
    required this.appliedLocationIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'businessEmail': businessEmail,
      'businessTaxCode': businessTaxCode,
      'businessLogoUrl': businessLogoUrl,
      'templateType': templateType,
      'showStt': showStt,
      'showItemName': showItemName,
      'showQuantity': showQuantity,
      'showUnit': showUnit,
      'showUnitPrice': showUnitPrice,
      'showItemDiscount': showItemDiscount,
      'showItemVat': showItemVat,
      'showItemTotalAmount': showItemTotalAmount,
      'showCustomerName': showCustomerName,
      'showCustomerPhone': showCustomerPhone,
      'showCustomerAddress': showCustomerAddress,
      'showCustomerEmail': showCustomerEmail,
      'showCustomerTaxCode': showCustomerTaxCode,
      'showTotalVat': showTotalVat,
      'showTotalDiscount': showTotalDiscount,
      'showSubTotal': showSubTotal,
      'showFooterNote': showFooterNote,
      'showFooterTerms': showFooterTerms,
      'showSignature': showSignature,
      'footerNoteText': footerNoteText,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'appliedLocationIds': appliedLocationIds,
    };
  }
}
