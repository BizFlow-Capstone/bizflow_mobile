// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocationsTableTable extends LocationsTable
    with TableInfo<$LocationsTableTable, LocationsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _districtMeta = const VerificationMeta(
    'district',
  );
  @override
  late final GeneratedColumn<String> district = GeneratedColumn<String>(
    'district',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ownerNameMeta = const VerificationMeta(
    'ownerName',
  );
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
    'owner_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ownerProfileIdMeta = const VerificationMeta(
    'ownerProfileId',
  );
  @override
  late final GeneratedColumn<String> ownerProfileId = GeneratedColumn<String>(
    'owner_profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taxCodeMeta = const VerificationMeta(
    'taxCode',
  );
  @override
  late final GeneratedColumn<String> taxCode = GeneratedColumn<String>(
    'tax_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _employeeIdsJsonMeta = const VerificationMeta(
    'employeeIdsJson',
  );
  @override
  late final GeneratedColumn<String> employeeIdsJson = GeneratedColumn<String>(
    'employee_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _isOwnerMeta = const VerificationMeta(
    'isOwner',
  );
  @override
  late final GeneratedColumn<bool> isOwner = GeneratedColumn<bool>(
    'is_owner',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_owner" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtEpochMeta = const VerificationMeta(
    'updatedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> updatedAtEpoch = GeneratedColumn<int>(
    'updated_at_epoch',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtEpochMeta = const VerificationMeta(
    'cachedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> cachedAtEpoch = GeneratedColumn<int>(
    'cached_at_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    address,
    district,
    city,
    phone,
    isActive,
    ownerName,
    ownerProfileId,
    taxCode,
    employeeIdsJson,
    isOwner,
    updatedAtEpoch,
    cachedAtEpoch,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'locations_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('district')) {
      context.handle(
        _districtMeta,
        district.isAcceptableOrUnknown(data['district']!, _districtMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('owner_name')) {
      context.handle(
        _ownerNameMeta,
        ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta),
      );
    }
    if (data.containsKey('owner_profile_id')) {
      context.handle(
        _ownerProfileIdMeta,
        ownerProfileId.isAcceptableOrUnknown(
          data['owner_profile_id']!,
          _ownerProfileIdMeta,
        ),
      );
    }
    if (data.containsKey('tax_code')) {
      context.handle(
        _taxCodeMeta,
        taxCode.isAcceptableOrUnknown(data['tax_code']!, _taxCodeMeta),
      );
    }
    if (data.containsKey('employee_ids_json')) {
      context.handle(
        _employeeIdsJsonMeta,
        employeeIdsJson.isAcceptableOrUnknown(
          data['employee_ids_json']!,
          _employeeIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_owner')) {
      context.handle(
        _isOwnerMeta,
        isOwner.isAcceptableOrUnknown(data['is_owner']!, _isOwnerMeta),
      );
    }
    if (data.containsKey('updated_at_epoch')) {
      context.handle(
        _updatedAtEpochMeta,
        updatedAtEpoch.isAcceptableOrUnknown(
          data['updated_at_epoch']!,
          _updatedAtEpochMeta,
        ),
      );
    }
    if (data.containsKey('cached_at_epoch')) {
      context.handle(
        _cachedAtEpochMeta,
        cachedAtEpoch.isAcceptableOrUnknown(
          data['cached_at_epoch']!,
          _cachedAtEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedAtEpochMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocationsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      district: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district'],
      )!,
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      ownerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_name'],
      )!,
      ownerProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_profile_id'],
      ),
      taxCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_code'],
      ),
      employeeIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_ids_json'],
      )!,
      isOwner: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_owner'],
      )!,
      updatedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_epoch'],
      ),
      cachedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at_epoch'],
      )!,
    );
  }

  @override
  $LocationsTableTable createAlias(String alias) {
    return $LocationsTableTable(attachedDatabase, alias);
  }
}

