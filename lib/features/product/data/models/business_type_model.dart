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
    return BusinessTypeDto(
      businessTypeId: json['businessTypeId'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
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
