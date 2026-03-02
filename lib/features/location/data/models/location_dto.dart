/// Location Response DTO - Maps API response to domain entity
class LocationResponseDto {
  final bool success;
  final String messageCode;
  final String message;
  final String timestamp;
  final List<LocationDto> data;

  LocationResponseDto({
    required this.success,
    required this.messageCode,
    required this.message,
    required this.timestamp,
    required this.data,
  });

  /// From JSON
  factory LocationResponseDto.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return LocationResponseDto(
      success: json['success'] as bool? ?? false,
      messageCode: json['messageCode'] as String? ?? '',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      data: dataList
          .map((item) => LocationDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Location DTO - Data Transfer Object for single location
class LocationDto {
  final int id;
  final String name;
  final String address;
  final String district;
  final String city;
  final String phone;
  final bool isActive;
  final String ownerName;
  final String? taxCode; // Optional - for create/update
  final List<String> employeeIds; // Employee IDs assigned to this location

  LocationDto({
    required this.id,
    required this.name,
    required this.address,
    required this.district,
    required this.city,
    required this.phone,
    required this.isActive,
    required this.ownerName,
    this.taxCode,
    this.employeeIds = const [],
  });

  /// From JSON
  factory LocationDto.fromJson(Map<String, dynamic> json) {
    // Handle id as either int or String from API
    final dynamic idValue = json['id'];
    final int parsedId = idValue is int
        ? idValue
        : (idValue is String ? int.tryParse(idValue) ?? 0 : 0);

    // Parse employeeIds from array (API might return employee objects or IDs)
    final List<String> employeeIds = [];
    final employees = json['employees'] as List<dynamic>?;
    if (employees != null) {
      employeeIds.addAll(
        employees
            .map(
              (e) => e is Map
                  ? (e['userId'] ?? e['id'] ?? '').toString()
                  : e.toString(),
            )
            .where((id) => id.isNotEmpty),
      );
    }

    return LocationDto(
      id: parsedId,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      district: json['district'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      ownerName: json['ownerName'] as String? ?? '',
      taxCode: json['taxCode'] as String?,
      employeeIds: employeeIds,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'district': district,
      'city': city,
      'phone': phone,
      'isActive': isActive,
      'ownerName': ownerName,
      if (taxCode != null) 'taxCode': taxCode,
      'employeeIds': employeeIds,
    };
  }
}

/// Create Location Request DTO
class CreateLocationRequestDto {
  final String name;
  final String address;
  final String district;
  final String city;
  final String phone;
  final String taxCode;
  final List<String> employeeIds;

  CreateLocationRequestDto({
    required this.name,
    required this.address,
    required this.district,
    required this.city,
    required this.phone,
    required this.taxCode,
    required this.employeeIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'district': district,
      'city': city,
      'phone': phone,
      'taxCode': taxCode,
      'employeeIds': employeeIds,
    };
  }
}

/// Update Location Request DTO
class UpdateLocationRequestDto {
  final String name;
  final String address;
  final String district;
  final String city;
  final String phone;
  final String taxCode;

  UpdateLocationRequestDto({
    required this.name,
    required this.address,
    required this.district,
    required this.city,
    required this.phone,
    required this.taxCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'district': district,
      'city': city,
      'phone': phone,
      'taxCode': taxCode,
    };
  }
}

/// Update Status Request DTO
class UpdateStatusRequestDto {
  final bool isActive;

  UpdateStatusRequestDto({required this.isActive});

  Map<String, dynamic> toJson() => {'isActive': isActive};
}