class LocationsTableData extends DataClass
    implements Insertable<LocationsTableData> {
  final String id;
  final String? businessId;
  final String name;
  final String address;
  final String district;
  final String city;
  final String phone;
  final bool isActive;
  final String ownerName;
  final String? ownerProfileId;
  final String? taxCode;
  final String employeeIdsJson;
  final bool isOwner;
  final int? updatedAtEpoch;
  final int cachedAtEpoch;
  const LocationsTableData({
    required this.id,
    this.businessId,
    required this.name,
    required this.address,
    required this.district,
    required this.city,
    required this.phone,
    required this.isActive,
    required this.ownerName,
    this.ownerProfileId,
    this.taxCode,
    required this.employeeIdsJson,
    required this.isOwner,
    this.updatedAtEpoch,
    required this.cachedAtEpoch,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || businessId != null) {
      map['business_id'] = Variable<String>(businessId);
    }
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    map['district'] = Variable<String>(district);
    map['city'] = Variable<String>(city);
    map['phone'] = Variable<String>(phone);
    map['is_active'] = Variable<bool>(isActive);
    map['owner_name'] = Variable<String>(ownerName);
    if (!nullToAbsent || ownerProfileId != null) {
      map['owner_profile_id'] = Variable<String>(ownerProfileId);
    }
    if (!nullToAbsent || taxCode != null) {
      map['tax_code'] = Variable<String>(taxCode);
    }
    map['employee_ids_json'] = Variable<String>(employeeIdsJson);
    map['is_owner'] = Variable<bool>(isOwner);
    if (!nullToAbsent || updatedAtEpoch != null) {
      map['updated_at_epoch'] = Variable<int>(updatedAtEpoch);
    }
    map['cached_at_epoch'] = Variable<int>(cachedAtEpoch);
    return map;
  }

  LocationsTableCompanion toCompanion(bool nullToAbsent) {
    return LocationsTableCompanion(
      id: Value(id),
      businessId: businessId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessId),
      name: Value(name),
      address: Value(address),
      district: Value(district),
      city: Value(city),
      phone: Value(phone),
      isActive: Value(isActive),
      ownerName: Value(ownerName),
      ownerProfileId: ownerProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerProfileId),
      taxCode: taxCode == null && nullToAbsent
          ? const Value.absent()
          : Value(taxCode),
      employeeIdsJson: Value(employeeIdsJson),
      isOwner: Value(isOwner),
      updatedAtEpoch: updatedAtEpoch == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAtEpoch),
      cachedAtEpoch: Value(cachedAtEpoch),
    );
  }

  factory LocationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String?>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      district: serializer.fromJson<String>(json['district']),
      city: serializer.fromJson<String>(json['city']),
      phone: serializer.fromJson<String>(json['phone']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      ownerName: serializer.fromJson<String>(json['ownerName']),
      ownerProfileId: serializer.fromJson<String?>(json['ownerProfileId']),
      taxCode: serializer.fromJson<String?>(json['taxCode']),
      employeeIdsJson: serializer.fromJson<String>(json['employeeIdsJson']),
      isOwner: serializer.fromJson<bool>(json['isOwner']),
      updatedAtEpoch: serializer.fromJson<int?>(json['updatedAtEpoch']),
      cachedAtEpoch: serializer.fromJson<int>(json['cachedAtEpoch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String?>(businessId),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'district': serializer.toJson<String>(district),
      'city': serializer.toJson<String>(city),
      'phone': serializer.toJson<String>(phone),
      'isActive': serializer.toJson<bool>(isActive),
      'ownerName': serializer.toJson<String>(ownerName),
      'ownerProfileId': serializer.toJson<String?>(ownerProfileId),
      'taxCode': serializer.toJson<String?>(taxCode),
      'employeeIdsJson': serializer.toJson<String>(employeeIdsJson),
      'isOwner': serializer.toJson<bool>(isOwner),
      'updatedAtEpoch': serializer.toJson<int?>(updatedAtEpoch),
      'cachedAtEpoch': serializer.toJson<int>(cachedAtEpoch),
    };
  }

  LocationsTableData copyWith({
    String? id,
    Value<String?> businessId = const Value.absent(),
    String? name,
    String? address,
    String? district,
    String? city,
    String? phone,
    bool? isActive,
    String? ownerName,
    Value<String?> ownerProfileId = const Value.absent(),
    Value<String?> taxCode = const Value.absent(),
    String? employeeIdsJson,
    bool? isOwner,
    Value<int?> updatedAtEpoch = const Value.absent(),
    int? cachedAtEpoch,
  }) => LocationsTableData(
    id: id ?? this.id,
    businessId: businessId.present ? businessId.value : this.businessId,
    name: name ?? this.name,
    address: address ?? this.address,
    district: district ?? this.district,
    city: city ?? this.city,
    phone: phone ?? this.phone,
    isActive: isActive ?? this.isActive,
    ownerName: ownerName ?? this.ownerName,
    ownerProfileId: ownerProfileId.present
        ? ownerProfileId.value
        : this.ownerProfileId,
    taxCode: taxCode.present ? taxCode.value : this.taxCode,
    employeeIdsJson: employeeIdsJson ?? this.employeeIdsJson,
    isOwner: isOwner ?? this.isOwner,
    updatedAtEpoch: updatedAtEpoch.present
        ? updatedAtEpoch.value
        : this.updatedAtEpoch,
    cachedAtEpoch: cachedAtEpoch ?? this.cachedAtEpoch,
  );
  LocationsTableData copyWithCompanion(LocationsTableCompanion data) {
    return LocationsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      district: data.district.present ? data.district.value : this.district,
      city: data.city.present ? data.city.value : this.city,
      phone: data.phone.present ? data.phone.value : this.phone,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
      ownerProfileId: data.ownerProfileId.present
          ? data.ownerProfileId.value
          : this.ownerProfileId,
      taxCode: data.taxCode.present ? data.taxCode.value : this.taxCode,
      employeeIdsJson: data.employeeIdsJson.present
          ? data.employeeIdsJson.value
          : this.employeeIdsJson,
      isOwner: data.isOwner.present ? data.isOwner.value : this.isOwner,
      updatedAtEpoch: data.updatedAtEpoch.present
          ? data.updatedAtEpoch.value
          : this.updatedAtEpoch,
      cachedAtEpoch: data.cachedAtEpoch.present
          ? data.cachedAtEpoch.value
          : this.cachedAtEpoch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('district: $district, ')
          ..write('city: $city, ')
          ..write('phone: $phone, ')
          ..write('isActive: $isActive, ')
          ..write('ownerName: $ownerName, ')
          ..write('ownerProfileId: $ownerProfileId, ')
          ..write('taxCode: $taxCode, ')
          ..write('employeeIdsJson: $employeeIdsJson, ')
          ..write('isOwner: $isOwner, ')
          ..write('updatedAtEpoch: $updatedAtEpoch, ')
          ..write('cachedAtEpoch: $cachedAtEpoch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    address,
    district,
    city,
    phone,
    isActive,
    ownerName,
    ownerProfileId,
    taxCode,
    employeeIdsJson,
    isOwner,
    updatedAtEpoch,
    cachedAtEpoch,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.address == this.address &&
          other.district == this.district &&
          other.city == this.city &&
          other.phone == this.phone &&
          other.isActive == this.isActive &&
          other.ownerName == this.ownerName &&
          other.ownerProfileId == this.ownerProfileId &&
          other.taxCode == this.taxCode &&
          other.employeeIdsJson == this.employeeIdsJson &&
          other.isOwner == this.isOwner &&
          other.updatedAtEpoch == this.updatedAtEpoch &&
          other.cachedAtEpoch == this.cachedAtEpoch);
}

class LocationsTableCompanion extends UpdateCompanion<LocationsTableData> {
  final Value<String> id;
  final Value<String?> businessId;
  final Value<String> name;
  final Value<String> address;
  final Value<String> district;
  final Value<String> city;
  final Value<String> phone;
  final Value<bool> isActive;
  final Value<String> ownerName;
  final Value<String?> ownerProfileId;
  final Value<String?> taxCode;
  final Value<String> employeeIdsJson;
  final Value<bool> isOwner;
  final Value<int?> updatedAtEpoch;
  final Value<int> cachedAtEpoch;
  final Value<int> rowid;
  const LocationsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.district = const Value.absent(),
    this.city = const Value.absent(),
    this.phone = const Value.absent(),
    this.isActive = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.ownerProfileId = const Value.absent(),
    this.taxCode = const Value.absent(),
    this.employeeIdsJson = const Value.absent(),
    this.isOwner = const Value.absent(),
    this.updatedAtEpoch = const Value.absent(),
    this.cachedAtEpoch = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocationsTableCompanion.insert({
    required String id,
    this.businessId = const Value.absent(),
    required String name,
    this.address = const Value.absent(),
    this.district = const Value.absent(),
    this.city = const Value.absent(),
    this.phone = const Value.absent(),
    this.isActive = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.ownerProfileId = const Value.absent(),
    this.taxCode = const Value.absent(),
    this.employeeIdsJson = const Value.absent(),
    this.isOwner = const Value.absent(),
    this.updatedAtEpoch = const Value.absent(),
    required int cachedAtEpoch,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       cachedAtEpoch = Value(cachedAtEpoch);
  static Insertable<LocationsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? district,
    Expression<String>? city,
    Expression<String>? phone,
    Expression<bool>? isActive,
    Expression<String>? ownerName,
    Expression<String>? ownerProfileId,
    Expression<String>? taxCode,
    Expression<String>? employeeIdsJson,
    Expression<bool>? isOwner,
    Expression<int>? updatedAtEpoch,
    Expression<int>? cachedAtEpoch,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (district != null) 'district': district,
      if (city != null) 'city': city,
      if (phone != null) 'phone': phone,
      if (isActive != null) 'is_active': isActive,
      if (ownerName != null) 'owner_name': ownerName,
      if (ownerProfileId != null) 'owner_profile_id': ownerProfileId,
      if (taxCode != null) 'tax_code': taxCode,
      if (employeeIdsJson != null) 'employee_ids_json': employeeIdsJson,
      if (isOwner != null) 'is_owner': isOwner,
      if (updatedAtEpoch != null) 'updated_at_epoch': updatedAtEpoch,
      if (cachedAtEpoch != null) 'cached_at_epoch': cachedAtEpoch,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocationsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? businessId,
    Value<String>? name,
    Value<String>? address,
    Value<String>? district,
    Value<String>? city,
    Value<String>? phone,
    Value<bool>? isActive,
    Value<String>? ownerName,
    Value<String?>? ownerProfileId,
    Value<String?>? taxCode,
    Value<String>? employeeIdsJson,
    Value<bool>? isOwner,
    Value<int?>? updatedAtEpoch,
    Value<int>? cachedAtEpoch,
    Value<int>? rowid,
  }) {
    return LocationsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      address: address ?? this.address,
      district: district ?? this.district,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      ownerName: ownerName ?? this.ownerName,
      ownerProfileId: ownerProfileId ?? this.ownerProfileId,
      taxCode: taxCode ?? this.taxCode,
      employeeIdsJson: employeeIdsJson ?? this.employeeIdsJson,
      isOwner: isOwner ?? this.isOwner,
      updatedAtEpoch: updatedAtEpoch ?? this.updatedAtEpoch,
      cachedAtEpoch: cachedAtEpoch ?? this.cachedAtEpoch,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (district.present) {
      map['district'] = Variable<String>(district.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (ownerName.present) {
      map['owner_name'] = Variable<String>(ownerName.value);
    }
    if (ownerProfileId.present) {
      map['owner_profile_id'] = Variable<String>(ownerProfileId.value);
    }
    if (taxCode.present) {
      map['tax_code'] = Variable<String>(taxCode.value);
    }
    if (employeeIdsJson.present) {
      map['employee_ids_json'] = Variable<String>(employeeIdsJson.value);
    }
    if (isOwner.present) {
      map['is_owner'] = Variable<bool>(isOwner.value);
    }
    if (updatedAtEpoch.present) {
      map['updated_at_epoch'] = Variable<int>(updatedAtEpoch.value);
    }
    if (cachedAtEpoch.present) {
      map['cached_at_epoch'] = Variable<int>(cachedAtEpoch.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('district: $district, ')
          ..write('city: $city, ')
          ..write('phone: $phone, ')
          ..write('isActive: $isActive, ')
          ..write('ownerName: $ownerName, ')
          ..write('ownerProfileId: $ownerProfileId, ')
          ..write('taxCode: $taxCode, ')
          ..write('employeeIdsJson: $employeeIdsJson, ')
          ..write('isOwner: $isOwner, ')
          ..write('updatedAtEpoch: $updatedAtEpoch, ')
          ..write('cachedAtEpoch: $cachedAtEpoch, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTableTable extends ProductsTable
    with TableInfo<$ProductsTableTable, ProductsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
    'cost_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salePriceMeta = const VerificationMeta(
    'salePrice',
  );
  @override
  late final GeneratedColumn<double> salePrice = GeneratedColumn<double>(
    'sale_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackInventoryMeta = const VerificationMeta(
    'trackInventory',
  );
  @override
  late final GeneratedColumn<bool> trackInventory = GeneratedColumn<bool>(
    'track_inventory',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("track_inventory" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtEpochMeta = const VerificationMeta(
    'createdAtEpoch',
  );
  @override
  late final GeneratedColumn<int> createdAtEpoch = GeneratedColumn<int>(
    'created_at_epoch',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<int> locationId = GeneratedColumn<int>(
    'location_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _businessTypeIdMeta = const VerificationMeta(
    'businessTypeId',
  );
  @override
  late final GeneratedColumn<String> businessTypeId = GeneratedColumn<String>(
    'business_type_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _manufacturerMeta = const VerificationMeta(
    'manufacturer',
  );
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _businessLocationNameMeta =
      const VerificationMeta('businessLocationName');
  @override
  late final GeneratedColumn<String> businessLocationName =
      GeneratedColumn<String>(
        'business_location_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _saleItemsJsonMeta = const VerificationMeta(
    'saleItemsJson',
  );
  @override
  late final GeneratedColumn<String> saleItemsJson = GeneratedColumn<String>(
    'sale_items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _cachedAtEpochMeta = const VerificationMeta(
    'cachedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> cachedAtEpoch = GeneratedColumn<int>(
    'cached_at_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scopeKey,
    name,
    description,
    price,
    quantity,
    imageUrl,
    barcode,
    category,
    costPrice,
    salePrice,
    unit,
    trackInventory,
    isActive,
    createdAtEpoch,
    locationId,
    businessTypeId,
    manufacturer,
    businessLocationName,
    saleItemsJson,
    cachedAtEpoch,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    }
    if (data.containsKey('sale_price')) {
      context.handle(
        _salePriceMeta,
        salePrice.isAcceptableOrUnknown(data['sale_price']!, _salePriceMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('track_inventory')) {
      context.handle(
        _trackInventoryMeta,
        trackInventory.isAcceptableOrUnknown(
          data['track_inventory']!,
          _trackInventoryMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at_epoch')) {
      context.handle(
        _createdAtEpochMeta,
        createdAtEpoch.isAcceptableOrUnknown(
          data['created_at_epoch']!,
          _createdAtEpochMeta,
        ),
      );
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    }
    if (data.containsKey('business_type_id')) {
      context.handle(
        _businessTypeIdMeta,
        businessTypeId.isAcceptableOrUnknown(
          data['business_type_id']!,
          _businessTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
        _manufacturerMeta,
        manufacturer.isAcceptableOrUnknown(
          data['manufacturer']!,
          _manufacturerMeta,
        ),
      );
    }
    if (data.containsKey('business_location_name')) {
      context.handle(
        _businessLocationNameMeta,
        businessLocationName.isAcceptableOrUnknown(
          data['business_location_name']!,
          _businessLocationNameMeta,
        ),
      );
    }
    if (data.containsKey('sale_items_json')) {
      context.handle(
        _saleItemsJsonMeta,
        saleItemsJson.isAcceptableOrUnknown(
          data['sale_items_json']!,
          _saleItemsJsonMeta,
        ),
      );
    }
    if (data.containsKey('cached_at_epoch')) {
      context.handle(
        _cachedAtEpochMeta,
        cachedAtEpoch.isAcceptableOrUnknown(
          data['cached_at_epoch']!,
          _cachedAtEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedAtEpochMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      costPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_price'],
      ),
      salePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sale_price'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      trackInventory: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}track_inventory'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_epoch'],
      ),
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}location_id'],
      ),
      businessTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_type_id'],
      ),
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      ),
      businessLocationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_location_name'],
      ),
      saleItemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_items_json'],
      )!,
      cachedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at_epoch'],
      )!,
    );
  }

  @override
  $ProductsTableTable createAlias(String alias) {
    return $ProductsTableTable(attachedDatabase, alias);
  }
}

class ProductsTableData extends DataClass
    implements Insertable<ProductsTableData> {
  final String id;
  final String scopeKey;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String? barcode;
  final String? category;
  final double? costPrice;
  final double? salePrice;
  final String? unit;
  final bool trackInventory;
  final bool isActive;
  final int? createdAtEpoch;
  final int? locationId;
  final String? businessTypeId;
  final String? manufacturer;
  final String? businessLocationName;
  final String saleItemsJson;
  final int cachedAtEpoch;
  const ProductsTableData({
    required this.id,
    required this.scopeKey,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.barcode,
    this.category,
    this.costPrice,
    this.salePrice,
    this.unit,
    required this.trackInventory,
    required this.isActive,
    this.createdAtEpoch,
    this.locationId,
    this.businessTypeId,
    this.manufacturer,
    this.businessLocationName,
    required this.saleItemsJson,
    required this.cachedAtEpoch,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope_key'] = Variable<String>(scopeKey);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['price'] = Variable<double>(price);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || costPrice != null) {
      map['cost_price'] = Variable<double>(costPrice);
    }
    if (!nullToAbsent || salePrice != null) {
      map['sale_price'] = Variable<double>(salePrice);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['track_inventory'] = Variable<bool>(trackInventory);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || createdAtEpoch != null) {
      map['created_at_epoch'] = Variable<int>(createdAtEpoch);
    }
    if (!nullToAbsent || locationId != null) {
      map['location_id'] = Variable<int>(locationId);
    }
    if (!nullToAbsent || businessTypeId != null) {
      map['business_type_id'] = Variable<String>(businessTypeId);
    }
    if (!nullToAbsent || manufacturer != null) {
      map['manufacturer'] = Variable<String>(manufacturer);
    }
    if (!nullToAbsent || businessLocationName != null) {
      map['business_location_name'] = Variable<String>(businessLocationName);
    }
    map['sale_items_json'] = Variable<String>(saleItemsJson);
    map['cached_at_epoch'] = Variable<int>(cachedAtEpoch);
    return map;
  }

  ProductsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductsTableCompanion(
      id: Value(id),
      scopeKey: Value(scopeKey),
      name: Value(name),
      description: Value(description),
      price: Value(price),
      quantity: Value(quantity),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      costPrice: costPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(costPrice),
      salePrice: salePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(salePrice),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      trackInventory: Value(trackInventory),
      isActive: Value(isActive),
      createdAtEpoch: createdAtEpoch == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAtEpoch),
      locationId: locationId == null && nullToAbsent
          ? const Value.absent()
          : Value(locationId),
      businessTypeId: businessTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessTypeId),
      manufacturer: manufacturer == null && nullToAbsent
          ? const Value.absent()
          : Value(manufacturer),
      businessLocationName: businessLocationName == null && nullToAbsent
          ? const Value.absent()
          : Value(businessLocationName),
      saleItemsJson: Value(saleItemsJson),
      cachedAtEpoch: Value(cachedAtEpoch),
    );
  }

  factory ProductsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductsTableData(
      id: serializer.fromJson<String>(json['id']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      price: serializer.fromJson<double>(json['price']),
      quantity: serializer.fromJson<int>(json['quantity']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      category: serializer.fromJson<String?>(json['category']),
      costPrice: serializer.fromJson<double?>(json['costPrice']),
      salePrice: serializer.fromJson<double?>(json['salePrice']),
      unit: serializer.fromJson<String?>(json['unit']),
      trackInventory: serializer.fromJson<bool>(json['trackInventory']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAtEpoch: serializer.fromJson<int?>(json['createdAtEpoch']),
      locationId: serializer.fromJson<int?>(json['locationId']),
      businessTypeId: serializer.fromJson<String?>(json['businessTypeId']),
      manufacturer: serializer.fromJson<String?>(json['manufacturer']),
      businessLocationName: serializer.fromJson<String?>(
        json['businessLocationName'],
      ),
      saleItemsJson: serializer.fromJson<String>(json['saleItemsJson']),
      cachedAtEpoch: serializer.fromJson<int>(json['cachedAtEpoch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'price': serializer.toJson<double>(price),
      'quantity': serializer.toJson<int>(quantity),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'barcode': serializer.toJson<String?>(barcode),
      'category': serializer.toJson<String?>(category),
      'costPrice': serializer.toJson<double?>(costPrice),
      'salePrice': serializer.toJson<double?>(salePrice),
      'unit': serializer.toJson<String?>(unit),
      'trackInventory': serializer.toJson<bool>(trackInventory),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAtEpoch': serializer.toJson<int?>(createdAtEpoch),
      'locationId': serializer.toJson<int?>(locationId),
      'businessTypeId': serializer.toJson<String?>(businessTypeId),
      'manufacturer': serializer.toJson<String?>(manufacturer),
      'businessLocationName': serializer.toJson<String?>(businessLocationName),
      'saleItemsJson': serializer.toJson<String>(saleItemsJson),
      'cachedAtEpoch': serializer.toJson<int>(cachedAtEpoch),
    };
  }

  ProductsTableData copyWith({
    String? id,
    String? scopeKey,
    String? name,
    String? description,
    double? price,
    int? quantity,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<double?> costPrice = const Value.absent(),
    Value<double?> salePrice = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    bool? trackInventory,
    bool? isActive,
    Value<int?> createdAtEpoch = const Value.absent(),
    Value<int?> locationId = const Value.absent(),
    Value<String?> businessTypeId = const Value.absent(),
    Value<String?> manufacturer = const Value.absent(),
    Value<String?> businessLocationName = const Value.absent(),
    String? saleItemsJson,
    int? cachedAtEpoch,
  }) => ProductsTableData(
    id: id ?? this.id,
    scopeKey: scopeKey ?? this.scopeKey,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    quantity: quantity ?? this.quantity,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    barcode: barcode.present ? barcode.value : this.barcode,
    category: category.present ? category.value : this.category,
    costPrice: costPrice.present ? costPrice.value : this.costPrice,
    salePrice: salePrice.present ? salePrice.value : this.salePrice,
    unit: unit.present ? unit.value : this.unit,
    trackInventory: trackInventory ?? this.trackInventory,
    isActive: isActive ?? this.isActive,
    createdAtEpoch: createdAtEpoch.present
        ? createdAtEpoch.value
        : this.createdAtEpoch,
    locationId: locationId.present ? locationId.value : this.locationId,
    businessTypeId: businessTypeId.present
        ? businessTypeId.value
        : this.businessTypeId,
    manufacturer: manufacturer.present ? manufacturer.value : this.manufacturer,
    businessLocationName: businessLocationName.present
        ? businessLocationName.value
        : this.businessLocationName,
    saleItemsJson: saleItemsJson ?? this.saleItemsJson,
    cachedAtEpoch: cachedAtEpoch ?? this.cachedAtEpoch,
  );
  ProductsTableData copyWithCompanion(ProductsTableCompanion data) {
    return ProductsTableData(
      id: data.id.present ? data.id.value : this.id,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      price: data.price.present ? data.price.value : this.price,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      category: data.category.present ? data.category.value : this.category,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      salePrice: data.salePrice.present ? data.salePrice.value : this.salePrice,
      unit: data.unit.present ? data.unit.value : this.unit,
      trackInventory: data.trackInventory.present
          ? data.trackInventory.value
          : this.trackInventory,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAtEpoch: data.createdAtEpoch.present
          ? data.createdAtEpoch.value
          : this.createdAtEpoch,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      businessTypeId: data.businessTypeId.present
          ? data.businessTypeId.value
          : this.businessTypeId,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      businessLocationName: data.businessLocationName.present
          ? data.businessLocationName.value
          : this.businessLocationName,
      saleItemsJson: data.saleItemsJson.present
          ? data.saleItemsJson.value
          : this.saleItemsJson,
      cachedAtEpoch: data.cachedAtEpoch.present
          ? data.cachedAtEpoch.value
          : this.cachedAtEpoch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableData(')
          ..write('id: $id, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('quantity: $quantity, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('barcode: $barcode, ')
          ..write('category: $category, ')
          ..write('costPrice: $costPrice, ')
          ..write('salePrice: $salePrice, ')
          ..write('unit: $unit, ')
          ..write('trackInventory: $trackInventory, ')
          ..write('isActive: $isActive, ')
          ..write('createdAtEpoch: $createdAtEpoch, ')
          ..write('locationId: $locationId, ')
          ..write('businessTypeId: $businessTypeId, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('businessLocationName: $businessLocationName, ')
          ..write('saleItemsJson: $saleItemsJson, ')
          ..write('cachedAtEpoch: $cachedAtEpoch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    scopeKey,
    name,
    description,
    price,
    quantity,
    imageUrl,
    barcode,
    category,
    costPrice,
    salePrice,
    unit,
    trackInventory,
    isActive,
    createdAtEpoch,
    locationId,
    businessTypeId,
    manufacturer,
    businessLocationName,
    saleItemsJson,
    cachedAtEpoch,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductsTableData &&
          other.id == this.id &&
          other.scopeKey == this.scopeKey &&
          other.name == this.name &&
          other.description == this.description &&
          other.price == this.price &&
          other.quantity == this.quantity &&
          other.imageUrl == this.imageUrl &&
          other.barcode == this.barcode &&
          other.category == this.category &&
          other.costPrice == this.costPrice &&
          other.salePrice == this.salePrice &&
          other.unit == this.unit &&
          other.trackInventory == this.trackInventory &&
          other.isActive == this.isActive &&
          other.createdAtEpoch == this.createdAtEpoch &&
          other.locationId == this.locationId &&
          other.businessTypeId == this.businessTypeId &&
          other.manufacturer == this.manufacturer &&
          other.businessLocationName == this.businessLocationName &&
          other.saleItemsJson == this.saleItemsJson &&
          other.cachedAtEpoch == this.cachedAtEpoch);
}

class ProductsTableCompanion extends UpdateCompanion<ProductsTableData> {
  final Value<String> id;
  final Value<String> scopeKey;
  final Value<String> name;
  final Value<String> description;
  final Value<double> price;
  final Value<int> quantity;
  final Value<String?> imageUrl;
  final Value<String?> barcode;
  final Value<String?> category;
  final Value<double?> costPrice;
  final Value<double?> salePrice;
  final Value<String?> unit;
  final Value<bool> trackInventory;
  final Value<bool> isActive;
  final Value<int?> createdAtEpoch;
  final Value<int?> locationId;
  final Value<String?> businessTypeId;
  final Value<String?> manufacturer;
  final Value<String?> businessLocationName;
  final Value<String> saleItemsJson;
  final Value<int> cachedAtEpoch;
  final Value<int> rowid;
  const ProductsTableCompanion({
    this.id = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    this.quantity = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.barcode = const Value.absent(),
    this.category = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.salePrice = const Value.absent(),
    this.unit = const Value.absent(),
    this.trackInventory = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAtEpoch = const Value.absent(),
    this.locationId = const Value.absent(),
    this.businessTypeId = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.businessLocationName = const Value.absent(),
    this.saleItemsJson = const Value.absent(),
    this.cachedAtEpoch = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsTableCompanion.insert({
    required String id,
    required String scopeKey,
    required String name,
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    this.quantity = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.barcode = const Value.absent(),
    this.category = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.salePrice = const Value.absent(),
    this.unit = const Value.absent(),
    this.trackInventory = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAtEpoch = const Value.absent(),
    this.locationId = const Value.absent(),
    this.businessTypeId = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.businessLocationName = const Value.absent(),
    this.saleItemsJson = const Value.absent(),
    required int cachedAtEpoch,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scopeKey = Value(scopeKey),
       name = Value(name),
       cachedAtEpoch = Value(cachedAtEpoch);
  static Insertable<ProductsTableData> custom({
    Expression<String>? id,
    Expression<String>? scopeKey,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? price,
    Expression<int>? quantity,
    Expression<String>? imageUrl,
    Expression<String>? barcode,
    Expression<String>? category,
    Expression<double>? costPrice,
    Expression<double>? salePrice,
    Expression<String>? unit,
    Expression<bool>? trackInventory,
    Expression<bool>? isActive,
    Expression<int>? createdAtEpoch,
    Expression<int>? locationId,
    Expression<String>? businessTypeId,
    Expression<String>? manufacturer,
    Expression<String>? businessLocationName,
    Expression<String>? saleItemsJson,
    Expression<int>? cachedAtEpoch,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (quantity != null) 'quantity': quantity,
      if (imageUrl != null) 'image_url': imageUrl,
      if (barcode != null) 'barcode': barcode,
      if (category != null) 'category': category,
      if (costPrice != null) 'cost_price': costPrice,
      if (salePrice != null) 'sale_price': salePrice,
      if (unit != null) 'unit': unit,
      if (trackInventory != null) 'track_inventory': trackInventory,
      if (isActive != null) 'is_active': isActive,
      if (createdAtEpoch != null) 'created_at_epoch': createdAtEpoch,
      if (locationId != null) 'location_id': locationId,
      if (businessTypeId != null) 'business_type_id': businessTypeId,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (businessLocationName != null)
        'business_location_name': businessLocationName,
      if (saleItemsJson != null) 'sale_items_json': saleItemsJson,
      if (cachedAtEpoch != null) 'cached_at_epoch': cachedAtEpoch,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? scopeKey,
    Value<String>? name,
    Value<String>? description,
    Value<double>? price,
    Value<int>? quantity,
    Value<String?>? imageUrl,
    Value<String?>? barcode,
    Value<String?>? category,
    Value<double?>? costPrice,
    Value<double?>? salePrice,
    Value<String?>? unit,
    Value<bool>? trackInventory,
    Value<bool>? isActive,
    Value<int?>? createdAtEpoch,
    Value<int?>? locationId,
    Value<String?>? businessTypeId,
    Value<String?>? manufacturer,
    Value<String?>? businessLocationName,
    Value<String>? saleItemsJson,
    Value<int>? cachedAtEpoch,
    Value<int>? rowid,
  }) {
    return ProductsTableCompanion(
      id: id ?? this.id,
      scopeKey: scopeKey ?? this.scopeKey,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      unit: unit ?? this.unit,
      trackInventory: trackInventory ?? this.trackInventory,
      isActive: isActive ?? this.isActive,
      createdAtEpoch: createdAtEpoch ?? this.createdAtEpoch,
      locationId: locationId ?? this.locationId,
      businessTypeId: businessTypeId ?? this.businessTypeId,
      manufacturer: manufacturer ?? this.manufacturer,
      businessLocationName: businessLocationName ?? this.businessLocationName,
      saleItemsJson: saleItemsJson ?? this.saleItemsJson,
      cachedAtEpoch: cachedAtEpoch ?? this.cachedAtEpoch,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (salePrice.present) {
      map['sale_price'] = Variable<double>(salePrice.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (trackInventory.present) {
      map['track_inventory'] = Variable<bool>(trackInventory.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAtEpoch.present) {
      map['created_at_epoch'] = Variable<int>(createdAtEpoch.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<int>(locationId.value);
    }
    if (businessTypeId.present) {
      map['business_type_id'] = Variable<String>(businessTypeId.value);
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (businessLocationName.present) {
      map['business_location_name'] = Variable<String>(
        businessLocationName.value,
      );
    }
    if (saleItemsJson.present) {
      map['sale_items_json'] = Variable<String>(saleItemsJson.value);
    }
    if (cachedAtEpoch.present) {
      map['cached_at_epoch'] = Variable<int>(cachedAtEpoch.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableCompanion(')
          ..write('id: $id, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('quantity: $quantity, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('barcode: $barcode, ')
          ..write('category: $category, ')
          ..write('costPrice: $costPrice, ')
          ..write('salePrice: $salePrice, ')
          ..write('unit: $unit, ')
          ..write('trackInventory: $trackInventory, ')
          ..write('isActive: $isActive, ')
          ..write('createdAtEpoch: $createdAtEpoch, ')
          ..write('locationId: $locationId, ')
          ..write('businessTypeId: $businessTypeId, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('businessLocationName: $businessLocationName, ')
          ..write('saleItemsJson: $saleItemsJson, ')
          ..write('cachedAtEpoch: $cachedAtEpoch, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmployeesTableTable extends EmployeesTable
    with TableInfo<$EmployeesTableTable, EmployeesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _employmentStatusMeta = const VerificationMeta(
    'employmentStatus',
  );
  @override
  late final GeneratedColumn<String> employmentStatus = GeneratedColumn<String>(
    'employment_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('accepted'),
  );
  static const VerificationMeta _startedAtEpochMeta = const VerificationMeta(
    'startedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> startedAtEpoch = GeneratedColumn<int>(
    'started_at_epoch',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtEpochMeta = const VerificationMeta(
    'endedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> endedAtEpoch = GeneratedColumn<int>(
    'ended_at_epoch',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assignedLocationIdsJsonMeta =
      const VerificationMeta('assignedLocationIdsJson');
  @override
  late final GeneratedColumn<String> assignedLocationIdsJson =
      GeneratedColumn<String>(
        'assigned_location_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _assignedLocationNamesJsonMeta =
      const VerificationMeta('assignedLocationNamesJson');
  @override
  late final GeneratedColumn<String> assignedLocationNamesJson =
      GeneratedColumn<String>(
        'assigned_location_names_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _cachedAtEpochMeta = const VerificationMeta(
    'cachedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> cachedAtEpoch = GeneratedColumn<int>(
    'cached_at_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    phone,
    email,
    status,
    isActive,
    employmentStatus,
    startedAtEpoch,
    endedAtEpoch,
    assignedLocationIdsJson,
    assignedLocationNamesJson,
    cachedAtEpoch,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employees_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmployeesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('employment_status')) {
      context.handle(
        _employmentStatusMeta,
        employmentStatus.isAcceptableOrUnknown(
          data['employment_status']!,
          _employmentStatusMeta,
        ),
      );
    }
    if (data.containsKey('started_at_epoch')) {
      context.handle(
        _startedAtEpochMeta,
        startedAtEpoch.isAcceptableOrUnknown(
          data['started_at_epoch']!,
          _startedAtEpochMeta,
        ),
      );
    }
    if (data.containsKey('ended_at_epoch')) {
      context.handle(
        _endedAtEpochMeta,
        endedAtEpoch.isAcceptableOrUnknown(
          data['ended_at_epoch']!,
          _endedAtEpochMeta,
        ),
      );
    }
    if (data.containsKey('assigned_location_ids_json')) {
      context.handle(
        _assignedLocationIdsJsonMeta,
        assignedLocationIdsJson.isAcceptableOrUnknown(
          data['assigned_location_ids_json']!,
          _assignedLocationIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('assigned_location_names_json')) {
      context.handle(
        _assignedLocationNamesJsonMeta,
        assignedLocationNamesJson.isAcceptableOrUnknown(
          data['assigned_location_names_json']!,
          _assignedLocationNamesJsonMeta,
        ),
      );
    }
    if (data.containsKey('cached_at_epoch')) {
      context.handle(
        _cachedAtEpochMeta,
        cachedAtEpoch.isAcceptableOrUnknown(
          data['cached_at_epoch']!,
          _cachedAtEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedAtEpochMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmployeesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmployeesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      employmentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employment_status'],
      )!,
      startedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_epoch'],
      ),
      endedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at_epoch'],
      ),
      assignedLocationIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_location_ids_json'],
      )!,
      assignedLocationNamesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_location_names_json'],
      )!,
      cachedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at_epoch'],
      )!,
    );
  }

  @override
  $EmployeesTableTable createAlias(String alias) {
    return $EmployeesTableTable(attachedDatabase, alias);
  }
}

class EmployeesTableData extends DataClass
    implements Insertable<EmployeesTableData> {
  final String id;
  final String businessId;
  final String name;
  final String phone;
  final String email;
  final String status;
  final bool isActive;
  final String employmentStatus;
  final int? startedAtEpoch;
  final int? endedAtEpoch;
  final String assignedLocationIdsJson;
  final String assignedLocationNamesJson;
  final int cachedAtEpoch;
  const EmployeesTableData({
    required this.id,
    required this.businessId,
    required this.name,
    required this.phone,
    required this.email,
    required this.status,
    required this.isActive,
    required this.employmentStatus,
    this.startedAtEpoch,
    this.endedAtEpoch,
    required this.assignedLocationIdsJson,
    required this.assignedLocationNamesJson,
    required this.cachedAtEpoch,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['email'] = Variable<String>(email);
    map['status'] = Variable<String>(status);
    map['is_active'] = Variable<bool>(isActive);
    map['employment_status'] = Variable<String>(employmentStatus);
    if (!nullToAbsent || startedAtEpoch != null) {
      map['started_at_epoch'] = Variable<int>(startedAtEpoch);
    }
    if (!nullToAbsent || endedAtEpoch != null) {
      map['ended_at_epoch'] = Variable<int>(endedAtEpoch);
    }
    map['assigned_location_ids_json'] = Variable<String>(
      assignedLocationIdsJson,
    );
    map['assigned_location_names_json'] = Variable<String>(
      assignedLocationNamesJson,
    );
    map['cached_at_epoch'] = Variable<int>(cachedAtEpoch);
    return map;
  }

  EmployeesTableCompanion toCompanion(bool nullToAbsent) {
    return EmployeesTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      phone: Value(phone),
      email: Value(email),
      status: Value(status),
      isActive: Value(isActive),
      employmentStatus: Value(employmentStatus),
      startedAtEpoch: startedAtEpoch == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAtEpoch),
      endedAtEpoch: endedAtEpoch == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtEpoch),
      assignedLocationIdsJson: Value(assignedLocationIdsJson),
      assignedLocationNamesJson: Value(assignedLocationNamesJson),
      cachedAtEpoch: Value(cachedAtEpoch),
    );
  }

  factory EmployeesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmployeesTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      email: serializer.fromJson<String>(json['email']),
      status: serializer.fromJson<String>(json['status']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      employmentStatus: serializer.fromJson<String>(json['employmentStatus']),
      startedAtEpoch: serializer.fromJson<int?>(json['startedAtEpoch']),
      endedAtEpoch: serializer.fromJson<int?>(json['endedAtEpoch']),
      assignedLocationIdsJson: serializer.fromJson<String>(
        json['assignedLocationIdsJson'],
      ),
      assignedLocationNamesJson: serializer.fromJson<String>(
        json['assignedLocationNamesJson'],
      ),
      cachedAtEpoch: serializer.fromJson<int>(json['cachedAtEpoch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'email': serializer.toJson<String>(email),
      'status': serializer.toJson<String>(status),
      'isActive': serializer.toJson<bool>(isActive),
      'employmentStatus': serializer.toJson<String>(employmentStatus),
      'startedAtEpoch': serializer.toJson<int?>(startedAtEpoch),
      'endedAtEpoch': serializer.toJson<int?>(endedAtEpoch),
      'assignedLocationIdsJson': serializer.toJson<String>(
        assignedLocationIdsJson,
      ),
      'assignedLocationNamesJson': serializer.toJson<String>(
        assignedLocationNamesJson,
      ),
      'cachedAtEpoch': serializer.toJson<int>(cachedAtEpoch),
    };
  }

  EmployeesTableData copyWith({
    String? id,
    String? businessId,
    String? name,
    String? phone,
    String? email,
    String? status,
    bool? isActive,
    String? employmentStatus,
    Value<int?> startedAtEpoch = const Value.absent(),
    Value<int?> endedAtEpoch = const Value.absent(),
    String? assignedLocationIdsJson,
    String? assignedLocationNamesJson,
    int? cachedAtEpoch,
  }) => EmployeesTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    status: status ?? this.status,
    isActive: isActive ?? this.isActive,
    employmentStatus: employmentStatus ?? this.employmentStatus,
    startedAtEpoch: startedAtEpoch.present
        ? startedAtEpoch.value
        : this.startedAtEpoch,
    endedAtEpoch: endedAtEpoch.present ? endedAtEpoch.value : this.endedAtEpoch,
    assignedLocationIdsJson:
        assignedLocationIdsJson ?? this.assignedLocationIdsJson,
    assignedLocationNamesJson:
        assignedLocationNamesJson ?? this.assignedLocationNamesJson,
    cachedAtEpoch: cachedAtEpoch ?? this.cachedAtEpoch,
  );
  EmployeesTableData copyWithCompanion(EmployeesTableCompanion data) {
    return EmployeesTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      status: data.status.present ? data.status.value : this.status,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      employmentStatus: data.employmentStatus.present
          ? data.employmentStatus.value
          : this.employmentStatus,
      startedAtEpoch: data.startedAtEpoch.present
          ? data.startedAtEpoch.value
          : this.startedAtEpoch,
      endedAtEpoch: data.endedAtEpoch.present
          ? data.endedAtEpoch.value
          : this.endedAtEpoch,
      assignedLocationIdsJson: data.assignedLocationIdsJson.present
          ? data.assignedLocationIdsJson.value
          : this.assignedLocationIdsJson,
      assignedLocationNamesJson: data.assignedLocationNamesJson.present
          ? data.assignedLocationNamesJson.value
          : this.assignedLocationNamesJson,
      cachedAtEpoch: data.cachedAtEpoch.present
          ? data.cachedAtEpoch.value
          : this.cachedAtEpoch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmployeesTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('status: $status, ')
          ..write('isActive: $isActive, ')
          ..write('employmentStatus: $employmentStatus, ')
          ..write('startedAtEpoch: $startedAtEpoch, ')
          ..write('endedAtEpoch: $endedAtEpoch, ')
          ..write('assignedLocationIdsJson: $assignedLocationIdsJson, ')
          ..write('assignedLocationNamesJson: $assignedLocationNamesJson, ')
          ..write('cachedAtEpoch: $cachedAtEpoch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    phone,
    email,
    status,
    isActive,
    employmentStatus,
    startedAtEpoch,
    endedAtEpoch,
    assignedLocationIdsJson,
    assignedLocationNamesJson,
    cachedAtEpoch,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmployeesTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.status == this.status &&
          other.isActive == this.isActive &&
          other.employmentStatus == this.employmentStatus &&
          other.startedAtEpoch == this.startedAtEpoch &&
          other.endedAtEpoch == this.endedAtEpoch &&
          other.assignedLocationIdsJson == this.assignedLocationIdsJson &&
          other.assignedLocationNamesJson == this.assignedLocationNamesJson &&
          other.cachedAtEpoch == this.cachedAtEpoch);
}

class EmployeesTableCompanion extends UpdateCompanion<EmployeesTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String> phone;
  final Value<String> email;
  final Value<String> status;
  final Value<bool> isActive;
  final Value<String> employmentStatus;
  final Value<int?> startedAtEpoch;
  final Value<int?> endedAtEpoch;
  final Value<String> assignedLocationIdsJson;
  final Value<String> assignedLocationNamesJson;
  final Value<int> cachedAtEpoch;
  final Value<int> rowid;
  const EmployeesTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.status = const Value.absent(),
    this.isActive = const Value.absent(),
    this.employmentStatus = const Value.absent(),
    this.startedAtEpoch = const Value.absent(),
    this.endedAtEpoch = const Value.absent(),
    this.assignedLocationIdsJson = const Value.absent(),
    this.assignedLocationNamesJson = const Value.absent(),
    this.cachedAtEpoch = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmployeesTableCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.status = const Value.absent(),
    this.isActive = const Value.absent(),
    this.employmentStatus = const Value.absent(),
    this.startedAtEpoch = const Value.absent(),
    this.endedAtEpoch = const Value.absent(),
    this.assignedLocationIdsJson = const Value.absent(),
    this.assignedLocationNamesJson = const Value.absent(),
    required int cachedAtEpoch,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name),
       cachedAtEpoch = Value(cachedAtEpoch);
  static Insertable<EmployeesTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? status,
    Expression<bool>? isActive,
    Expression<String>? employmentStatus,
    Expression<int>? startedAtEpoch,
    Expression<int>? endedAtEpoch,
    Expression<String>? assignedLocationIdsJson,
    Expression<String>? assignedLocationNamesJson,
    Expression<int>? cachedAtEpoch,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (status != null) 'status': status,
      if (isActive != null) 'is_active': isActive,
      if (employmentStatus != null) 'employment_status': employmentStatus,
      if (startedAtEpoch != null) 'started_at_epoch': startedAtEpoch,
      if (endedAtEpoch != null) 'ended_at_epoch': endedAtEpoch,
      if (assignedLocationIdsJson != null)
        'assigned_location_ids_json': assignedLocationIdsJson,
      if (assignedLocationNamesJson != null)
        'assigned_location_names_json': assignedLocationNamesJson,
      if (cachedAtEpoch != null) 'cached_at_epoch': cachedAtEpoch,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmployeesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String>? phone,
    Value<String>? email,
    Value<String>? status,
    Value<bool>? isActive,
    Value<String>? employmentStatus,
    Value<int?>? startedAtEpoch,
    Value<int?>? endedAtEpoch,
    Value<String>? assignedLocationIdsJson,
    Value<String>? assignedLocationNamesJson,
    Value<int>? cachedAtEpoch,
    Value<int>? rowid,
  }) {
    return EmployeesTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      startedAtEpoch: startedAtEpoch ?? this.startedAtEpoch,
      endedAtEpoch: endedAtEpoch ?? this.endedAtEpoch,
      assignedLocationIdsJson:
          assignedLocationIdsJson ?? this.assignedLocationIdsJson,
      assignedLocationNamesJson:
          assignedLocationNamesJson ?? this.assignedLocationNamesJson,
      cachedAtEpoch: cachedAtEpoch ?? this.cachedAtEpoch,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (employmentStatus.present) {
      map['employment_status'] = Variable<String>(employmentStatus.value);
    }
    if (startedAtEpoch.present) {
      map['started_at_epoch'] = Variable<int>(startedAtEpoch.value);
    }
    if (endedAtEpoch.present) {
      map['ended_at_epoch'] = Variable<int>(endedAtEpoch.value);
    }
    if (assignedLocationIdsJson.present) {
      map['assigned_location_ids_json'] = Variable<String>(
        assignedLocationIdsJson.value,
      );
    }
    if (assignedLocationNamesJson.present) {
      map['assigned_location_names_json'] = Variable<String>(
        assignedLocationNamesJson.value,
      );
    }
    if (cachedAtEpoch.present) {
      map['cached_at_epoch'] = Variable<int>(cachedAtEpoch.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeesTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('status: $status, ')
          ..write('isActive: $isActive, ')
          ..write('employmentStatus: $employmentStatus, ')
          ..write('startedAtEpoch: $startedAtEpoch, ')
          ..write('endedAtEpoch: $endedAtEpoch, ')
          ..write('assignedLocationIdsJson: $assignedLocationIdsJson, ')
          ..write('assignedLocationNamesJson: $assignedLocationNamesJson, ')
          ..write('cachedAtEpoch: $cachedAtEpoch, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTableTable extends OrdersTable
    with TableInfo<$OrdersTableTable, OrdersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderCodeMeta = const VerificationMeta(
    'orderCode',
  );
  @override
  late final GeneratedColumn<String> orderCode = GeneratedColumn<String>(
    'order_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerPhoneMeta = const VerificationMeta(
    'customerPhone',
  );
  @override
  late final GeneratedColumn<String> customerPhone = GeneratedColumn<String>(
    'customer_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
    'location_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _discountAmountMeta = const VerificationMeta(
    'discountAmount',
  );
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
    'discount_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _taxAmountMeta = const VerificationMeta(
    'taxAmount',
  );
  @override
  late final GeneratedColumn<double> taxAmount = GeneratedColumn<double>(
    'tax_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _cashAmountMeta = const VerificationMeta(
    'cashAmount',
  );
  @override
  late final GeneratedColumn<double> cashAmount = GeneratedColumn<double>(
    'cash_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _bankAmountMeta = const VerificationMeta(
    'bankAmount',
  );
  @override
  late final GeneratedColumn<double> bankAmount = GeneratedColumn<double>(
    'bank_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _debtAmountMeta = const VerificationMeta(
    'debtAmount',
  );
  @override
  late final GeneratedColumn<double> debtAmount = GeneratedColumn<double>(
    'debt_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _debtorIdMeta = const VerificationMeta(
    'debtorId',
  );
  @override
  late final GeneratedColumn<int> debtorId = GeneratedColumn<int>(
    'debtor_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtEpochMeta = const VerificationMeta(
    'createdAtEpoch',
  );
  @override
  late final GeneratedColumn<int> createdAtEpoch = GeneratedColumn<int>(
    'created_at_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtEpochMeta = const VerificationMeta(
    'updatedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> updatedAtEpoch = GeneratedColumn<int>(
    'updated_at_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtEpochMeta = const VerificationMeta(
    'completedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> completedAtEpoch = GeneratedColumn<int>(
    'completed_at_epoch',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cancelledAtEpochMeta = const VerificationMeta(
    'cancelledAtEpoch',
  );
  @override
  late final GeneratedColumn<int> cancelledAtEpoch = GeneratedColumn<int>(
    'cancelled_at_epoch',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cancelReasonMeta = const VerificationMeta(
    'cancelReason',
  );
  @override
  late final GeneratedColumn<String> cancelReason = GeneratedColumn<String>(
    'cancel_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoiceNumberMeta = const VerificationMeta(
    'invoiceNumber',
  );
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
    'invoice_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoicedAtEpochMeta = const VerificationMeta(
    'invoicedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> invoicedAtEpoch = GeneratedColumn<int>(
    'invoiced_at_epoch',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtEpochMeta = const VerificationMeta(
    'cachedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> cachedAtEpoch = GeneratedColumn<int>(
    'cached_at_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scopeKey,
    orderCode,
    customerName,
    customerPhone,
    locationId,
    locationName,
    status,
    itemsJson,
    subtotal,
    discountAmount,
    taxAmount,
    totalAmount,
    cashAmount,
    bankAmount,
    debtAmount,
    debtorId,
    note,
    createdAtEpoch,
    updatedAtEpoch,
    completedAtEpoch,
    cancelledAtEpoch,
    cancelReason,
    invoiceNumber,
    invoicedAtEpoch,
    cachedAtEpoch,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrdersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('order_code')) {
      context.handle(
        _orderCodeMeta,
        orderCode.isAcceptableOrUnknown(data['order_code']!, _orderCodeMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('customer_phone')) {
      context.handle(
        _customerPhoneMeta,
        customerPhone.isAcceptableOrUnknown(
          data['customer_phone']!,
          _customerPhoneMeta,
        ),
      );
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_locationIdMeta);
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
        _discountAmountMeta,
        discountAmount.isAcceptableOrUnknown(
          data['discount_amount']!,
          _discountAmountMeta,
        ),
      );
    }
    if (data.containsKey('tax_amount')) {
      context.handle(
        _taxAmountMeta,
        taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('cash_amount')) {
      context.handle(
        _cashAmountMeta,
        cashAmount.isAcceptableOrUnknown(data['cash_amount']!, _cashAmountMeta),
      );
    }
    if (data.containsKey('bank_amount')) {
      context.handle(
        _bankAmountMeta,
        bankAmount.isAcceptableOrUnknown(data['bank_amount']!, _bankAmountMeta),
      );
    }
    if (data.containsKey('debt_amount')) {
      context.handle(
        _debtAmountMeta,
        debtAmount.isAcceptableOrUnknown(data['debt_amount']!, _debtAmountMeta),
      );
    }
    if (data.containsKey('debtor_id')) {
      context.handle(
        _debtorIdMeta,
        debtorId.isAcceptableOrUnknown(data['debtor_id']!, _debtorIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at_epoch')) {
      context.handle(
        _createdAtEpochMeta,
        createdAtEpoch.isAcceptableOrUnknown(
          data['created_at_epoch']!,
          _createdAtEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtEpochMeta);
    }
    if (data.containsKey('updated_at_epoch')) {
      context.handle(
        _updatedAtEpochMeta,
        updatedAtEpoch.isAcceptableOrUnknown(
          data['updated_at_epoch']!,
          _updatedAtEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtEpochMeta);
    }
    if (data.containsKey('completed_at_epoch')) {
      context.handle(
        _completedAtEpochMeta,
        completedAtEpoch.isAcceptableOrUnknown(
          data['completed_at_epoch']!,
          _completedAtEpochMeta,
        ),
      );
    }
    if (data.containsKey('cancelled_at_epoch')) {
      context.handle(
        _cancelledAtEpochMeta,
        cancelledAtEpoch.isAcceptableOrUnknown(
          data['cancelled_at_epoch']!,
          _cancelledAtEpochMeta,
        ),
      );
    }
    if (data.containsKey('cancel_reason')) {
      context.handle(
        _cancelReasonMeta,
        cancelReason.isAcceptableOrUnknown(
          data['cancel_reason']!,
          _cancelReasonMeta,
        ),
      );
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
        _invoiceNumberMeta,
        invoiceNumber.isAcceptableOrUnknown(
          data['invoice_number']!,
          _invoiceNumberMeta,
        ),
      );
    }
    if (data.containsKey('invoiced_at_epoch')) {
      context.handle(
        _invoicedAtEpochMeta,
        invoicedAtEpoch.isAcceptableOrUnknown(
          data['invoiced_at_epoch']!,
          _invoicedAtEpochMeta,
        ),
      );
    }
    if (data.containsKey('cached_at_epoch')) {
      context.handle(
        _cachedAtEpochMeta,
        cachedAtEpoch.isAcceptableOrUnknown(
          data['cached_at_epoch']!,
          _cachedAtEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedAtEpochMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, scopeKey};
  @override
  OrdersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrdersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      orderCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_code'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      customerPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_phone'],
      ),
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_id'],
      )!,
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      discountAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_amount'],
      )!,
      taxAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax_amount'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      cashAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_amount'],
      )!,
      bankAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bank_amount'],
      )!,
      debtAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}debt_amount'],
      )!,
      debtorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}debtor_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_epoch'],
      )!,
      updatedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_epoch'],
      )!,
      completedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at_epoch'],
      ),
      cancelledAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cancelled_at_epoch'],
      ),
      cancelReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cancel_reason'],
      ),
      invoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_number'],
      ),
      invoicedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}invoiced_at_epoch'],
      ),
      cachedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at_epoch'],
      )!,
    );
  }

  @override
  $OrdersTableTable createAlias(String alias) {
    return $OrdersTableTable(attachedDatabase, alias);
  }
}

class OrdersTableData extends DataClass implements Insertable<OrdersTableData> {
  final String id;
  final String scopeKey;
  final String orderCode;
  final String? customerName;
  final String? customerPhone;
  final String locationId;
  final String locationName;
  final String status;
  final String itemsJson;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double cashAmount;
  final double bankAmount;
  final double debtAmount;
  final int? debtorId;
  final String? note;
  final int createdAtEpoch;
  final int updatedAtEpoch;
  final int? completedAtEpoch;
  final int? cancelledAtEpoch;
  final String? cancelReason;
  final String? invoiceNumber;
  final int? invoicedAtEpoch;
  final int cachedAtEpoch;
  const OrdersTableData({
    required this.id,
    required this.scopeKey,
    required this.orderCode,
    this.customerName,
    this.customerPhone,
    required this.locationId,
    required this.locationName,
    required this.status,
    required this.itemsJson,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.cashAmount,
    required this.bankAmount,
    required this.debtAmount,
    this.debtorId,
    this.note,
    required this.createdAtEpoch,
    required this.updatedAtEpoch,
    this.completedAtEpoch,
    this.cancelledAtEpoch,
    this.cancelReason,
    this.invoiceNumber,
    this.invoicedAtEpoch,
    required this.cachedAtEpoch,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope_key'] = Variable<String>(scopeKey);
    map['order_code'] = Variable<String>(orderCode);
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || customerPhone != null) {
      map['customer_phone'] = Variable<String>(customerPhone);
    }
    map['location_id'] = Variable<String>(locationId);
    map['location_name'] = Variable<String>(locationName);
    map['status'] = Variable<String>(status);
    map['items_json'] = Variable<String>(itemsJson);
    map['subtotal'] = Variable<double>(subtotal);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['tax_amount'] = Variable<double>(taxAmount);
    map['total_amount'] = Variable<double>(totalAmount);
    map['cash_amount'] = Variable<double>(cashAmount);
    map['bank_amount'] = Variable<double>(bankAmount);
    map['debt_amount'] = Variable<double>(debtAmount);
    if (!nullToAbsent || debtorId != null) {
      map['debtor_id'] = Variable<int>(debtorId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at_epoch'] = Variable<int>(createdAtEpoch);
    map['updated_at_epoch'] = Variable<int>(updatedAtEpoch);
    if (!nullToAbsent || completedAtEpoch != null) {
      map['completed_at_epoch'] = Variable<int>(completedAtEpoch);
    }
    if (!nullToAbsent || cancelledAtEpoch != null) {
      map['cancelled_at_epoch'] = Variable<int>(cancelledAtEpoch);
    }
    if (!nullToAbsent || cancelReason != null) {
      map['cancel_reason'] = Variable<String>(cancelReason);
    }
    if (!nullToAbsent || invoiceNumber != null) {
      map['invoice_number'] = Variable<String>(invoiceNumber);
    }
    if (!nullToAbsent || invoicedAtEpoch != null) {
      map['invoiced_at_epoch'] = Variable<int>(invoicedAtEpoch);
    }
    map['cached_at_epoch'] = Variable<int>(cachedAtEpoch);
    return map;
  }

  OrdersTableCompanion toCompanion(bool nullToAbsent) {
    return OrdersTableCompanion(
      id: Value(id),
      scopeKey: Value(scopeKey),
      orderCode: Value(orderCode),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      customerPhone: customerPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(customerPhone),
      locationId: Value(locationId),
      locationName: Value(locationName),
      status: Value(status),
      itemsJson: Value(itemsJson),
      subtotal: Value(subtotal),
      discountAmount: Value(discountAmount),
      taxAmount: Value(taxAmount),
      totalAmount: Value(totalAmount),
      cashAmount: Value(cashAmount),
      bankAmount: Value(bankAmount),
      debtAmount: Value(debtAmount),
      debtorId: debtorId == null && nullToAbsent
          ? const Value.absent()
          : Value(debtorId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAtEpoch: Value(createdAtEpoch),
      updatedAtEpoch: Value(updatedAtEpoch),
      completedAtEpoch: completedAtEpoch == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAtEpoch),
      cancelledAtEpoch: cancelledAtEpoch == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledAtEpoch),
      cancelReason: cancelReason == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelReason),
      invoiceNumber: invoiceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceNumber),
      invoicedAtEpoch: invoicedAtEpoch == null && nullToAbsent
          ? const Value.absent()
          : Value(invoicedAtEpoch),
      cachedAtEpoch: Value(cachedAtEpoch),
    );
  }

  factory OrdersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrdersTableData(
      id: serializer.fromJson<String>(json['id']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      orderCode: serializer.fromJson<String>(json['orderCode']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      customerPhone: serializer.fromJson<String?>(json['customerPhone']),
      locationId: serializer.fromJson<String>(json['locationId']),
      locationName: serializer.fromJson<String>(json['locationName']),
      status: serializer.fromJson<String>(json['status']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      taxAmount: serializer.fromJson<double>(json['taxAmount']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      cashAmount: serializer.fromJson<double>(json['cashAmount']),
      bankAmount: serializer.fromJson<double>(json['bankAmount']),
      debtAmount: serializer.fromJson<double>(json['debtAmount']),
      debtorId: serializer.fromJson<int?>(json['debtorId']),
      note: serializer.fromJson<String?>(json['note']),
      createdAtEpoch: serializer.fromJson<int>(json['createdAtEpoch']),
      updatedAtEpoch: serializer.fromJson<int>(json['updatedAtEpoch']),
      completedAtEpoch: serializer.fromJson<int?>(json['completedAtEpoch']),
      cancelledAtEpoch: serializer.fromJson<int?>(json['cancelledAtEpoch']),
      cancelReason: serializer.fromJson<String?>(json['cancelReason']),
      invoiceNumber: serializer.fromJson<String?>(json['invoiceNumber']),
      invoicedAtEpoch: serializer.fromJson<int?>(json['invoicedAtEpoch']),
      cachedAtEpoch: serializer.fromJson<int>(json['cachedAtEpoch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'orderCode': serializer.toJson<String>(orderCode),
      'customerName': serializer.toJson<String?>(customerName),
      'customerPhone': serializer.toJson<String?>(customerPhone),
      'locationId': serializer.toJson<String>(locationId),
      'locationName': serializer.toJson<String>(locationName),
      'status': serializer.toJson<String>(status),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'subtotal': serializer.toJson<double>(subtotal),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'taxAmount': serializer.toJson<double>(taxAmount),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'cashAmount': serializer.toJson<double>(cashAmount),
      'bankAmount': serializer.toJson<double>(bankAmount),
      'debtAmount': serializer.toJson<double>(debtAmount),
      'debtorId': serializer.toJson<int?>(debtorId),
      'note': serializer.toJson<String?>(note),
      'createdAtEpoch': serializer.toJson<int>(createdAtEpoch),
      'updatedAtEpoch': serializer.toJson<int>(updatedAtEpoch),
      'completedAtEpoch': serializer.toJson<int?>(completedAtEpoch),
      'cancelledAtEpoch': serializer.toJson<int?>(cancelledAtEpoch),
      'cancelReason': serializer.toJson<String?>(cancelReason),
      'invoiceNumber': serializer.toJson<String?>(invoiceNumber),
      'invoicedAtEpoch': serializer.toJson<int?>(invoicedAtEpoch),
      'cachedAtEpoch': serializer.toJson<int>(cachedAtEpoch),
    };
  }

  OrdersTableData copyWith({
    String? id,
    String? scopeKey,
    String? orderCode,
    Value<String?> customerName = const Value.absent(),
    Value<String?> customerPhone = const Value.absent(),
    String? locationId,
    String? locationName,
    String? status,
    String? itemsJson,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? totalAmount,
    double? cashAmount,
    double? bankAmount,
    double? debtAmount,
    Value<int?> debtorId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? createdAtEpoch,
    int? updatedAtEpoch,
    Value<int?> completedAtEpoch = const Value.absent(),
    Value<int?> cancelledAtEpoch = const Value.absent(),
    Value<String?> cancelReason = const Value.absent(),
    Value<String?> invoiceNumber = const Value.absent(),
    Value<int?> invoicedAtEpoch = const Value.absent(),
    int? cachedAtEpoch,
  }) => OrdersTableData(
    id: id ?? this.id,
    scopeKey: scopeKey ?? this.scopeKey,
    orderCode: orderCode ?? this.orderCode,
    customerName: customerName.present ? customerName.value : this.customerName,
    customerPhone: customerPhone.present
        ? customerPhone.value
        : this.customerPhone,
    locationId: locationId ?? this.locationId,
    locationName: locationName ?? this.locationName,
    status: status ?? this.status,
    itemsJson: itemsJson ?? this.itemsJson,
    subtotal: subtotal ?? this.subtotal,
    discountAmount: discountAmount ?? this.discountAmount,
    taxAmount: taxAmount ?? this.taxAmount,
    totalAmount: totalAmount ?? this.totalAmount,
    cashAmount: cashAmount ?? this.cashAmount,
    bankAmount: bankAmount ?? this.bankAmount,
    debtAmount: debtAmount ?? this.debtAmount,
    debtorId: debtorId.present ? debtorId.value : this.debtorId,
    note: note.present ? note.value : this.note,
    createdAtEpoch: createdAtEpoch ?? this.createdAtEpoch,
    updatedAtEpoch: updatedAtEpoch ?? this.updatedAtEpoch,
    completedAtEpoch: completedAtEpoch.present
        ? completedAtEpoch.value
        : this.completedAtEpoch,
    cancelledAtEpoch: cancelledAtEpoch.present
        ? cancelledAtEpoch.value
        : this.cancelledAtEpoch,
    cancelReason: cancelReason.present ? cancelReason.value : this.cancelReason,
    invoiceNumber: invoiceNumber.present
        ? invoiceNumber.value
        : this.invoiceNumber,
    invoicedAtEpoch: invoicedAtEpoch.present
        ? invoicedAtEpoch.value
        : this.invoicedAtEpoch,
    cachedAtEpoch: cachedAtEpoch ?? this.cachedAtEpoch,
  );
  OrdersTableData copyWithCompanion(OrdersTableCompanion data) {
    return OrdersTableData(
      id: data.id.present ? data.id.value : this.id,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      orderCode: data.orderCode.present ? data.orderCode.value : this.orderCode,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerPhone: data.customerPhone.present
          ? data.customerPhone.value
          : this.customerPhone,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      status: data.status.present ? data.status.value : this.status,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      cashAmount: data.cashAmount.present
          ? data.cashAmount.value
          : this.cashAmount,
      bankAmount: data.bankAmount.present
          ? data.bankAmount.value
          : this.bankAmount,
      debtAmount: data.debtAmount.present
          ? data.debtAmount.value
          : this.debtAmount,
      debtorId: data.debtorId.present ? data.debtorId.value : this.debtorId,
      note: data.note.present ? data.note.value : this.note,
      createdAtEpoch: data.createdAtEpoch.present
          ? data.createdAtEpoch.value
          : this.createdAtEpoch,
      updatedAtEpoch: data.updatedAtEpoch.present
          ? data.updatedAtEpoch.value
          : this.updatedAtEpoch,
      completedAtEpoch: data.completedAtEpoch.present
          ? data.completedAtEpoch.value
          : this.completedAtEpoch,
      cancelledAtEpoch: data.cancelledAtEpoch.present
          ? data.cancelledAtEpoch.value
          : this.cancelledAtEpoch,
      cancelReason: data.cancelReason.present
          ? data.cancelReason.value
          : this.cancelReason,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      invoicedAtEpoch: data.invoicedAtEpoch.present
          ? data.invoicedAtEpoch.value
          : this.invoicedAtEpoch,
      cachedAtEpoch: data.cachedAtEpoch.present
          ? data.cachedAtEpoch.value
          : this.cachedAtEpoch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrdersTableData(')
          ..write('id: $id, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('orderCode: $orderCode, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('locationId: $locationId, ')
          ..write('locationName: $locationName, ')
          ..write('status: $status, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('cashAmount: $cashAmount, ')
          ..write('bankAmount: $bankAmount, ')
          ..write('debtAmount: $debtAmount, ')
          ..write('debtorId: $debtorId, ')
          ..write('note: $note, ')
          ..write('createdAtEpoch: $createdAtEpoch, ')
          ..write('updatedAtEpoch: $updatedAtEpoch, ')
          ..write('completedAtEpoch: $completedAtEpoch, ')
          ..write('cancelledAtEpoch: $cancelledAtEpoch, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('invoicedAtEpoch: $invoicedAtEpoch, ')
          ..write('cachedAtEpoch: $cachedAtEpoch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    scopeKey,
    orderCode,
    customerName,
    customerPhone,
    locationId,
    locationName,
    status,
    itemsJson,
    subtotal,
    discountAmount,
    taxAmount,
    totalAmount,
    cashAmount,
    bankAmount,
    debtAmount,
    debtorId,
    note,
    createdAtEpoch,
    updatedAtEpoch,
    completedAtEpoch,
    cancelledAtEpoch,
    cancelReason,
    invoiceNumber,
    invoicedAtEpoch,
    cachedAtEpoch,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrdersTableData &&
          other.id == this.id &&
          other.scopeKey == this.scopeKey &&
          other.orderCode == this.orderCode &&
          other.customerName == this.customerName &&
          other.customerPhone == this.customerPhone &&
          other.locationId == this.locationId &&
          other.locationName == this.locationName &&
          other.status == this.status &&
          other.itemsJson == this.itemsJson &&
          other.subtotal == this.subtotal &&
          other.discountAmount == this.discountAmount &&
          other.taxAmount == this.taxAmount &&
          other.totalAmount == this.totalAmount &&
          other.cashAmount == this.cashAmount &&
          other.bankAmount == this.bankAmount &&
          other.debtAmount == this.debtAmount &&
          other.debtorId == this.debtorId &&
          other.note == this.note &&
          other.createdAtEpoch == this.createdAtEpoch &&
          other.updatedAtEpoch == this.updatedAtEpoch &&
          other.completedAtEpoch == this.completedAtEpoch &&
          other.cancelledAtEpoch == this.cancelledAtEpoch &&
          other.cancelReason == this.cancelReason &&
          other.invoiceNumber == this.invoiceNumber &&
          other.invoicedAtEpoch == this.invoicedAtEpoch &&
          other.cachedAtEpoch == this.cachedAtEpoch);
}

class OrdersTableCompanion extends UpdateCompanion<OrdersTableData> {
  final Value<String> id;
  final Value<String> scopeKey;
  final Value<String> orderCode;
  final Value<String?> customerName;
  final Value<String?> customerPhone;
  final Value<String> locationId;
  final Value<String> locationName;
  final Value<String> status;
  final Value<String> itemsJson;
  final Value<double> subtotal;
  final Value<double> discountAmount;
  final Value<double> taxAmount;
  final Value<double> totalAmount;
  final Value<double> cashAmount;
  final Value<double> bankAmount;
  final Value<double> debtAmount;
  final Value<int?> debtorId;
  final Value<String?> note;
  final Value<int> createdAtEpoch;
  final Value<int> updatedAtEpoch;
  final Value<int?> completedAtEpoch;
  final Value<int?> cancelledAtEpoch;
  final Value<String?> cancelReason;
  final Value<String?> invoiceNumber;
  final Value<int?> invoicedAtEpoch;
  final Value<int> cachedAtEpoch;
  final Value<int> rowid;
  const OrdersTableCompanion({
    this.id = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.orderCode = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.locationId = const Value.absent(),
    this.locationName = const Value.absent(),
    this.status = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.cashAmount = const Value.absent(),
    this.bankAmount = const Value.absent(),
    this.debtAmount = const Value.absent(),
    this.debtorId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAtEpoch = const Value.absent(),
    this.updatedAtEpoch = const Value.absent(),
    this.completedAtEpoch = const Value.absent(),
    this.cancelledAtEpoch = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.invoicedAtEpoch = const Value.absent(),
    this.cachedAtEpoch = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersTableCompanion.insert({
    required String id,
    required String scopeKey,
    this.orderCode = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    required String locationId,
    this.locationName = const Value.absent(),
    required String status,
    this.itemsJson = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.cashAmount = const Value.absent(),
    this.bankAmount = const Value.absent(),
    this.debtAmount = const Value.absent(),
    this.debtorId = const Value.absent(),
    this.note = const Value.absent(),
    required int createdAtEpoch,
    required int updatedAtEpoch,
    this.completedAtEpoch = const Value.absent(),
    this.cancelledAtEpoch = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.invoicedAtEpoch = const Value.absent(),
    required int cachedAtEpoch,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scopeKey = Value(scopeKey),
       locationId = Value(locationId),
       status = Value(status),
       createdAtEpoch = Value(createdAtEpoch),
       updatedAtEpoch = Value(updatedAtEpoch),
       cachedAtEpoch = Value(cachedAtEpoch);
  static Insertable<OrdersTableData> custom({
    Expression<String>? id,
    Expression<String>? scopeKey,
    Expression<String>? orderCode,
    Expression<String>? customerName,
    Expression<String>? customerPhone,
    Expression<String>? locationId,
    Expression<String>? locationName,
    Expression<String>? status,
    Expression<String>? itemsJson,
    Expression<double>? subtotal,
    Expression<double>? discountAmount,
    Expression<double>? taxAmount,
    Expression<double>? totalAmount,
    Expression<double>? cashAmount,
    Expression<double>? bankAmount,
    Expression<double>? debtAmount,
    Expression<int>? debtorId,
    Expression<String>? note,
    Expression<int>? createdAtEpoch,
    Expression<int>? updatedAtEpoch,
    Expression<int>? completedAtEpoch,
    Expression<int>? cancelledAtEpoch,
    Expression<String>? cancelReason,
    Expression<String>? invoiceNumber,
    Expression<int>? invoicedAtEpoch,
    Expression<int>? cachedAtEpoch,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (orderCode != null) 'order_code': orderCode,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (locationId != null) 'location_id': locationId,
      if (locationName != null) 'location_name': locationName,
      if (status != null) 'status': status,
      if (itemsJson != null) 'items_json': itemsJson,
      if (subtotal != null) 'subtotal': subtotal,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (cashAmount != null) 'cash_amount': cashAmount,
      if (bankAmount != null) 'bank_amount': bankAmount,
      if (debtAmount != null) 'debt_amount': debtAmount,
      if (debtorId != null) 'debtor_id': debtorId,
      if (note != null) 'note': note,
      if (createdAtEpoch != null) 'created_at_epoch': createdAtEpoch,
      if (updatedAtEpoch != null) 'updated_at_epoch': updatedAtEpoch,
      if (completedAtEpoch != null) 'completed_at_epoch': completedAtEpoch,
      if (cancelledAtEpoch != null) 'cancelled_at_epoch': cancelledAtEpoch,
      if (cancelReason != null) 'cancel_reason': cancelReason,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (invoicedAtEpoch != null) 'invoiced_at_epoch': invoicedAtEpoch,
      if (cachedAtEpoch != null) 'cached_at_epoch': cachedAtEpoch,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? scopeKey,
    Value<String>? orderCode,
    Value<String?>? customerName,
    Value<String?>? customerPhone,
    Value<String>? locationId,
    Value<String>? locationName,
    Value<String>? status,
    Value<String>? itemsJson,
    Value<double>? subtotal,
    Value<double>? discountAmount,
    Value<double>? taxAmount,
    Value<double>? totalAmount,
    Value<double>? cashAmount,
    Value<double>? bankAmount,
    Value<double>? debtAmount,
    Value<int?>? debtorId,
    Value<String?>? note,
    Value<int>? createdAtEpoch,
    Value<int>? updatedAtEpoch,
    Value<int?>? completedAtEpoch,
    Value<int?>? cancelledAtEpoch,
    Value<String?>? cancelReason,
    Value<String?>? invoiceNumber,
    Value<int?>? invoicedAtEpoch,
    Value<int>? cachedAtEpoch,
    Value<int>? rowid,
  }) {
    return OrdersTableCompanion(
      id: id ?? this.id,
      scopeKey: scopeKey ?? this.scopeKey,
      orderCode: orderCode ?? this.orderCode,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      status: status ?? this.status,
      itemsJson: itemsJson ?? this.itemsJson,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      cashAmount: cashAmount ?? this.cashAmount,
      bankAmount: bankAmount ?? this.bankAmount,
      debtAmount: debtAmount ?? this.debtAmount,
      debtorId: debtorId ?? this.debtorId,
      note: note ?? this.note,
      createdAtEpoch: createdAtEpoch ?? this.createdAtEpoch,
      updatedAtEpoch: updatedAtEpoch ?? this.updatedAtEpoch,
      completedAtEpoch: completedAtEpoch ?? this.completedAtEpoch,
      cancelledAtEpoch: cancelledAtEpoch ?? this.cancelledAtEpoch,
      cancelReason: cancelReason ?? this.cancelReason,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoicedAtEpoch: invoicedAtEpoch ?? this.invoicedAtEpoch,
      cachedAtEpoch: cachedAtEpoch ?? this.cachedAtEpoch,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (orderCode.present) {
      map['order_code'] = Variable<String>(orderCode.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerPhone.present) {
      map['customer_phone'] = Variable<String>(customerPhone.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<double>(taxAmount.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (cashAmount.present) {
      map['cash_amount'] = Variable<double>(cashAmount.value);
    }
    if (bankAmount.present) {
      map['bank_amount'] = Variable<double>(bankAmount.value);
    }
    if (debtAmount.present) {
      map['debt_amount'] = Variable<double>(debtAmount.value);
    }
    if (debtorId.present) {
      map['debtor_id'] = Variable<int>(debtorId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAtEpoch.present) {
      map['created_at_epoch'] = Variable<int>(createdAtEpoch.value);
    }
    if (updatedAtEpoch.present) {
      map['updated_at_epoch'] = Variable<int>(updatedAtEpoch.value);
    }
    if (completedAtEpoch.present) {
      map['completed_at_epoch'] = Variable<int>(completedAtEpoch.value);
    }
    if (cancelledAtEpoch.present) {
      map['cancelled_at_epoch'] = Variable<int>(cancelledAtEpoch.value);
    }
    if (cancelReason.present) {
      map['cancel_reason'] = Variable<String>(cancelReason.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (invoicedAtEpoch.present) {
      map['invoiced_at_epoch'] = Variable<int>(invoicedAtEpoch.value);
    }
    if (cachedAtEpoch.present) {
      map['cached_at_epoch'] = Variable<int>(cachedAtEpoch.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersTableCompanion(')
          ..write('id: $id, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('orderCode: $orderCode, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('locationId: $locationId, ')
          ..write('locationName: $locationName, ')
          ..write('status: $status, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('cashAmount: $cashAmount, ')
          ..write('bankAmount: $bankAmount, ')
          ..write('debtAmount: $debtAmount, ')
          ..write('debtorId: $debtorId, ')
          ..write('note: $note, ')
          ..write('createdAtEpoch: $createdAtEpoch, ')
          ..write('updatedAtEpoch: $updatedAtEpoch, ')
          ..write('completedAtEpoch: $completedAtEpoch, ')
          ..write('cancelledAtEpoch: $cancelledAtEpoch, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('invoicedAtEpoch: $invoicedAtEpoch, ')
          ..write('cachedAtEpoch: $cachedAtEpoch, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportsTableTable extends ImportsTable
    with TableInfo<$ImportsTableTable, ImportsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importCodeMeta = const VerificationMeta(
    'importCode',
  );
  @override
  late final GeneratedColumn<String> importCode = GeneratedColumn<String>(
    'import_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _importTypeMeta = const VerificationMeta(
    'importType',
  );
  @override
  late final GeneratedColumn<String> importType = GeneratedColumn<String>(
    'import_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _businessLocationIdMeta =
      const VerificationMeta('businessLocationId');
  @override
  late final GeneratedColumn<int> businessLocationId = GeneratedColumn<int>(
    'business_location_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessLocationNameMeta =
      const VerificationMeta('businessLocationName');
  @override
  late final GeneratedColumn<String> businessLocationName =
      GeneratedColumn<String>(
        'business_location_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _supplierMeta = const VerificationMeta(
    'supplier',
  );
  @override
  late final GeneratedColumn<String> supplier = GeneratedColumn<String>(
    'supplier',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receivedAtEpochMeta = const VerificationMeta(
    'receivedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> receivedAtEpoch = GeneratedColumn<int>(
    'received_at_epoch',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _createdAtEpochMeta = const VerificationMeta(
    'createdAtEpoch',
  );
  @override
  late final GeneratedColumn<int> createdAtEpoch = GeneratedColumn<int>(
    'created_at_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtEpochMeta = const VerificationMeta(
    'updatedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> updatedAtEpoch = GeneratedColumn<int>(
    'updated_at_epoch',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _cachedAtEpochMeta = const VerificationMeta(
    'cachedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> cachedAtEpoch = GeneratedColumn<int>(
    'cached_at_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scopeKey,
    importCode,
    importType,
    status,
    businessLocationId,
    businessLocationName,
    supplier,
    note,
    receivedAtEpoch,
    totalAmount,
    createdAtEpoch,
    updatedAtEpoch,
    imageUrl,
    itemsJson,
    cachedAtEpoch,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'imports_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('import_code')) {
      context.handle(
        _importCodeMeta,
        importCode.isAcceptableOrUnknown(data['import_code']!, _importCodeMeta),
      );
    }
    if (data.containsKey('import_type')) {
      context.handle(
        _importTypeMeta,
        importType.isAcceptableOrUnknown(data['import_type']!, _importTypeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('business_location_id')) {
      context.handle(
        _businessLocationIdMeta,
        businessLocationId.isAcceptableOrUnknown(
          data['business_location_id']!,
          _businessLocationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessLocationIdMeta);
    }
    if (data.containsKey('business_location_name')) {
      context.handle(
        _businessLocationNameMeta,
        businessLocationName.isAcceptableOrUnknown(
          data['business_location_name']!,
          _businessLocationNameMeta,
        ),
      );
    }
    if (data.containsKey('supplier')) {
      context.handle(
        _supplierMeta,
        supplier.isAcceptableOrUnknown(data['supplier']!, _supplierMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('received_at_epoch')) {
      context.handle(
        _receivedAtEpochMeta,
        receivedAtEpoch.isAcceptableOrUnknown(
          data['received_at_epoch']!,
          _receivedAtEpochMeta,
        ),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('created_at_epoch')) {
      context.handle(
        _createdAtEpochMeta,
        createdAtEpoch.isAcceptableOrUnknown(
          data['created_at_epoch']!,
          _createdAtEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtEpochMeta);
    }
    if (data.containsKey('updated_at_epoch')) {
      context.handle(
        _updatedAtEpochMeta,
        updatedAtEpoch.isAcceptableOrUnknown(
          data['updated_at_epoch']!,
          _updatedAtEpochMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    }
    if (data.containsKey('cached_at_epoch')) {
      context.handle(
        _cachedAtEpochMeta,
        cachedAtEpoch.isAcceptableOrUnknown(
          data['cached_at_epoch']!,
          _cachedAtEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedAtEpochMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, scopeKey};
  @override
  ImportsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      importCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}import_code'],
      )!,
      importType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}import_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      businessLocationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}business_location_id'],
      )!,
      businessLocationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_location_name'],
      )!,
      supplier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      receivedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_at_epoch'],
      ),
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      createdAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_epoch'],
      )!,
      updatedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_epoch'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
      cachedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at_epoch'],
      )!,
    );
  }

  @override
  $ImportsTableTable createAlias(String alias) {
    return $ImportsTableTable(attachedDatabase, alias);
  }
}

class ImportsTableData extends DataClass
    implements Insertable<ImportsTableData> {
  final int id;
  final String scopeKey;
  final String importCode;
  final String importType;
  final String status;
  final int businessLocationId;
  final String businessLocationName;
  final String? supplier;
  final String? note;
  final int? receivedAtEpoch;
  final double totalAmount;
  final int createdAtEpoch;
  final int? updatedAtEpoch;
  final String? imageUrl;
  final String itemsJson;
  final int cachedAtEpoch;
  const ImportsTableData({
    required this.id,
    required this.scopeKey,
    required this.importCode,
    required this.importType,
    required this.status,
    required this.businessLocationId,
    required this.businessLocationName,
    this.supplier,
    this.note,
    this.receivedAtEpoch,
    required this.totalAmount,
    required this.createdAtEpoch,
    this.updatedAtEpoch,
    this.imageUrl,
    required this.itemsJson,
    required this.cachedAtEpoch,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['scope_key'] = Variable<String>(scopeKey);
    map['import_code'] = Variable<String>(importCode);
    map['import_type'] = Variable<String>(importType);
    map['status'] = Variable<String>(status);
    map['business_location_id'] = Variable<int>(businessLocationId);
    map['business_location_name'] = Variable<String>(businessLocationName);
    if (!nullToAbsent || supplier != null) {
      map['supplier'] = Variable<String>(supplier);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || receivedAtEpoch != null) {
      map['received_at_epoch'] = Variable<int>(receivedAtEpoch);
    }
    map['total_amount'] = Variable<double>(totalAmount);
    map['created_at_epoch'] = Variable<int>(createdAtEpoch);
    if (!nullToAbsent || updatedAtEpoch != null) {
      map['updated_at_epoch'] = Variable<int>(updatedAtEpoch);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['items_json'] = Variable<String>(itemsJson);
    map['cached_at_epoch'] = Variable<int>(cachedAtEpoch);
    return map;
  }

  ImportsTableCompanion toCompanion(bool nullToAbsent) {
    return ImportsTableCompanion(
      id: Value(id),
      scopeKey: Value(scopeKey),
      importCode: Value(importCode),
      importType: Value(importType),
      status: Value(status),
      businessLocationId: Value(businessLocationId),
      businessLocationName: Value(businessLocationName),
      supplier: supplier == null && nullToAbsent
          ? const Value.absent()
          : Value(supplier),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      receivedAtEpoch: receivedAtEpoch == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedAtEpoch),
      totalAmount: Value(totalAmount),
      createdAtEpoch: Value(createdAtEpoch),
      updatedAtEpoch: updatedAtEpoch == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAtEpoch),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      itemsJson: Value(itemsJson),
      cachedAtEpoch: Value(cachedAtEpoch),
    );
  }

  factory ImportsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportsTableData(
      id: serializer.fromJson<int>(json['id']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      importCode: serializer.fromJson<String>(json['importCode']),
      importType: serializer.fromJson<String>(json['importType']),
      status: serializer.fromJson<String>(json['status']),
      businessLocationId: serializer.fromJson<int>(json['businessLocationId']),
      businessLocationName: serializer.fromJson<String>(
        json['businessLocationName'],
      ),
      supplier: serializer.fromJson<String?>(json['supplier']),
      note: serializer.fromJson<String?>(json['note']),
      receivedAtEpoch: serializer.fromJson<int?>(json['receivedAtEpoch']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      createdAtEpoch: serializer.fromJson<int>(json['createdAtEpoch']),
      updatedAtEpoch: serializer.fromJson<int?>(json['updatedAtEpoch']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      cachedAtEpoch: serializer.fromJson<int>(json['cachedAtEpoch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'importCode': serializer.toJson<String>(importCode),
      'importType': serializer.toJson<String>(importType),
      'status': serializer.toJson<String>(status),
      'businessLocationId': serializer.toJson<int>(businessLocationId),
      'businessLocationName': serializer.toJson<String>(businessLocationName),
      'supplier': serializer.toJson<String?>(supplier),
      'note': serializer.toJson<String?>(note),
      'receivedAtEpoch': serializer.toJson<int?>(receivedAtEpoch),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'createdAtEpoch': serializer.toJson<int>(createdAtEpoch),
      'updatedAtEpoch': serializer.toJson<int?>(updatedAtEpoch),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'cachedAtEpoch': serializer.toJson<int>(cachedAtEpoch),
    };
  }

  ImportsTableData copyWith({
    int? id,
    String? scopeKey,
    String? importCode,
    String? importType,
    String? status,
    int? businessLocationId,
    String? businessLocationName,
    Value<String?> supplier = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<int?> receivedAtEpoch = const Value.absent(),
    double? totalAmount,
    int? createdAtEpoch,
    Value<int?> updatedAtEpoch = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    String? itemsJson,
    int? cachedAtEpoch,
  }) => ImportsTableData(
    id: id ?? this.id,
    scopeKey: scopeKey ?? this.scopeKey,
    importCode: importCode ?? this.importCode,
    importType: importType ?? this.importType,
    status: status ?? this.status,
    businessLocationId: businessLocationId ?? this.businessLocationId,
    businessLocationName: businessLocationName ?? this.businessLocationName,
    supplier: supplier.present ? supplier.value : this.supplier,
    note: note.present ? note.value : this.note,
    receivedAtEpoch: receivedAtEpoch.present
        ? receivedAtEpoch.value
        : this.receivedAtEpoch,
    totalAmount: totalAmount ?? this.totalAmount,
    createdAtEpoch: createdAtEpoch ?? this.createdAtEpoch,
    updatedAtEpoch: updatedAtEpoch.present
        ? updatedAtEpoch.value
        : this.updatedAtEpoch,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    itemsJson: itemsJson ?? this.itemsJson,
    cachedAtEpoch: cachedAtEpoch ?? this.cachedAtEpoch,
  );
  ImportsTableData copyWithCompanion(ImportsTableCompanion data) {
    return ImportsTableData(
      id: data.id.present ? data.id.value : this.id,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      importCode: data.importCode.present
          ? data.importCode.value
          : this.importCode,
      importType: data.importType.present
          ? data.importType.value
          : this.importType,
      status: data.status.present ? data.status.value : this.status,
      businessLocationId: data.businessLocationId.present
          ? data.businessLocationId.value
          : this.businessLocationId,
      businessLocationName: data.businessLocationName.present
          ? data.businessLocationName.value
          : this.businessLocationName,
      supplier: data.supplier.present ? data.supplier.value : this.supplier,
      note: data.note.present ? data.note.value : this.note,
      receivedAtEpoch: data.receivedAtEpoch.present
          ? data.receivedAtEpoch.value
          : this.receivedAtEpoch,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      createdAtEpoch: data.createdAtEpoch.present
          ? data.createdAtEpoch.value
          : this.createdAtEpoch,
      updatedAtEpoch: data.updatedAtEpoch.present
          ? data.updatedAtEpoch.value
          : this.updatedAtEpoch,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      cachedAtEpoch: data.cachedAtEpoch.present
          ? data.cachedAtEpoch.value
          : this.cachedAtEpoch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportsTableData(')
          ..write('id: $id, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('importCode: $importCode, ')
          ..write('importType: $importType, ')
          ..write('status: $status, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('businessLocationName: $businessLocationName, ')
          ..write('supplier: $supplier, ')
          ..write('note: $note, ')
          ..write('receivedAtEpoch: $receivedAtEpoch, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('createdAtEpoch: $createdAtEpoch, ')
          ..write('updatedAtEpoch: $updatedAtEpoch, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('cachedAtEpoch: $cachedAtEpoch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scopeKey,
    importCode,
    importType,
    status,
    businessLocationId,
    businessLocationName,
    supplier,
    note,
    receivedAtEpoch,
    totalAmount,
    createdAtEpoch,
    updatedAtEpoch,
    imageUrl,
    itemsJson,
    cachedAtEpoch,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportsTableData &&
          other.id == this.id &&
          other.scopeKey == this.scopeKey &&
          other.importCode == this.importCode &&
          other.importType == this.importType &&
          other.status == this.status &&
          other.businessLocationId == this.businessLocationId &&
          other.businessLocationName == this.businessLocationName &&
          other.supplier == this.supplier &&
          other.note == this.note &&
          other.receivedAtEpoch == this.receivedAtEpoch &&
          other.totalAmount == this.totalAmount &&
          other.createdAtEpoch == this.createdAtEpoch &&
          other.updatedAtEpoch == this.updatedAtEpoch &&
          other.imageUrl == this.imageUrl &&
          other.itemsJson == this.itemsJson &&
          other.cachedAtEpoch == this.cachedAtEpoch);
}

class ImportsTableCompanion extends UpdateCompanion<ImportsTableData> {
  final Value<int> id;
  final Value<String> scopeKey;
  final Value<String> importCode;
  final Value<String> importType;
  final Value<String> status;
  final Value<int> businessLocationId;
  final Value<String> businessLocationName;
  final Value<String?> supplier;
  final Value<String?> note;
  final Value<int?> receivedAtEpoch;
  final Value<double> totalAmount;
  final Value<int> createdAtEpoch;
  final Value<int?> updatedAtEpoch;
  final Value<String?> imageUrl;
  final Value<String> itemsJson;
  final Value<int> cachedAtEpoch;
  final Value<int> rowid;
  const ImportsTableCompanion({
    this.id = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.importCode = const Value.absent(),
    this.importType = const Value.absent(),
    this.status = const Value.absent(),
    this.businessLocationId = const Value.absent(),
    this.businessLocationName = const Value.absent(),
    this.supplier = const Value.absent(),
    this.note = const Value.absent(),
    this.receivedAtEpoch = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.createdAtEpoch = const Value.absent(),
    this.updatedAtEpoch = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.cachedAtEpoch = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportsTableCompanion.insert({
    required int id,
    required String scopeKey,
    this.importCode = const Value.absent(),
    this.importType = const Value.absent(),
    this.status = const Value.absent(),
    required int businessLocationId,
    this.businessLocationName = const Value.absent(),
    this.supplier = const Value.absent(),
    this.note = const Value.absent(),
    this.receivedAtEpoch = const Value.absent(),
    this.totalAmount = const Value.absent(),
    required int createdAtEpoch,
    this.updatedAtEpoch = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.itemsJson = const Value.absent(),
    required int cachedAtEpoch,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scopeKey = Value(scopeKey),
       businessLocationId = Value(businessLocationId),
       createdAtEpoch = Value(createdAtEpoch),
       cachedAtEpoch = Value(cachedAtEpoch);
  static Insertable<ImportsTableData> custom({
    Expression<int>? id,
    Expression<String>? scopeKey,
    Expression<String>? importCode,
    Expression<String>? importType,
    Expression<String>? status,
    Expression<int>? businessLocationId,
    Expression<String>? businessLocationName,
    Expression<String>? supplier,
    Expression<String>? note,
    Expression<int>? receivedAtEpoch,
    Expression<double>? totalAmount,
    Expression<int>? createdAtEpoch,
    Expression<int>? updatedAtEpoch,
    Expression<String>? imageUrl,
    Expression<String>? itemsJson,
    Expression<int>? cachedAtEpoch,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (importCode != null) 'import_code': importCode,
      if (importType != null) 'import_type': importType,
      if (status != null) 'status': status,
      if (businessLocationId != null)
        'business_location_id': businessLocationId,
      if (businessLocationName != null)
        'business_location_name': businessLocationName,
      if (supplier != null) 'supplier': supplier,
      if (note != null) 'note': note,
      if (receivedAtEpoch != null) 'received_at_epoch': receivedAtEpoch,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (createdAtEpoch != null) 'created_at_epoch': createdAtEpoch,
      if (updatedAtEpoch != null) 'updated_at_epoch': updatedAtEpoch,
      if (imageUrl != null) 'image_url': imageUrl,
      if (itemsJson != null) 'items_json': itemsJson,
      if (cachedAtEpoch != null) 'cached_at_epoch': cachedAtEpoch,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? scopeKey,
    Value<String>? importCode,
    Value<String>? importType,
    Value<String>? status,
    Value<int>? businessLocationId,
    Value<String>? businessLocationName,
    Value<String?>? supplier,
    Value<String?>? note,
    Value<int?>? receivedAtEpoch,
    Value<double>? totalAmount,
    Value<int>? createdAtEpoch,
    Value<int?>? updatedAtEpoch,
    Value<String?>? imageUrl,
    Value<String>? itemsJson,
    Value<int>? cachedAtEpoch,
    Value<int>? rowid,
  }) {
    return ImportsTableCompanion(
      id: id ?? this.id,
      scopeKey: scopeKey ?? this.scopeKey,
      importCode: importCode ?? this.importCode,
      importType: importType ?? this.importType,
      status: status ?? this.status,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      businessLocationName: businessLocationName ?? this.businessLocationName,
      supplier: supplier ?? this.supplier,
      note: note ?? this.note,
      receivedAtEpoch: receivedAtEpoch ?? this.receivedAtEpoch,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAtEpoch: createdAtEpoch ?? this.createdAtEpoch,
      updatedAtEpoch: updatedAtEpoch ?? this.updatedAtEpoch,
      imageUrl: imageUrl ?? this.imageUrl,
      itemsJson: itemsJson ?? this.itemsJson,
      cachedAtEpoch: cachedAtEpoch ?? this.cachedAtEpoch,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (importCode.present) {
      map['import_code'] = Variable<String>(importCode.value);
    }
    if (importType.present) {
      map['import_type'] = Variable<String>(importType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (businessLocationId.present) {
      map['business_location_id'] = Variable<int>(businessLocationId.value);
    }
    if (businessLocationName.present) {
      map['business_location_name'] = Variable<String>(
        businessLocationName.value,
      );
    }
    if (supplier.present) {
      map['supplier'] = Variable<String>(supplier.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (receivedAtEpoch.present) {
      map['received_at_epoch'] = Variable<int>(receivedAtEpoch.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (createdAtEpoch.present) {
      map['created_at_epoch'] = Variable<int>(createdAtEpoch.value);
    }
    if (updatedAtEpoch.present) {
      map['updated_at_epoch'] = Variable<int>(updatedAtEpoch.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (cachedAtEpoch.present) {
      map['cached_at_epoch'] = Variable<int>(cachedAtEpoch.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportsTableCompanion(')
          ..write('id: $id, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('importCode: $importCode, ')
          ..write('importType: $importType, ')
          ..write('status: $status, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('businessLocationName: $businessLocationName, ')
          ..write('supplier: $supplier, ')
          ..write('note: $note, ')
          ..write('receivedAtEpoch: $receivedAtEpoch, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('createdAtEpoch: $createdAtEpoch, ')
          ..write('updatedAtEpoch: $updatedAtEpoch, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('cachedAtEpoch: $cachedAtEpoch, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApiCacheEntriesTableTable extends ApiCacheEntriesTable
    with TableInfo<$ApiCacheEntriesTableTable, ApiCacheEntriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiCacheEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupKeyMeta = const VerificationMeta(
    'groupKey',
  );
  @override
  late final GeneratedColumn<String> groupKey = GeneratedColumn<String>(
    'group_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cacheTypeMeta = const VerificationMeta(
    'cacheType',
  );
  @override
  late final GeneratedColumn<String> cacheType = GeneratedColumn<String>(
    'cache_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('list'),
  );
  static const VerificationMeta _cachedAtEpochMeta = const VerificationMeta(
    'cachedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> cachedAtEpoch = GeneratedColumn<int>(
    'cached_at_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheKey,
    groupKey,
    payloadJson,
    cacheType,
    cachedAtEpoch,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_cache_entries_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApiCacheEntriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('group_key')) {
      context.handle(
        _groupKeyMeta,
        groupKey.isAcceptableOrUnknown(data['group_key']!, _groupKeyMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('cache_type')) {
      context.handle(
        _cacheTypeMeta,
        cacheType.isAcceptableOrUnknown(data['cache_type']!, _cacheTypeMeta),
      );
    }
    if (data.containsKey('cached_at_epoch')) {
      context.handle(
        _cachedAtEpochMeta,
        cachedAtEpoch.isAcceptableOrUnknown(
          data['cached_at_epoch']!,
          _cachedAtEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedAtEpochMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  ApiCacheEntriesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiCacheEntriesTableData(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      groupKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_key'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      cacheType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_type'],
      )!,
      cachedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at_epoch'],
      )!,
    );
  }

  @override
  $ApiCacheEntriesTableTable createAlias(String alias) {
    return $ApiCacheEntriesTableTable(attachedDatabase, alias);
  }
}

class ApiCacheEntriesTableData extends DataClass
    implements Insertable<ApiCacheEntriesTableData> {
  final String cacheKey;
  final String? groupKey;
  final String payloadJson;
  final String cacheType;
  final int cachedAtEpoch;
  const ApiCacheEntriesTableData({
    required this.cacheKey,
    this.groupKey,
    required this.payloadJson,
    required this.cacheType,
    required this.cachedAtEpoch,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    if (!nullToAbsent || groupKey != null) {
      map['group_key'] = Variable<String>(groupKey);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    map['cache_type'] = Variable<String>(cacheType);
    map['cached_at_epoch'] = Variable<int>(cachedAtEpoch);
    return map;
  }

  ApiCacheEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return ApiCacheEntriesTableCompanion(
      cacheKey: Value(cacheKey),
      groupKey: groupKey == null && nullToAbsent
          ? const Value.absent()
          : Value(groupKey),
      payloadJson: Value(payloadJson),
      cacheType: Value(cacheType),
      cachedAtEpoch: Value(cachedAtEpoch),
    );
  }

  factory ApiCacheEntriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiCacheEntriesTableData(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      groupKey: serializer.fromJson<String?>(json['groupKey']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      cacheType: serializer.fromJson<String>(json['cacheType']),
      cachedAtEpoch: serializer.fromJson<int>(json['cachedAtEpoch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'groupKey': serializer.toJson<String?>(groupKey),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'cacheType': serializer.toJson<String>(cacheType),
      'cachedAtEpoch': serializer.toJson<int>(cachedAtEpoch),
    };
  }

  ApiCacheEntriesTableData copyWith({
    String? cacheKey,
    Value<String?> groupKey = const Value.absent(),
    String? payloadJson,
    String? cacheType,
    int? cachedAtEpoch,
  }) => ApiCacheEntriesTableData(
    cacheKey: cacheKey ?? this.cacheKey,
    groupKey: groupKey.present ? groupKey.value : this.groupKey,
    payloadJson: payloadJson ?? this.payloadJson,
    cacheType: cacheType ?? this.cacheType,
    cachedAtEpoch: cachedAtEpoch ?? this.cachedAtEpoch,
  );
  ApiCacheEntriesTableData copyWithCompanion(
    ApiCacheEntriesTableCompanion data,
  ) {
    return ApiCacheEntriesTableData(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      groupKey: data.groupKey.present ? data.groupKey.value : this.groupKey,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      cacheType: data.cacheType.present ? data.cacheType.value : this.cacheType,
      cachedAtEpoch: data.cachedAtEpoch.present
          ? data.cachedAtEpoch.value
          : this.cachedAtEpoch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiCacheEntriesTableData(')
          ..write('cacheKey: $cacheKey, ')
          ..write('groupKey: $groupKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('cacheType: $cacheType, ')
          ..write('cachedAtEpoch: $cachedAtEpoch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(cacheKey, groupKey, payloadJson, cacheType, cachedAtEpoch);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiCacheEntriesTableData &&
          other.cacheKey == this.cacheKey &&
          other.groupKey == this.groupKey &&
          other.payloadJson == this.payloadJson &&
          other.cacheType == this.cacheType &&
          other.cachedAtEpoch == this.cachedAtEpoch);
}

class ApiCacheEntriesTableCompanion
    extends UpdateCompanion<ApiCacheEntriesTableData> {
  final Value<String> cacheKey;
  final Value<String?> groupKey;
  final Value<String> payloadJson;
  final Value<String> cacheType;
  final Value<int> cachedAtEpoch;
  final Value<int> rowid;
  const ApiCacheEntriesTableCompanion({
    this.cacheKey = const Value.absent(),
    this.groupKey = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.cacheType = const Value.absent(),
    this.cachedAtEpoch = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApiCacheEntriesTableCompanion.insert({
    required String cacheKey,
    this.groupKey = const Value.absent(),
    required String payloadJson,
    this.cacheType = const Value.absent(),
    required int cachedAtEpoch,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       payloadJson = Value(payloadJson),
       cachedAtEpoch = Value(cachedAtEpoch);
  static Insertable<ApiCacheEntriesTableData> custom({
    Expression<String>? cacheKey,
    Expression<String>? groupKey,
    Expression<String>? payloadJson,
    Expression<String>? cacheType,
    Expression<int>? cachedAtEpoch,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (groupKey != null) 'group_key': groupKey,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (cacheType != null) 'cache_type': cacheType,
      if (cachedAtEpoch != null) 'cached_at_epoch': cachedAtEpoch,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApiCacheEntriesTableCompanion copyWith({
    Value<String>? cacheKey,
    Value<String?>? groupKey,
    Value<String>? payloadJson,
    Value<String>? cacheType,
    Value<int>? cachedAtEpoch,
    Value<int>? rowid,
  }) {
    return ApiCacheEntriesTableCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      groupKey: groupKey ?? this.groupKey,
      payloadJson: payloadJson ?? this.payloadJson,
      cacheType: cacheType ?? this.cacheType,
      cachedAtEpoch: cachedAtEpoch ?? this.cachedAtEpoch,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (groupKey.present) {
      map['group_key'] = Variable<String>(groupKey.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (cacheType.present) {
      map['cache_type'] = Variable<String>(cacheType.value);
    }
    if (cachedAtEpoch.present) {
      map['cached_at_epoch'] = Variable<int>(cachedAtEpoch.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiCacheEntriesTableCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('groupKey: $groupKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('cacheType: $cacheType, ')
          ..write('cachedAtEpoch: $cachedAtEpoch, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvoiceTemplateSettingsTableTable extends InvoiceTemplateSettingsTable
    with
        TableInfo<
          $InvoiceTemplateSettingsTableTable,
          InvoiceTemplateSettingsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoiceTemplateSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountScopeMeta = const VerificationMeta(
    'accountScope',
  );
  @override
  late final GeneratedColumn<String> accountScope = GeneratedColumn<String>(
    'account_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtEpochMeta = const VerificationMeta(
    'updatedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> updatedAtEpoch = GeneratedColumn<int>(
    'updated_at_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountScope,
    payloadJson,
    updatedAtEpoch,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoice_template_settings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoiceTemplateSettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_scope')) {
      context.handle(
        _accountScopeMeta,
        accountScope.isAcceptableOrUnknown(
          data['account_scope']!,
          _accountScopeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountScopeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at_epoch')) {
      context.handle(
        _updatedAtEpochMeta,
        updatedAtEpoch.isAcceptableOrUnknown(
          data['updated_at_epoch']!,
          _updatedAtEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtEpochMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountScope};
  @override
  InvoiceTemplateSettingsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceTemplateSettingsTableData(
      accountScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_scope'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      updatedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_epoch'],
      )!,
    );
  }

  @override
  $InvoiceTemplateSettingsTableTable createAlias(String alias) {
    return $InvoiceTemplateSettingsTableTable(attachedDatabase, alias);
  }
}

class InvoiceTemplateSettingsTableData extends DataClass
    implements Insertable<InvoiceTemplateSettingsTableData> {
  final String accountScope;
  final String payloadJson;
  final int updatedAtEpoch;
  const InvoiceTemplateSettingsTableData({
    required this.accountScope,
    required this.payloadJson,
    required this.updatedAtEpoch,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_scope'] = Variable<String>(accountScope);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at_epoch'] = Variable<int>(updatedAtEpoch);
    return map;
  }

  InvoiceTemplateSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return InvoiceTemplateSettingsTableCompanion(
      accountScope: Value(accountScope),
      payloadJson: Value(payloadJson),
      updatedAtEpoch: Value(updatedAtEpoch),
    );
  }

  factory InvoiceTemplateSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceTemplateSettingsTableData(
      accountScope: serializer.fromJson<String>(json['accountScope']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAtEpoch: serializer.fromJson<int>(json['updatedAtEpoch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountScope': serializer.toJson<String>(accountScope),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAtEpoch': serializer.toJson<int>(updatedAtEpoch),
    };
  }

  InvoiceTemplateSettingsTableData copyWith({
    String? accountScope,
    String? payloadJson,
    int? updatedAtEpoch,
  }) => InvoiceTemplateSettingsTableData(
    accountScope: accountScope ?? this.accountScope,
    payloadJson: payloadJson ?? this.payloadJson,
    updatedAtEpoch: updatedAtEpoch ?? this.updatedAtEpoch,
  );
  InvoiceTemplateSettingsTableData copyWithCompanion(
    InvoiceTemplateSettingsTableCompanion data,
  ) {
    return InvoiceTemplateSettingsTableData(
      accountScope: data.accountScope.present
          ? data.accountScope.value
          : this.accountScope,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      updatedAtEpoch: data.updatedAtEpoch.present
          ? data.updatedAtEpoch.value
          : this.updatedAtEpoch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceTemplateSettingsTableData(')
          ..write('accountScope: $accountScope, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAtEpoch: $updatedAtEpoch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountScope, payloadJson, updatedAtEpoch);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceTemplateSettingsTableData &&
          other.accountScope == this.accountScope &&
          other.payloadJson == this.payloadJson &&
          other.updatedAtEpoch == this.updatedAtEpoch);
}

class InvoiceTemplateSettingsTableCompanion
    extends UpdateCompanion<InvoiceTemplateSettingsTableData> {
  final Value<String> accountScope;
  final Value<String> payloadJson;
  final Value<int> updatedAtEpoch;
  final Value<int> rowid;
  const InvoiceTemplateSettingsTableCompanion({
    this.accountScope = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAtEpoch = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoiceTemplateSettingsTableCompanion.insert({
    required String accountScope,
    required String payloadJson,
    required int updatedAtEpoch,
    this.rowid = const Value.absent(),
  }) : accountScope = Value(accountScope),
       payloadJson = Value(payloadJson),
       updatedAtEpoch = Value(updatedAtEpoch);
  static Insertable<InvoiceTemplateSettingsTableData> custom({
    Expression<String>? accountScope,
    Expression<String>? payloadJson,
    Expression<int>? updatedAtEpoch,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountScope != null) 'account_scope': accountScope,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAtEpoch != null) 'updated_at_epoch': updatedAtEpoch,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoiceTemplateSettingsTableCompanion copyWith({
    Value<String>? accountScope,
    Value<String>? payloadJson,
    Value<int>? updatedAtEpoch,
    Value<int>? rowid,
  }) {
    return InvoiceTemplateSettingsTableCompanion(
      accountScope: accountScope ?? this.accountScope,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAtEpoch: updatedAtEpoch ?? this.updatedAtEpoch,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountScope.present) {
      map['account_scope'] = Variable<String>(accountScope.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAtEpoch.present) {
      map['updated_at_epoch'] = Variable<int>(updatedAtEpoch.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceTemplateSettingsTableCompanion(')
          ..write('accountScope: $accountScope, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAtEpoch: $updatedAtEpoch, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTableTable extends SyncStateTable
    with TableInfo<$SyncStateTableTable, SyncStateTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceKeyMeta = const VerificationMeta(
    'resourceKey',
  );
  @override
  late final GeneratedColumn<String> resourceKey = GeneratedColumn<String>(
    'resource_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('global'),
  );
  static const VerificationMeta _lastSyncedAtEpochMeta = const VerificationMeta(
    'lastSyncedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAtEpoch = GeneratedColumn<int>(
    'last_synced_at_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    resourceKey,
    businessId,
    lastSyncedAtEpoch,
    etag,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_key')) {
      context.handle(
        _resourceKeyMeta,
        resourceKey.isAcceptableOrUnknown(
          data['resource_key']!,
          _resourceKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resourceKeyMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    if (data.containsKey('last_synced_at_epoch')) {
      context.handle(
        _lastSyncedAtEpochMeta,
        lastSyncedAtEpoch.isAcceptableOrUnknown(
          data['last_synced_at_epoch']!,
          _lastSyncedAtEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedAtEpochMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceKey, businessId};
  @override
  SyncStateTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateTableData(
      resourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_key'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      lastSyncedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at_epoch'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
    );
  }

  @override
  $SyncStateTableTable createAlias(String alias) {
    return $SyncStateTableTable(attachedDatabase, alias);
  }
}

class SyncStateTableData extends DataClass
    implements Insertable<SyncStateTableData> {
  final String resourceKey;
  final String businessId;
  final int lastSyncedAtEpoch;
  final String? etag;
  const SyncStateTableData({
    required this.resourceKey,
    required this.businessId,
    required this.lastSyncedAtEpoch,
    this.etag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_key'] = Variable<String>(resourceKey);
    map['business_id'] = Variable<String>(businessId);
    map['last_synced_at_epoch'] = Variable<int>(lastSyncedAtEpoch);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    return map;
  }

  SyncStateTableCompanion toCompanion(bool nullToAbsent) {
    return SyncStateTableCompanion(
      resourceKey: Value(resourceKey),
      businessId: Value(businessId),
      lastSyncedAtEpoch: Value(lastSyncedAtEpoch),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
    );
  }

  factory SyncStateTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateTableData(
      resourceKey: serializer.fromJson<String>(json['resourceKey']),
      businessId: serializer.fromJson<String>(json['businessId']),
      lastSyncedAtEpoch: serializer.fromJson<int>(json['lastSyncedAtEpoch']),
      etag: serializer.fromJson<String?>(json['etag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resourceKey': serializer.toJson<String>(resourceKey),
      'businessId': serializer.toJson<String>(businessId),
      'lastSyncedAtEpoch': serializer.toJson<int>(lastSyncedAtEpoch),
      'etag': serializer.toJson<String?>(etag),
    };
  }

  SyncStateTableData copyWith({
    String? resourceKey,
    String? businessId,
    int? lastSyncedAtEpoch,
    Value<String?> etag = const Value.absent(),
  }) => SyncStateTableData(
    resourceKey: resourceKey ?? this.resourceKey,
    businessId: businessId ?? this.businessId,
    lastSyncedAtEpoch: lastSyncedAtEpoch ?? this.lastSyncedAtEpoch,
    etag: etag.present ? etag.value : this.etag,
  );
  SyncStateTableData copyWithCompanion(SyncStateTableCompanion data) {
    return SyncStateTableData(
      resourceKey: data.resourceKey.present
          ? data.resourceKey.value
          : this.resourceKey,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      lastSyncedAtEpoch: data.lastSyncedAtEpoch.present
          ? data.lastSyncedAtEpoch.value
          : this.lastSyncedAtEpoch,
      etag: data.etag.present ? data.etag.value : this.etag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateTableData(')
          ..write('resourceKey: $resourceKey, ')
          ..write('businessId: $businessId, ')
          ..write('lastSyncedAtEpoch: $lastSyncedAtEpoch, ')
          ..write('etag: $etag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(resourceKey, businessId, lastSyncedAtEpoch, etag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateTableData &&
          other.resourceKey == this.resourceKey &&
          other.businessId == this.businessId &&
          other.lastSyncedAtEpoch == this.lastSyncedAtEpoch &&
          other.etag == this.etag);
}

class SyncStateTableCompanion extends UpdateCompanion<SyncStateTableData> {
  final Value<String> resourceKey;
  final Value<String> businessId;
  final Value<int> lastSyncedAtEpoch;
  final Value<String?> etag;
  final Value<int> rowid;
  const SyncStateTableCompanion({
    this.resourceKey = const Value.absent(),
    this.businessId = const Value.absent(),
    this.lastSyncedAtEpoch = const Value.absent(),
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateTableCompanion.insert({
    required String resourceKey,
    this.businessId = const Value.absent(),
    required int lastSyncedAtEpoch,
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : resourceKey = Value(resourceKey),
       lastSyncedAtEpoch = Value(lastSyncedAtEpoch);
  static Insertable<SyncStateTableData> custom({
    Expression<String>? resourceKey,
    Expression<String>? businessId,
    Expression<int>? lastSyncedAtEpoch,
    Expression<String>? etag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceKey != null) 'resource_key': resourceKey,
      if (businessId != null) 'business_id': businessId,
      if (lastSyncedAtEpoch != null) 'last_synced_at_epoch': lastSyncedAtEpoch,
      if (etag != null) 'etag': etag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateTableCompanion copyWith({
    Value<String>? resourceKey,
    Value<String>? businessId,
    Value<int>? lastSyncedAtEpoch,
    Value<String?>? etag,
    Value<int>? rowid,
  }) {
    return SyncStateTableCompanion(
      resourceKey: resourceKey ?? this.resourceKey,
      businessId: businessId ?? this.businessId,
      lastSyncedAtEpoch: lastSyncedAtEpoch ?? this.lastSyncedAtEpoch,
      etag: etag ?? this.etag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceKey.present) {
      map['resource_key'] = Variable<String>(resourceKey.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (lastSyncedAtEpoch.present) {
      map['last_synced_at_epoch'] = Variable<int>(lastSyncedAtEpoch.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateTableCompanion(')
          ..write('resourceKey: $resourceKey, ')
          ..write('businessId: $businessId, ')
          ..write('lastSyncedAtEpoch: $lastSyncedAtEpoch, ')
          ..write('etag: $etag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocationsTableTable locationsTable = $LocationsTableTable(this);
  late final $ProductsTableTable productsTable = $ProductsTableTable(this);
  late final $EmployeesTableTable employeesTable = $EmployeesTableTable(this);
  late final $OrdersTableTable ordersTable = $OrdersTableTable(this);
  late final $ImportsTableTable importsTable = $ImportsTableTable(this);
  late final $ApiCacheEntriesTableTable apiCacheEntriesTable =
      $ApiCacheEntriesTableTable(this);
  late final $InvoiceTemplateSettingsTableTable invoiceTemplateSettingsTable =
      $InvoiceTemplateSettingsTableTable(this);
  late final $SyncStateTableTable syncStateTable = $SyncStateTableTable(this);
  late final LocationsDao locationsDao = LocationsDao(this as AppDatabase);
  late final ProductsDao productsDao = ProductsDao(this as AppDatabase);
  late final EmployeesDao employeesDao = EmployeesDao(this as AppDatabase);
  late final OrdersDao ordersDao = OrdersDao(this as AppDatabase);
  late final ImportsDao importsDao = ImportsDao(this as AppDatabase);
  late final ApiCacheDao apiCacheDao = ApiCacheDao(this as AppDatabase);
  late final InvoiceTemplateSettingsDao invoiceTemplateSettingsDao =
      InvoiceTemplateSettingsDao(this as AppDatabase);
  late final SyncStateDao syncStateDao = SyncStateDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    locationsTable,
    productsTable,
    employeesTable,
    ordersTable,
    importsTable,
    apiCacheEntriesTable,
    invoiceTemplateSettingsTable,
    syncStateTable,
  ];
}

typedef $$LocationsTableTableCreateCompanionBuilder =
    LocationsTableCompanion Function({
      required String id,
      Value<String?> businessId,
      required String name,
      Value<String> address,
      Value<String> district,
      Value<String> city,
      Value<String> phone,
      Value<bool> isActive,
      Value<String> ownerName,
      Value<String?> ownerProfileId,
      Value<String?> taxCode,
      Value<String> employeeIdsJson,
      Value<bool> isOwner,
      Value<int?> updatedAtEpoch,
      required int cachedAtEpoch,
      Value<int> rowid,
    });
typedef $$LocationsTableTableUpdateCompanionBuilder =
    LocationsTableCompanion Function({
      Value<String> id,
      Value<String?> businessId,
      Value<String> name,
      Value<String> address,
      Value<String> district,
      Value<String> city,
      Value<String> phone,
      Value<bool> isActive,
      Value<String> ownerName,
      Value<String?> ownerProfileId,
      Value<String?> taxCode,
      Value<String> employeeIdsJson,
      Value<bool> isOwner,
      Value<int?> updatedAtEpoch,
      Value<int> cachedAtEpoch,
      Value<int> rowid,
    });

class $$LocationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocationsTableTable> {
  $$LocationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerProfileId => $composableBuilder(
    column: $table.ownerProfileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxCode => $composableBuilder(
    column: $table.taxCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeIdsJson => $composableBuilder(
    column: $table.employeeIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOwner => $composableBuilder(
    column: $table.isOwner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocationsTableTable> {
  $$LocationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerProfileId => $composableBuilder(
    column: $table.ownerProfileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxCode => $composableBuilder(
    column: $table.taxCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeIdsJson => $composableBuilder(
    column: $table.employeeIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOwner => $composableBuilder(
    column: $table.isOwner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocationsTableTable> {
  $$LocationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get district =>
      $composableBuilder(column: $table.district, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => column);

  GeneratedColumn<String> get ownerProfileId => $composableBuilder(
    column: $table.ownerProfileId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxCode =>
      $composableBuilder(column: $table.taxCode, builder: (column) => column);

  GeneratedColumn<String> get employeeIdsJson => $composableBuilder(
    column: $table.employeeIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOwner =>
      $composableBuilder(column: $table.isOwner, builder: (column) => column);

  GeneratedColumn<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => column,
  );
}

class $$LocationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocationsTableTable,
          LocationsTableData,
          $$LocationsTableTableFilterComposer,
          $$LocationsTableTableOrderingComposer,
          $$LocationsTableTableAnnotationComposer,
          $$LocationsTableTableCreateCompanionBuilder,
          $$LocationsTableTableUpdateCompanionBuilder,
          (
            LocationsTableData,
            BaseReferences<
              _$AppDatabase,
              $LocationsTableTable,
              LocationsTableData
            >,
          ),
          LocationsTableData,
          PrefetchHooks Function()
        > {
  $$LocationsTableTableTableManager(
    _$AppDatabase db,
    $LocationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> district = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> ownerName = const Value.absent(),
                Value<String?> ownerProfileId = const Value.absent(),
                Value<String?> taxCode = const Value.absent(),
                Value<String> employeeIdsJson = const Value.absent(),
                Value<bool> isOwner = const Value.absent(),
                Value<int?> updatedAtEpoch = const Value.absent(),
                Value<int> cachedAtEpoch = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocationsTableCompanion(
                id: id,
                businessId: businessId,
                name: name,
                address: address,
                district: district,
                city: city,
                phone: phone,
                isActive: isActive,
                ownerName: ownerName,
                ownerProfileId: ownerProfileId,
                taxCode: taxCode,
                employeeIdsJson: employeeIdsJson,
                isOwner: isOwner,
                updatedAtEpoch: updatedAtEpoch,
                cachedAtEpoch: cachedAtEpoch,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> businessId = const Value.absent(),
                required String name,
                Value<String> address = const Value.absent(),
                Value<String> district = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> ownerName = const Value.absent(),
                Value<String?> ownerProfileId = const Value.absent(),
                Value<String?> taxCode = const Value.absent(),
                Value<String> employeeIdsJson = const Value.absent(),
                Value<bool> isOwner = const Value.absent(),
                Value<int?> updatedAtEpoch = const Value.absent(),
                required int cachedAtEpoch,
                Value<int> rowid = const Value.absent(),
              }) => LocationsTableCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                address: address,
                district: district,
                city: city,
                phone: phone,
                isActive: isActive,
                ownerName: ownerName,
                ownerProfileId: ownerProfileId,
                taxCode: taxCode,
                employeeIdsJson: employeeIdsJson,
                isOwner: isOwner,
                updatedAtEpoch: updatedAtEpoch,
                cachedAtEpoch: cachedAtEpoch,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocationsTableTable,
      LocationsTableData,
      $$LocationsTableTableFilterComposer,
      $$LocationsTableTableOrderingComposer,
      $$LocationsTableTableAnnotationComposer,
      $$LocationsTableTableCreateCompanionBuilder,
      $$LocationsTableTableUpdateCompanionBuilder,
      (
        LocationsTableData,
        BaseReferences<_$AppDatabase, $LocationsTableTable, LocationsTableData>,
      ),
      LocationsTableData,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableTableCreateCompanionBuilder =
    ProductsTableCompanion Function({
      required String id,
      required String scopeKey,
      required String name,
      Value<String> description,
      Value<double> price,
      Value<int> quantity,
      Value<String?> imageUrl,
      Value<String?> barcode,
      Value<String?> category,
      Value<double?> costPrice,
      Value<double?> salePrice,
      Value<String?> unit,
      Value<bool> trackInventory,
      Value<bool> isActive,
      Value<int?> createdAtEpoch,
      Value<int?> locationId,
      Value<String?> businessTypeId,
      Value<String?> manufacturer,
      Value<String?> businessLocationName,
      Value<String> saleItemsJson,
      required int cachedAtEpoch,
      Value<int> rowid,
    });
typedef $$ProductsTableTableUpdateCompanionBuilder =
    ProductsTableCompanion Function({
      Value<String> id,
      Value<String> scopeKey,
      Value<String> name,
      Value<String> description,
      Value<double> price,
      Value<int> quantity,
      Value<String?> imageUrl,
      Value<String?> barcode,
      Value<String?> category,
      Value<double?> costPrice,
      Value<double?> salePrice,
      Value<String?> unit,
      Value<bool> trackInventory,
      Value<bool> isActive,
      Value<int?> createdAtEpoch,
      Value<int?> locationId,
      Value<String?> businessTypeId,
      Value<String?> manufacturer,
      Value<String?> businessLocationName,
      Value<String> saleItemsJson,
      Value<int> cachedAtEpoch,
      Value<int> rowid,
    });

class $$ProductsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salePrice => $composableBuilder(
    column: $table.salePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trackInventory => $composableBuilder(
    column: $table.trackInventory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtEpoch => $composableBuilder(
    column: $table.createdAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessTypeId => $composableBuilder(
    column: $table.businessTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessLocationName => $composableBuilder(
    column: $table.businessLocationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleItemsJson => $composableBuilder(
    column: $table.saleItemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salePrice => $composableBuilder(
    column: $table.salePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trackInventory => $composableBuilder(
    column: $table.trackInventory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtEpoch => $composableBuilder(
    column: $table.createdAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessTypeId => $composableBuilder(
    column: $table.businessTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessLocationName => $composableBuilder(
    column: $table.businessLocationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleItemsJson => $composableBuilder(
    column: $table.saleItemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<double> get salePrice =>
      $composableBuilder(column: $table.salePrice, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get trackInventory => $composableBuilder(
    column: $table.trackInventory,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAtEpoch => $composableBuilder(
    column: $table.createdAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessTypeId => $composableBuilder(
    column: $table.businessTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessLocationName => $composableBuilder(
    column: $table.businessLocationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get saleItemsJson => $composableBuilder(
    column: $table.saleItemsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => column,
  );
}

class $$ProductsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTableTable,
          ProductsTableData,
          $$ProductsTableTableFilterComposer,
          $$ProductsTableTableOrderingComposer,
          $$ProductsTableTableAnnotationComposer,
          $$ProductsTableTableCreateCompanionBuilder,
          $$ProductsTableTableUpdateCompanionBuilder,
          (
            ProductsTableData,
            BaseReferences<
              _$AppDatabase,
              $ProductsTableTable,
              ProductsTableData
            >,
          ),
          ProductsTableData,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableTableManager(_$AppDatabase db, $ProductsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scopeKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<double?> costPrice = const Value.absent(),
                Value<double?> salePrice = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> trackInventory = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int?> createdAtEpoch = const Value.absent(),
                Value<int?> locationId = const Value.absent(),
                Value<String?> businessTypeId = const Value.absent(),
                Value<String?> manufacturer = const Value.absent(),
                Value<String?> businessLocationName = const Value.absent(),
                Value<String> saleItemsJson = const Value.absent(),
                Value<int> cachedAtEpoch = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion(
                id: id,
                scopeKey: scopeKey,
                name: name,
                description: description,
                price: price,
                quantity: quantity,
                imageUrl: imageUrl,
                barcode: barcode,
                category: category,
                costPrice: costPrice,
                salePrice: salePrice,
                unit: unit,
                trackInventory: trackInventory,
                isActive: isActive,
                createdAtEpoch: createdAtEpoch,
                locationId: locationId,
                businessTypeId: businessTypeId,
                manufacturer: manufacturer,
                businessLocationName: businessLocationName,
                saleItemsJson: saleItemsJson,
                cachedAtEpoch: cachedAtEpoch,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scopeKey,
                required String name,
                Value<String> description = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<double?> costPrice = const Value.absent(),
                Value<double?> salePrice = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> trackInventory = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int?> createdAtEpoch = const Value.absent(),
                Value<int?> locationId = const Value.absent(),
                Value<String?> businessTypeId = const Value.absent(),
                Value<String?> manufacturer = const Value.absent(),
                Value<String?> businessLocationName = const Value.absent(),
                Value<String> saleItemsJson = const Value.absent(),
                required int cachedAtEpoch,
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion.insert(
                id: id,
                scopeKey: scopeKey,
                name: name,
                description: description,
                price: price,
                quantity: quantity,
                imageUrl: imageUrl,
                barcode: barcode,
                category: category,
                costPrice: costPrice,
                salePrice: salePrice,
                unit: unit,
                trackInventory: trackInventory,
                isActive: isActive,
                createdAtEpoch: createdAtEpoch,
                locationId: locationId,
                businessTypeId: businessTypeId,
                manufacturer: manufacturer,
                businessLocationName: businessLocationName,
                saleItemsJson: saleItemsJson,
                cachedAtEpoch: cachedAtEpoch,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTableTable,
      ProductsTableData,
      $$ProductsTableTableFilterComposer,
      $$ProductsTableTableOrderingComposer,
      $$ProductsTableTableAnnotationComposer,
      $$ProductsTableTableCreateCompanionBuilder,
      $$ProductsTableTableUpdateCompanionBuilder,
      (
        ProductsTableData,
        BaseReferences<_$AppDatabase, $ProductsTableTable, ProductsTableData>,
      ),
      ProductsTableData,
      PrefetchHooks Function()
    >;
typedef $$EmployeesTableTableCreateCompanionBuilder =
    EmployeesTableCompanion Function({
      required String id,
      required String businessId,
      required String name,
      Value<String> phone,
      Value<String> email,
      Value<String> status,
      Value<bool> isActive,
      Value<String> employmentStatus,
      Value<int?> startedAtEpoch,
      Value<int?> endedAtEpoch,
      Value<String> assignedLocationIdsJson,
      Value<String> assignedLocationNamesJson,
      required int cachedAtEpoch,
      Value<int> rowid,
    });
typedef $$EmployeesTableTableUpdateCompanionBuilder =
    EmployeesTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<String> phone,
      Value<String> email,
      Value<String> status,
      Value<bool> isActive,
      Value<String> employmentStatus,
      Value<int?> startedAtEpoch,
      Value<int?> endedAtEpoch,
      Value<String> assignedLocationIdsJson,
      Value<String> assignedLocationNamesJson,
      Value<int> cachedAtEpoch,
      Value<int> rowid,
    });

class $$EmployeesTableTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeesTableTable> {
  $$EmployeesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employmentStatus => $composableBuilder(
    column: $table.employmentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtEpoch => $composableBuilder(
    column: $table.startedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAtEpoch => $composableBuilder(
    column: $table.endedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assignedLocationIdsJson => $composableBuilder(
    column: $table.assignedLocationIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assignedLocationNamesJson => $composableBuilder(
    column: $table.assignedLocationNamesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EmployeesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeesTableTable> {
  $$EmployeesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employmentStatus => $composableBuilder(
    column: $table.employmentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtEpoch => $composableBuilder(
    column: $table.startedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAtEpoch => $composableBuilder(
    column: $table.endedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignedLocationIdsJson => $composableBuilder(
    column: $table.assignedLocationIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignedLocationNamesJson => $composableBuilder(
    column: $table.assignedLocationNamesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmployeesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeesTableTable> {
  $$EmployeesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get employmentStatus => $composableBuilder(
    column: $table.employmentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAtEpoch => $composableBuilder(
    column: $table.startedAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endedAtEpoch => $composableBuilder(
    column: $table.endedAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assignedLocationIdsJson => $composableBuilder(
    column: $table.assignedLocationIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assignedLocationNamesJson => $composableBuilder(
    column: $table.assignedLocationNamesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => column,
  );
}

class $$EmployeesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmployeesTableTable,
          EmployeesTableData,
          $$EmployeesTableTableFilterComposer,
          $$EmployeesTableTableOrderingComposer,
          $$EmployeesTableTableAnnotationComposer,
          $$EmployeesTableTableCreateCompanionBuilder,
          $$EmployeesTableTableUpdateCompanionBuilder,
          (
            EmployeesTableData,
            BaseReferences<
              _$AppDatabase,
              $EmployeesTableTable,
              EmployeesTableData
            >,
          ),
          EmployeesTableData,
          PrefetchHooks Function()
        > {
  $$EmployeesTableTableTableManager(
    _$AppDatabase db,
    $EmployeesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> employmentStatus = const Value.absent(),
                Value<int?> startedAtEpoch = const Value.absent(),
                Value<int?> endedAtEpoch = const Value.absent(),
                Value<String> assignedLocationIdsJson = const Value.absent(),
                Value<String> assignedLocationNamesJson = const Value.absent(),
                Value<int> cachedAtEpoch = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmployeesTableCompanion(
                id: id,
                businessId: businessId,
                name: name,
                phone: phone,
                email: email,
                status: status,
                isActive: isActive,
                employmentStatus: employmentStatus,
                startedAtEpoch: startedAtEpoch,
                endedAtEpoch: endedAtEpoch,
                assignedLocationIdsJson: assignedLocationIdsJson,
                assignedLocationNamesJson: assignedLocationNamesJson,
                cachedAtEpoch: cachedAtEpoch,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String name,
                Value<String> phone = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> employmentStatus = const Value.absent(),
                Value<int?> startedAtEpoch = const Value.absent(),
                Value<int?> endedAtEpoch = const Value.absent(),
                Value<String> assignedLocationIdsJson = const Value.absent(),
                Value<String> assignedLocationNamesJson = const Value.absent(),
                required int cachedAtEpoch,
                Value<int> rowid = const Value.absent(),
              }) => EmployeesTableCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                phone: phone,
                email: email,
                status: status,
                isActive: isActive,
                employmentStatus: employmentStatus,
                startedAtEpoch: startedAtEpoch,
                endedAtEpoch: endedAtEpoch,
                assignedLocationIdsJson: assignedLocationIdsJson,
                assignedLocationNamesJson: assignedLocationNamesJson,
                cachedAtEpoch: cachedAtEpoch,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmployeesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmployeesTableTable,
      EmployeesTableData,
      $$EmployeesTableTableFilterComposer,
      $$EmployeesTableTableOrderingComposer,
      $$EmployeesTableTableAnnotationComposer,
      $$EmployeesTableTableCreateCompanionBuilder,
      $$EmployeesTableTableUpdateCompanionBuilder,
      (
        EmployeesTableData,
        BaseReferences<_$AppDatabase, $EmployeesTableTable, EmployeesTableData>,
      ),
      EmployeesTableData,
      PrefetchHooks Function()
    >;
typedef $$OrdersTableTableCreateCompanionBuilder =
    OrdersTableCompanion Function({
      required String id,
      required String scopeKey,
      Value<String> orderCode,
      Value<String?> customerName,
      Value<String?> customerPhone,
      required String locationId,
      Value<String> locationName,
      required String status,
      Value<String> itemsJson,
      Value<double> subtotal,
      Value<double> discountAmount,
      Value<double> taxAmount,
      Value<double> totalAmount,
      Value<double> cashAmount,
      Value<double> bankAmount,
      Value<double> debtAmount,
      Value<int?> debtorId,
      Value<String?> note,
      required int createdAtEpoch,
      required int updatedAtEpoch,
      Value<int?> completedAtEpoch,
      Value<int?> cancelledAtEpoch,
      Value<String?> cancelReason,
      Value<String?> invoiceNumber,
      Value<int?> invoicedAtEpoch,
      required int cachedAtEpoch,
      Value<int> rowid,
    });
typedef $$OrdersTableTableUpdateCompanionBuilder =
    OrdersTableCompanion Function({
      Value<String> id,
      Value<String> scopeKey,
      Value<String> orderCode,
      Value<String?> customerName,
      Value<String?> customerPhone,
      Value<String> locationId,
      Value<String> locationName,
      Value<String> status,
      Value<String> itemsJson,
      Value<double> subtotal,
      Value<double> discountAmount,
      Value<double> taxAmount,
      Value<double> totalAmount,
      Value<double> cashAmount,
      Value<double> bankAmount,
      Value<double> debtAmount,
      Value<int?> debtorId,
      Value<String?> note,
      Value<int> createdAtEpoch,
      Value<int> updatedAtEpoch,
      Value<int?> completedAtEpoch,
      Value<int?> cancelledAtEpoch,
      Value<String?> cancelReason,
      Value<String?> invoiceNumber,
      Value<int?> invoicedAtEpoch,
      Value<int> cachedAtEpoch,
      Value<int> rowid,
    });

class $$OrdersTableTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTableTable> {
  $$OrdersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderCode => $composableBuilder(
    column: $table.orderCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashAmount => $composableBuilder(
    column: $table.cashAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bankAmount => $composableBuilder(
    column: $table.bankAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get debtAmount => $composableBuilder(
    column: $table.debtAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get debtorId => $composableBuilder(
    column: $table.debtorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtEpoch => $composableBuilder(
    column: $table.createdAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAtEpoch => $composableBuilder(
    column: $table.completedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cancelledAtEpoch => $composableBuilder(
    column: $table.cancelledAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get invoicedAtEpoch => $composableBuilder(
    column: $table.invoicedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrdersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTableTable> {
  $$OrdersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderCode => $composableBuilder(
    column: $table.orderCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashAmount => $composableBuilder(
    column: $table.cashAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bankAmount => $composableBuilder(
    column: $table.bankAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get debtAmount => $composableBuilder(
    column: $table.debtAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get debtorId => $composableBuilder(
    column: $table.debtorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtEpoch => $composableBuilder(
    column: $table.createdAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAtEpoch => $composableBuilder(
    column: $table.completedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cancelledAtEpoch => $composableBuilder(
    column: $table.cancelledAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get invoicedAtEpoch => $composableBuilder(
    column: $table.invoicedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrdersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTableTable> {
  $$OrdersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<String> get orderCode =>
      $composableBuilder(column: $table.orderCode, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cashAmount => $composableBuilder(
    column: $table.cashAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bankAmount => $composableBuilder(
    column: $table.bankAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get debtAmount => $composableBuilder(
    column: $table.debtAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get debtorId =>
      $composableBuilder(column: $table.debtorId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAtEpoch => $composableBuilder(
    column: $table.createdAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedAtEpoch => $composableBuilder(
    column: $table.completedAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cancelledAtEpoch => $composableBuilder(
    column: $table.cancelledAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get invoicedAtEpoch => $composableBuilder(
    column: $table.invoicedAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => column,
  );
}

class $$OrdersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdersTableTable,
          OrdersTableData,
          $$OrdersTableTableFilterComposer,
          $$OrdersTableTableOrderingComposer,
          $$OrdersTableTableAnnotationComposer,
          $$OrdersTableTableCreateCompanionBuilder,
          $$OrdersTableTableUpdateCompanionBuilder,
          (
            OrdersTableData,
            BaseReferences<_$AppDatabase, $OrdersTableTable, OrdersTableData>,
          ),
          OrdersTableData,
          PrefetchHooks Function()
        > {
  $$OrdersTableTableTableManager(_$AppDatabase db, $OrdersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scopeKey = const Value.absent(),
                Value<String> orderCode = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerPhone = const Value.absent(),
                Value<String> locationId = const Value.absent(),
                Value<String> locationName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> taxAmount = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<double> cashAmount = const Value.absent(),
                Value<double> bankAmount = const Value.absent(),
                Value<double> debtAmount = const Value.absent(),
                Value<int?> debtorId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdAtEpoch = const Value.absent(),
                Value<int> updatedAtEpoch = const Value.absent(),
                Value<int?> completedAtEpoch = const Value.absent(),
                Value<int?> cancelledAtEpoch = const Value.absent(),
                Value<String?> cancelReason = const Value.absent(),
                Value<String?> invoiceNumber = const Value.absent(),
                Value<int?> invoicedAtEpoch = const Value.absent(),
                Value<int> cachedAtEpoch = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersTableCompanion(
                id: id,
                scopeKey: scopeKey,
                orderCode: orderCode,
                customerName: customerName,
                customerPhone: customerPhone,
                locationId: locationId,
                locationName: locationName,
                status: status,
                itemsJson: itemsJson,
                subtotal: subtotal,
                discountAmount: discountAmount,
                taxAmount: taxAmount,
                totalAmount: totalAmount,
                cashAmount: cashAmount,
                bankAmount: bankAmount,
                debtAmount: debtAmount,
                debtorId: debtorId,
                note: note,
                createdAtEpoch: createdAtEpoch,
                updatedAtEpoch: updatedAtEpoch,
                completedAtEpoch: completedAtEpoch,
                cancelledAtEpoch: cancelledAtEpoch,
                cancelReason: cancelReason,
                invoiceNumber: invoiceNumber,
                invoicedAtEpoch: invoicedAtEpoch,
                cachedAtEpoch: cachedAtEpoch,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scopeKey,
                Value<String> orderCode = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerPhone = const Value.absent(),
                required String locationId,
                Value<String> locationName = const Value.absent(),
                required String status,
                Value<String> itemsJson = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> taxAmount = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<double> cashAmount = const Value.absent(),
                Value<double> bankAmount = const Value.absent(),
                Value<double> debtAmount = const Value.absent(),
                Value<int?> debtorId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int createdAtEpoch,
                required int updatedAtEpoch,
                Value<int?> completedAtEpoch = const Value.absent(),
                Value<int?> cancelledAtEpoch = const Value.absent(),
                Value<String?> cancelReason = const Value.absent(),
                Value<String?> invoiceNumber = const Value.absent(),
                Value<int?> invoicedAtEpoch = const Value.absent(),
                required int cachedAtEpoch,
                Value<int> rowid = const Value.absent(),
              }) => OrdersTableCompanion.insert(
                id: id,
                scopeKey: scopeKey,
                orderCode: orderCode,
                customerName: customerName,
                customerPhone: customerPhone,
                locationId: locationId,
                locationName: locationName,
                status: status,
                itemsJson: itemsJson,
                subtotal: subtotal,
                discountAmount: discountAmount,
                taxAmount: taxAmount,
                totalAmount: totalAmount,
                cashAmount: cashAmount,
                bankAmount: bankAmount,
                debtAmount: debtAmount,
                debtorId: debtorId,
                note: note,
                createdAtEpoch: createdAtEpoch,
                updatedAtEpoch: updatedAtEpoch,
                completedAtEpoch: completedAtEpoch,
                cancelledAtEpoch: cancelledAtEpoch,
                cancelReason: cancelReason,
                invoiceNumber: invoiceNumber,
                invoicedAtEpoch: invoicedAtEpoch,
                cachedAtEpoch: cachedAtEpoch,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrdersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdersTableTable,
      OrdersTableData,
      $$OrdersTableTableFilterComposer,
      $$OrdersTableTableOrderingComposer,
      $$OrdersTableTableAnnotationComposer,
      $$OrdersTableTableCreateCompanionBuilder,
      $$OrdersTableTableUpdateCompanionBuilder,
      (
        OrdersTableData,
        BaseReferences<_$AppDatabase, $OrdersTableTable, OrdersTableData>,
      ),
      OrdersTableData,
      PrefetchHooks Function()
    >;
typedef $$ImportsTableTableCreateCompanionBuilder =
    ImportsTableCompanion Function({
      required int id,
      required String scopeKey,
      Value<String> importCode,
      Value<String> importType,
      Value<String> status,
      required int businessLocationId,
      Value<String> businessLocationName,
      Value<String?> supplier,
      Value<String?> note,
      Value<int?> receivedAtEpoch,
      Value<double> totalAmount,
      required int createdAtEpoch,
      Value<int?> updatedAtEpoch,
      Value<String?> imageUrl,
      Value<String> itemsJson,
      required int cachedAtEpoch,
      Value<int> rowid,
    });
typedef $$ImportsTableTableUpdateCompanionBuilder =
    ImportsTableCompanion Function({
      Value<int> id,
      Value<String> scopeKey,
      Value<String> importCode,
      Value<String> importType,
      Value<String> status,
      Value<int> businessLocationId,
      Value<String> businessLocationName,
      Value<String?> supplier,
      Value<String?> note,
      Value<int?> receivedAtEpoch,
      Value<double> totalAmount,
      Value<int> createdAtEpoch,
      Value<int?> updatedAtEpoch,
      Value<String?> imageUrl,
      Value<String> itemsJson,
      Value<int> cachedAtEpoch,
      Value<int> rowid,
    });

class $$ImportsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ImportsTableTable> {
  $$ImportsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importCode => $composableBuilder(
    column: $table.importCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importType => $composableBuilder(
    column: $table.importType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessLocationName => $composableBuilder(
    column: $table.businessLocationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplier => $composableBuilder(
    column: $table.supplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedAtEpoch => $composableBuilder(
    column: $table.receivedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtEpoch => $composableBuilder(
    column: $table.createdAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportsTableTable> {
  $$ImportsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importCode => $composableBuilder(
    column: $table.importCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importType => $composableBuilder(
    column: $table.importType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessLocationName => $composableBuilder(
    column: $table.businessLocationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplier => $composableBuilder(
    column: $table.supplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedAtEpoch => $composableBuilder(
    column: $table.receivedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtEpoch => $composableBuilder(
    column: $table.createdAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportsTableTable> {
  $$ImportsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<String> get importCode => $composableBuilder(
    column: $table.importCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get importType => $composableBuilder(
    column: $table.importType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessLocationName => $composableBuilder(
    column: $table.businessLocationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supplier =>
      $composableBuilder(column: $table.supplier, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get receivedAtEpoch => $composableBuilder(
    column: $table.receivedAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtEpoch => $composableBuilder(
    column: $table.createdAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => column,
  );
}

class $$ImportsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportsTableTable,
          ImportsTableData,
          $$ImportsTableTableFilterComposer,
          $$ImportsTableTableOrderingComposer,
          $$ImportsTableTableAnnotationComposer,
          $$ImportsTableTableCreateCompanionBuilder,
          $$ImportsTableTableUpdateCompanionBuilder,
          (
            ImportsTableData,
            BaseReferences<_$AppDatabase, $ImportsTableTable, ImportsTableData>,
          ),
          ImportsTableData,
          PrefetchHooks Function()
        > {
  $$ImportsTableTableTableManager(_$AppDatabase db, $ImportsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> scopeKey = const Value.absent(),
                Value<String> importCode = const Value.absent(),
                Value<String> importType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> businessLocationId = const Value.absent(),
                Value<String> businessLocationName = const Value.absent(),
                Value<String?> supplier = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> receivedAtEpoch = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<int> createdAtEpoch = const Value.absent(),
                Value<int?> updatedAtEpoch = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<int> cachedAtEpoch = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportsTableCompanion(
                id: id,
                scopeKey: scopeKey,
                importCode: importCode,
                importType: importType,
                status: status,
                businessLocationId: businessLocationId,
                businessLocationName: businessLocationName,
                supplier: supplier,
                note: note,
                receivedAtEpoch: receivedAtEpoch,
                totalAmount: totalAmount,
                createdAtEpoch: createdAtEpoch,
                updatedAtEpoch: updatedAtEpoch,
                imageUrl: imageUrl,
                itemsJson: itemsJson,
                cachedAtEpoch: cachedAtEpoch,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int id,
                required String scopeKey,
                Value<String> importCode = const Value.absent(),
                Value<String> importType = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int businessLocationId,
                Value<String> businessLocationName = const Value.absent(),
                Value<String?> supplier = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> receivedAtEpoch = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                required int createdAtEpoch,
                Value<int?> updatedAtEpoch = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                required int cachedAtEpoch,
                Value<int> rowid = const Value.absent(),
              }) => ImportsTableCompanion.insert(
                id: id,
                scopeKey: scopeKey,
                importCode: importCode,
                importType: importType,
                status: status,
                businessLocationId: businessLocationId,
                businessLocationName: businessLocationName,
                supplier: supplier,
                note: note,
                receivedAtEpoch: receivedAtEpoch,
                totalAmount: totalAmount,
                createdAtEpoch: createdAtEpoch,
                updatedAtEpoch: updatedAtEpoch,
                imageUrl: imageUrl,
                itemsJson: itemsJson,
                cachedAtEpoch: cachedAtEpoch,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportsTableTable,
      ImportsTableData,
      $$ImportsTableTableFilterComposer,
      $$ImportsTableTableOrderingComposer,
      $$ImportsTableTableAnnotationComposer,
      $$ImportsTableTableCreateCompanionBuilder,
      $$ImportsTableTableUpdateCompanionBuilder,
      (
        ImportsTableData,
        BaseReferences<_$AppDatabase, $ImportsTableTable, ImportsTableData>,
      ),
      ImportsTableData,
      PrefetchHooks Function()
    >;
typedef $$ApiCacheEntriesTableTableCreateCompanionBuilder =
    ApiCacheEntriesTableCompanion Function({
      required String cacheKey,
      Value<String?> groupKey,
      required String payloadJson,
      Value<String> cacheType,
      required int cachedAtEpoch,
      Value<int> rowid,
    });
typedef $$ApiCacheEntriesTableTableUpdateCompanionBuilder =
    ApiCacheEntriesTableCompanion Function({
      Value<String> cacheKey,
      Value<String?> groupKey,
      Value<String> payloadJson,
      Value<String> cacheType,
      Value<int> cachedAtEpoch,
      Value<int> rowid,
    });

class $$ApiCacheEntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ApiCacheEntriesTableTable> {
  $$ApiCacheEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cacheType => $composableBuilder(
    column: $table.cacheType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ApiCacheEntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiCacheEntriesTableTable> {
  $$ApiCacheEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cacheType => $composableBuilder(
    column: $table.cacheType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ApiCacheEntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiCacheEntriesTableTable> {
  $$ApiCacheEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get groupKey =>
      $composableBuilder(column: $table.groupKey, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cacheType =>
      $composableBuilder(column: $table.cacheType, builder: (column) => column);

  GeneratedColumn<int> get cachedAtEpoch => $composableBuilder(
    column: $table.cachedAtEpoch,
    builder: (column) => column,
  );
}

class $$ApiCacheEntriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApiCacheEntriesTableTable,
          ApiCacheEntriesTableData,
          $$ApiCacheEntriesTableTableFilterComposer,
          $$ApiCacheEntriesTableTableOrderingComposer,
          $$ApiCacheEntriesTableTableAnnotationComposer,
          $$ApiCacheEntriesTableTableCreateCompanionBuilder,
          $$ApiCacheEntriesTableTableUpdateCompanionBuilder,
          (
            ApiCacheEntriesTableData,
            BaseReferences<
              _$AppDatabase,
              $ApiCacheEntriesTableTable,
              ApiCacheEntriesTableData
            >,
          ),
          ApiCacheEntriesTableData,
          PrefetchHooks Function()
        > {
  $$ApiCacheEntriesTableTableTableManager(
    _$AppDatabase db,
    $ApiCacheEntriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiCacheEntriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiCacheEntriesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ApiCacheEntriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String?> groupKey = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> cacheType = const Value.absent(),
                Value<int> cachedAtEpoch = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiCacheEntriesTableCompanion(
                cacheKey: cacheKey,
                groupKey: groupKey,
                payloadJson: payloadJson,
                cacheType: cacheType,
                cachedAtEpoch: cachedAtEpoch,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                Value<String?> groupKey = const Value.absent(),
                required String payloadJson,
                Value<String> cacheType = const Value.absent(),
                required int cachedAtEpoch,
                Value<int> rowid = const Value.absent(),
              }) => ApiCacheEntriesTableCompanion.insert(
                cacheKey: cacheKey,
                groupKey: groupKey,
                payloadJson: payloadJson,
                cacheType: cacheType,
                cachedAtEpoch: cachedAtEpoch,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ApiCacheEntriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApiCacheEntriesTableTable,
      ApiCacheEntriesTableData,
      $$ApiCacheEntriesTableTableFilterComposer,
      $$ApiCacheEntriesTableTableOrderingComposer,
      $$ApiCacheEntriesTableTableAnnotationComposer,
      $$ApiCacheEntriesTableTableCreateCompanionBuilder,
      $$ApiCacheEntriesTableTableUpdateCompanionBuilder,
      (
        ApiCacheEntriesTableData,
        BaseReferences<
          _$AppDatabase,
          $ApiCacheEntriesTableTable,
          ApiCacheEntriesTableData
        >,
      ),
      ApiCacheEntriesTableData,
      PrefetchHooks Function()
    >;
typedef $$InvoiceTemplateSettingsTableTableCreateCompanionBuilder =
    InvoiceTemplateSettingsTableCompanion Function({
      required String accountScope,
      required String payloadJson,
      required int updatedAtEpoch,
      Value<int> rowid,
    });
typedef $$InvoiceTemplateSettingsTableTableUpdateCompanionBuilder =
    InvoiceTemplateSettingsTableCompanion Function({
      Value<String> accountScope,
      Value<String> payloadJson,
      Value<int> updatedAtEpoch,
      Value<int> rowid,
    });

class $$InvoiceTemplateSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $InvoiceTemplateSettingsTableTable> {
  $$InvoiceTemplateSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InvoiceTemplateSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoiceTemplateSettingsTableTable> {
  $$InvoiceTemplateSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InvoiceTemplateSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoiceTemplateSettingsTableTable> {
  $$InvoiceTemplateSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => column,
  );
}

class $$InvoiceTemplateSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoiceTemplateSettingsTableTable,
          InvoiceTemplateSettingsTableData,
          $$InvoiceTemplateSettingsTableTableFilterComposer,
          $$InvoiceTemplateSettingsTableTableOrderingComposer,
          $$InvoiceTemplateSettingsTableTableAnnotationComposer,
          $$InvoiceTemplateSettingsTableTableCreateCompanionBuilder,
          $$InvoiceTemplateSettingsTableTableUpdateCompanionBuilder,
          (
            InvoiceTemplateSettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $InvoiceTemplateSettingsTableTable,
              InvoiceTemplateSettingsTableData
            >,
          ),
          InvoiceTemplateSettingsTableData,
          PrefetchHooks Function()
        > {
  $$InvoiceTemplateSettingsTableTableTableManager(
    _$AppDatabase db,
    $InvoiceTemplateSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoiceTemplateSettingsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InvoiceTemplateSettingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InvoiceTemplateSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountScope = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> updatedAtEpoch = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoiceTemplateSettingsTableCompanion(
                accountScope: accountScope,
                payloadJson: payloadJson,
                updatedAtEpoch: updatedAtEpoch,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountScope,
                required String payloadJson,
                required int updatedAtEpoch,
                Value<int> rowid = const Value.absent(),
              }) => InvoiceTemplateSettingsTableCompanion.insert(
                accountScope: accountScope,
                payloadJson: payloadJson,
                updatedAtEpoch: updatedAtEpoch,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InvoiceTemplateSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoiceTemplateSettingsTableTable,
      InvoiceTemplateSettingsTableData,
      $$InvoiceTemplateSettingsTableTableFilterComposer,
      $$InvoiceTemplateSettingsTableTableOrderingComposer,
      $$InvoiceTemplateSettingsTableTableAnnotationComposer,
      $$InvoiceTemplateSettingsTableTableCreateCompanionBuilder,
      $$InvoiceTemplateSettingsTableTableUpdateCompanionBuilder,
      (
        InvoiceTemplateSettingsTableData,
        BaseReferences<
          _$AppDatabase,
          $InvoiceTemplateSettingsTableTable,
          InvoiceTemplateSettingsTableData
        >,
      ),
      InvoiceTemplateSettingsTableData,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableTableCreateCompanionBuilder =
    SyncStateTableCompanion Function({
      required String resourceKey,
      Value<String> businessId,
      required int lastSyncedAtEpoch,
      Value<String?> etag,
      Value<int> rowid,
    });
typedef $$SyncStateTableTableUpdateCompanionBuilder =
    SyncStateTableCompanion Function({
      Value<String> resourceKey,
      Value<String> businessId,
      Value<int> lastSyncedAtEpoch,
      Value<String?> etag,
      Value<int> rowid,
    });

class $$SyncStateTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTableTable> {
  $$SyncStateTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resourceKey => $composableBuilder(
    column: $table.resourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAtEpoch => $composableBuilder(
    column: $table.lastSyncedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTableTable> {
  $$SyncStateTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resourceKey => $composableBuilder(
    column: $table.resourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAtEpoch => $composableBuilder(
    column: $table.lastSyncedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTableTable> {
  $$SyncStateTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resourceKey => $composableBuilder(
    column: $table.resourceKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncedAtEpoch => $composableBuilder(
    column: $table.lastSyncedAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);
}

class $$SyncStateTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTableTable,
          SyncStateTableData,
          $$SyncStateTableTableFilterComposer,
          $$SyncStateTableTableOrderingComposer,
          $$SyncStateTableTableAnnotationComposer,
          $$SyncStateTableTableCreateCompanionBuilder,
          $$SyncStateTableTableUpdateCompanionBuilder,
          (
            SyncStateTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncStateTableTable,
              SyncStateTableData
            >,
          ),
          SyncStateTableData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableTableManager(
    _$AppDatabase db,
    $SyncStateTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> resourceKey = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<int> lastSyncedAtEpoch = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateTableCompanion(
                resourceKey: resourceKey,
                businessId: businessId,
                lastSyncedAtEpoch: lastSyncedAtEpoch,
                etag: etag,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String resourceKey,
                Value<String> businessId = const Value.absent(),
                required int lastSyncedAtEpoch,
                Value<String?> etag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateTableCompanion.insert(
                resourceKey: resourceKey,
                businessId: businessId,
                lastSyncedAtEpoch: lastSyncedAtEpoch,
                etag: etag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTableTable,
      SyncStateTableData,
      $$SyncStateTableTableFilterComposer,
      $$SyncStateTableTableOrderingComposer,
      $$SyncStateTableTableAnnotationComposer,
      $$SyncStateTableTableCreateCompanionBuilder,
      $$SyncStateTableTableUpdateCompanionBuilder,
      (
        SyncStateTableData,
        BaseReferences<_$AppDatabase, $SyncStateTableTable, SyncStateTableData>,
      ),
      SyncStateTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocationsTableTableTableManager get locationsTable =>
      $$LocationsTableTableTableManager(_db, _db.locationsTable);
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db, _db.productsTable);
  $$EmployeesTableTableTableManager get employeesTable =>
      $$EmployeesTableTableTableManager(_db, _db.employeesTable);
  $$OrdersTableTableTableManager get ordersTable =>
      $$OrdersTableTableTableManager(_db, _db.ordersTable);
  $$ImportsTableTableTableManager get importsTable =>
      $$ImportsTableTableTableManager(_db, _db.importsTable);
  $$ApiCacheEntriesTableTableTableManager get apiCacheEntriesTable =>
      $$ApiCacheEntriesTableTableTableManager(_db, _db.apiCacheEntriesTable);
  $$InvoiceTemplateSettingsTableTableTableManager
  get invoiceTemplateSettingsTable =>
      $$InvoiceTemplateSettingsTableTableTableManager(
        _db,
        _db.invoiceTemplateSettingsTable,
      );
  $$SyncStateTableTableTableManager get syncStateTable =>
      $$SyncStateTableTableTableManager(_db, _db.syncStateTable);
}
