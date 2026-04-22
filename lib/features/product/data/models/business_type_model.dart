import '../../../../core/reference/data/reference_item.dart';

class BusinessTypeDto {
  final String businessTypeId;
  final String code;
  final String name;
  final String description;
  final String status;

  BusinessTypeDto({
    required this.businessTypeId,
    required this.code,
    required this.name,
    required this.description,
    required this.status,
  });

  factory BusinessTypeDto.fromJson(Map<String, dynamic> json) {
    String asString(dynamic value, {String fallback = ''}) {
      final normalized = value?.toString().trim();
      if (normalized == null || normalized.isEmpty) return fallback;
      return normalized;
    }

    final rawBusinessTypeId =
        json['businessTypeId'] ?? json['BusinessTypeId'] ?? json['id'];
    final rawCode = json['code'] ?? json['Code'] ?? rawBusinessTypeId;
    final rawName = json['name'] ?? json['Name'] ?? json['label'];
    final rawStatus = json['status'] ?? json['Status'];

    final businessTypeIdCode = referenceCodeFromDynamic(rawBusinessTypeId);
    final codeValue = referenceCodeFromDynamic(rawCode);
    final nameValue = referenceLabelFromDynamic(rawName) ?? asString(rawName);

    return BusinessTypeDto(
      businessTypeId: businessTypeIdCode.isNotEmpty
          ? businessTypeIdCode
          : asString(rawBusinessTypeId),
      code: codeValue.isNotEmpty ? codeValue : asString(rawCode),
      name: nameValue,
      description: asString(json['description'] ?? json['Description']),
      status: (() {
        final statusCode = referenceCodeFromDynamic(rawStatus).trim();
        if (statusCode.isNotEmpty) return statusCode;
        final statusText = asString(rawStatus, fallback: 'active').toLowerCase();
        return statusText.isEmpty ? 'active' : statusText;
      })(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessTypeId': businessTypeId,
      'code': code,
      'name': name,
      'description': description,
      'status': status,
    };
  }
}
