/// Business Location Entity
///
/// Domain model - represents business location in clean architecture
/// This is used by BLoC and UI layers
class LocationEntity {
  final String id;
  final String name;
  final String address;
  final String district;
  final String city;
  final String phone;
  final bool isActive;
  final String ownerName;
  final String? taxCode; // Optional
  final List<String> employeeIds; // Employee IDs assigned to this location
  final bool isOwner; // true = current user owns this location

  LocationEntity({
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
    this.isOwner = false,
  });

  /// Full address (combined)
  String get fullAddress => '$address, $district, $city';

  LocationEntity copyWith({
    String? id,
    String? name,
    String? address,
    String? district,
    String? city,
    String? phone,
    bool? isActive,
    String? ownerName,
    String? taxCode,
    List<String>? employeeIds,
    bool? isOwner,
  }) {
    return LocationEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      district: district ?? this.district,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      ownerName: ownerName ?? this.ownerName,
      taxCode: taxCode ?? this.taxCode,
      employeeIds: employeeIds ?? this.employeeIds,
      isOwner: isOwner ?? this.isOwner,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'district': district,
      'city': city,
      'phone': phone,
      'isActive': isActive,
      'ownerName': ownerName,
      'taxCode': taxCode,
      'employeeIds': employeeIds,
      'isOwner': isOwner,
    };
  }

  factory LocationEntity.fromMap(Map<String, dynamic> map) {
    return LocationEntity(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      district: map['district'] ?? '',
      city: map['city'] ?? '',
      phone: map['phone'] ?? '',
      isActive: map['isActive'] ?? false,
      ownerName: map['ownerName'] ?? '',
      taxCode: map['taxCode'],
      employeeIds: List<String>.from(map['employeeIds'] ?? []),
      isOwner: map['isOwner'] ?? false,
    );
  }
}
