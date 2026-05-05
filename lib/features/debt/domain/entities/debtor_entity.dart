import '../../../../shared/utils/date_formatter.dart';

class DebtorEntity {
  final int debtorId;
  final int businessLocationId;
  final String businessLocationName;
  final String name;
  final String phone;
  final String? address;
  final String? notes;
  final double creditLimit;
  final double currentBalance;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DebtorEntity({
    required this.debtorId,
    required this.businessLocationId,
    required this.businessLocationName,
    required this.name,
    required this.phone,
    this.address,
    this.notes,
    required this.creditLimit,
    required this.currentBalance,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  DebtorEntity copyWith({
    int? debtorId,
    int? businessLocationId,
    String? businessLocationName,
    String? name,
    String? phone,
    String? address,
    String? notes,
    double? creditLimit,
    double? currentBalance,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DebtorEntity(
      debtorId: debtorId ?? this.debtorId,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      businessLocationName: businessLocationName ?? this.businessLocationName,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DebtorEntity.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    DateTime? toDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        return DateFormatter.parseApiDateTime(value);
      }
      return null;
    }

    int toInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    Map<String, dynamic>? toMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return value.map((key, val) => MapEntry(key.toString(), val));
      }
      return null;
    }

    final locationMap = toMap(map['businessLocation'] ?? map['location']);

    final businessLocationId = toInt(map['businessLocationId']) > 0
        ? toInt(map['businessLocationId'])
        : toInt(locationMap?['businessLocationId']) > 0
        ? toInt(locationMap?['businessLocationId'])
        : toInt(locationMap?['id']);

    final businessLocationName =
        (map['businessLocationName'] ??
                map['locationName'] ??
                locationMap?['name'] ??
                locationMap?['locationName'] ??
                '')
            .toString();

    final address =
        (map['address'] ??
                map['debtorAddress'] ??
                map['customerAddress'] ??
                locationMap?['address'] ??
                locationMap?['fullAddress'])
            ?.toString();

    return DebtorEntity(
      debtorId: (map['debtorId'] as num?)?.toInt() ?? 0,
      businessLocationId: businessLocationId,
      businessLocationName: businessLocationName,
      name: (map['name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      address: address,
      notes: map['notes']?.toString(),
      creditLimit: toDouble(map['creditLimit']),
      currentBalance: toDouble(map['currentBalance']),
      isActive: map['isActive'] == true || map['status'] == 'ACTIVE',
      createdAt: toDate(map['createdAt']),
      updatedAt: toDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'debtorId': debtorId,
      'businessLocationId': businessLocationId,
      'businessLocationName': businessLocationName,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'creditLimit': creditLimit,
      'currentBalance': currentBalance,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? DateFormatter.toApiUtcIsoString(createdAt!)
          : null,
      'updatedAt': updatedAt != null
          ? DateFormatter.toApiUtcIsoString(updatedAt!)
          : null,
    };
  }
}
