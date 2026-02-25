/// Import Models - Manual JSON serialization (no code generation required)

class ImportItemModel {
  final int productId;
  final String? productName;
  final int quantity;
  final String? baseUnit;
  final double costPrice;
  final double? totalPrice;
  final int? currentStock;

  ImportItemModel({
    required this.productId,
    this.productName,
    required this.quantity,
    this.baseUnit,
    required this.costPrice,
    this.totalPrice,
    this.currentStock,
  });

  factory ImportItemModel.fromJson(Map<String, dynamic> json) {
    return ImportItemModel(
      productId: json['productId'] as int,
      productName: json['productName'] as String?,
      quantity: json['quantity'] as int,
      baseUnit: json['baseUnit'] as String?,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      currentStock: json['currentStock'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      if (productName != null) 'productName': productName,
      'quantity': quantity,
      if (baseUnit != null) 'baseUnit': baseUnit,
      'costPrice': costPrice,
      if (totalPrice != null) 'totalPrice': totalPrice,
      if (currentStock != null) 'currentStock': currentStock,
    };
  }
}

class ImportHistoryItemModel {
  final int importId;
  final String importCode;
  final String importType;
  final String status;
  final int businessLocationId;
  final String businessLocationName;
  final String? supplier;
  final String? note;
  final DateTime? receivedAt;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ImportHistoryItemModel({
    required this.importId,
    required this.importCode,
    required this.importType,
    required this.status,
    required this.businessLocationId,
    required this.businessLocationName,
    this.supplier,
    this.note,
    this.receivedAt,
    required this.totalAmount,
    required this.createdAt,
    this.updatedAt,
  });

  factory ImportHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return ImportHistoryItemModel(
      importId: json['importId'] as int,
      importCode: json['importCode'] as String,
      importType: json['importType'] as String,
      status: json['status'] as String,
      businessLocationId: json['businessLocationId'] as int,
      businessLocationName: json['businessLocationName'] as String,
      supplier: json['supplier'] as String?,
      note: json['note'] as String?,
      receivedAt: json['receivedAt'] != null
          ? DateTime.tryParse(json['receivedAt'] as String)
          : null,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'importId': importId,
      'importCode': importCode,
      'importType': importType,
      'status': status,
      'businessLocationId': businessLocationId,
      'businessLocationName': businessLocationName,
      if (supplier != null) 'supplier': supplier,
      if (note != null) 'note': note,
      if (receivedAt != null) 'receivedAt': receivedAt!.toIso8601String(),
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

class ImportDetailModel extends ImportHistoryItemModel {
  final List<ImportItemModel> items;

  ImportDetailModel({
    required super.importId,
    required super.importCode,
    required super.importType,
    required super.status,
    required super.businessLocationId,
    required super.businessLocationName,
    super.supplier,
    super.note,
    super.receivedAt,
    required super.totalAmount,
    required super.createdAt,
    super.updatedAt,
    required this.items,
  });

  factory ImportDetailModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? [];
    return ImportDetailModel(
      importId: json['importId'] as int,
      importCode: json['importCode'] as String,
      importType: json['importType'] as String,
      status: json['status'] as String,
      businessLocationId: json['businessLocationId'] as int,
      businessLocationName: json['businessLocationName'] as String,
      supplier: json['supplier'] as String?,
      note: json['note'] as String?,
      receivedAt: json['receivedAt'] != null
          ? DateTime.tryParse(json['receivedAt'] as String)
          : null,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      items: itemsRaw
          .map((e) => ImportItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {...super.toJson(), 'items': items.map((e) => e.toJson()).toList()};
  }
}

class CreateImportRequest {
  final String importType;
  final int businessLocationId;
  final String supplier;
  final String note;
  final DateTime? receivedAt;
  final bool saveAsDraft;
  final List<ImportItemModel> items;

  CreateImportRequest({
    required this.importType,
    required this.businessLocationId,
    required this.supplier,
    required this.note,
    this.receivedAt,
    required this.saveAsDraft,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'importType': importType,
      'businessLocationId': businessLocationId,
      'supplier': supplier,
      'note': note,
      if (receivedAt != null) 'receivedAt': receivedAt!.toIso8601String(),
      'saveAsDraft': saveAsDraft,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class UpdateImportRequest {
  final String importType;
  final String supplier;
  final String note;
  final DateTime? receivedAt;
  final List<ImportItemModel> items;

  UpdateImportRequest({
    required this.importType,
    required this.supplier,
    required this.note,
    this.receivedAt,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'importType': importType,
      'supplier': supplier,
      'note': note,
      if (receivedAt != null) 'receivedAt': receivedAt!.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class ConfirmImportRequest {
  final DateTime receivedAt;

  ConfirmImportRequest({required this.receivedAt});

  Map<String, dynamic> toJson() {
    return {'receivedAt': receivedAt.toIso8601String()};
  }
}
