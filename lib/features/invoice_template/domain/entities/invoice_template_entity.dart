import 'package:equatable/equatable.dart';

class InvoiceTemplateEntity extends Equatable {
  final String id;
  // business info
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessEmail;
  final String businessTaxCode;
  final String businessLogoUrl;
  
  // template choice
  final String templateType; // basic, professional, retail, fnb, service, repair

  // table columns config
  final bool showStt;
  final bool showItemName;
  final bool showQuantity;
  final bool showUnit;
  final bool showUnitPrice;
  final bool showItemDiscount;
  final bool showItemVat;
  final bool showItemTotalAmount;

  // customer info config
  final bool showCustomerName;
  final bool showCustomerPhone;
  final bool showCustomerAddress;
  final bool showCustomerEmail;
  final bool showCustomerTaxCode;

  // display options config
  final bool showTotalVat;
  final bool showTotalDiscount;
  final bool showSubTotal;
  final bool showFooterNote;
  final bool showFooterTerms;
  final bool showSignature;
  
  final String footerNoteText;
  final String primaryColor;
  final String secondaryColor;

  // Locations applied
  final List<String> appliedLocationIds;

  const InvoiceTemplateEntity({
    required this.id,
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

  InvoiceTemplateEntity copyWith({
    String? id,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    String? businessTaxCode,
    String? businessLogoUrl,
    String? templateType,
    bool? showStt,
    bool? showItemName,
    bool? showQuantity,
    bool? showUnit,
    bool? showUnitPrice,
    bool? showItemDiscount,
    bool? showItemVat,
    bool? showItemTotalAmount,
    bool? showCustomerName,
    bool? showCustomerPhone,
    bool? showCustomerAddress,
    bool? showCustomerEmail,
    bool? showCustomerTaxCode,
    bool? showTotalVat,
    bool? showTotalDiscount,
    bool? showSubTotal,
    bool? showFooterNote,
    bool? showFooterTerms,
    bool? showSignature,
    String? footerNoteText,
    String? primaryColor,
    String? secondaryColor,
    List<String>? appliedLocationIds,
  }) {
    return InvoiceTemplateEntity(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      businessTaxCode: businessTaxCode ?? this.businessTaxCode,
      businessLogoUrl: businessLogoUrl ?? this.businessLogoUrl,
      templateType: templateType ?? this.templateType,
      showStt: showStt ?? this.showStt,
      showItemName: showItemName ?? this.showItemName,
      showQuantity: showQuantity ?? this.showQuantity,
      showUnit: showUnit ?? this.showUnit,
      showUnitPrice: showUnitPrice ?? this.showUnitPrice,
      showItemDiscount: showItemDiscount ?? this.showItemDiscount,
      showItemVat: showItemVat ?? this.showItemVat,
      showItemTotalAmount: showItemTotalAmount ?? this.showItemTotalAmount,
      showCustomerName: showCustomerName ?? this.showCustomerName,
      showCustomerPhone: showCustomerPhone ?? this.showCustomerPhone,
      showCustomerAddress: showCustomerAddress ?? this.showCustomerAddress,
      showCustomerEmail: showCustomerEmail ?? this.showCustomerEmail,
      showCustomerTaxCode: showCustomerTaxCode ?? this.showCustomerTaxCode,
      showTotalVat: showTotalVat ?? this.showTotalVat,
      showTotalDiscount: showTotalDiscount ?? this.showTotalDiscount,
      showSubTotal: showSubTotal ?? this.showSubTotal,
      showFooterNote: showFooterNote ?? this.showFooterNote,
      showFooterTerms: showFooterTerms ?? this.showFooterTerms,
      showSignature: showSignature ?? this.showSignature,
      footerNoteText: footerNoteText ?? this.footerNoteText,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      appliedLocationIds: appliedLocationIds ?? this.appliedLocationIds,
    );
  }

  factory InvoiceTemplateEntity.empty() {
    return const InvoiceTemplateEntity(
      id: '',
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
      showFooterNote: false,
      showFooterTerms: false,
      showSignature: false,
      footerNoteText: '',
      primaryColor: '#000000',
      secondaryColor: '#000000',
      appliedLocationIds: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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

  factory InvoiceTemplateEntity.fromMap(Map<String, dynamic> map) {
    return InvoiceTemplateEntity(
      id: map['id'] ?? '',
      businessName: map['businessName'] ?? '',
      businessAddress: map['businessAddress'] ?? '',
      businessPhone: map['businessPhone'] ?? '',
      businessEmail: map['businessEmail'] ?? '',
      businessTaxCode: map['businessTaxCode'] ?? '',
      businessLogoUrl: map['businessLogoUrl'] ?? '',
      templateType: map['templateType'] ?? 'basic',
      showStt: map['showStt'] ?? true,
      showItemName: map['showItemName'] ?? true,
      showQuantity: map['showQuantity'] ?? true,
      showUnit: map['showUnit'] ?? true,
      showUnitPrice: map['showUnitPrice'] ?? true,
      showItemDiscount: map['showItemDiscount'] ?? false,
      showItemVat: map['showItemVat'] ?? false,
      showItemTotalAmount: map['showItemTotalAmount'] ?? true,
      showCustomerName: map['showCustomerName'] ?? true,
      showCustomerPhone: map['showCustomerPhone'] ?? true,
      showCustomerAddress: map['showCustomerAddress'] ?? true,
      showCustomerEmail: map['showCustomerEmail'] ?? false,
      showCustomerTaxCode: map['showCustomerTaxCode'] ?? false,
      showTotalVat: map['showTotalVat'] ?? false,
      showTotalDiscount: map['showTotalDiscount'] ?? false,
      showSubTotal: map['showSubTotal'] ?? false,
      showFooterNote: map['showFooterNote'] ?? false,
      showFooterTerms: map['showFooterTerms'] ?? false,
      showSignature: map['showSignature'] ?? false,
      footerNoteText: map['footerNoteText'] ?? '',
      primaryColor: map['primaryColor'] ?? '#000000',
      secondaryColor: map['secondaryColor'] ?? '#000000',
      appliedLocationIds: List<String>.from(map['appliedLocationIds'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
        id,
        businessName,
        businessAddress,
        businessPhone,
        businessEmail,
        businessTaxCode,
        businessLogoUrl,
        templateType,
        showStt,
        showItemName,
        showQuantity,
        showUnit,
        showUnitPrice,
        showItemDiscount,
        showItemVat,
        showItemTotalAmount,
        showCustomerName,
        showCustomerPhone,
        showCustomerAddress,
        showCustomerEmail,
        showCustomerTaxCode,
        showTotalVat,
        showTotalDiscount,
        showSubTotal,
        showFooterNote,
        showFooterTerms,
        showSignature,
        footerNoteText,
        primaryColor,
        secondaryColor,
        appliedLocationIds,
      ];
}
