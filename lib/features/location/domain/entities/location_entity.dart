/// Business Location Entity
class LocationEntity {
  final String id;
  final String name;
  final String address;
  final String managerId;
  final String managerName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocationEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.managerId,
    required this.managerName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  LocationEntity copyWith({
    String? id,
    String? name,
    String? address,
    String? managerId,
    String? managerName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
