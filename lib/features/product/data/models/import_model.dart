// Import Models - Manual JSON serialization (no code generation required)
import '../../../../shared/utils/date_formatter.dart';

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
  final String? imageUrl;

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
    this.imageUrl,
  });

  factory ImportHistoryItemModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value, DateTime fallback) {
      if (value is String) {
        return DateFormatter.parseApiDateTime(value, fallback: fallback) ??
            fallback;
      }
      return fallback;
    }

    return ImportHistoryItemModel(
      importId: (json['importId'] ?? json['ImportId'] ?? 0) as int,
      importCode: (json['importCode'] ?? json['ImportCode'] ?? '').toString(),
      importType: (json['importType'] ?? json['ImportType'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? '').toString(),
      businessLocationId:
          (json['businessLocationId'] ?? json['BusinessLocationId'] ?? 0)
              as int,
      businessLocationName:
          (json['businessLocationName'] ?? json['BusinessLocationName'] ?? '')
              .toString(),
      supplier: json['supplier'] as String?,
      note: json['note'] as String?,
      receivedAt: DateFormatter.parseApiDateTime(
        (json['receivedAt'] ?? json['ReceivedAt']) as String?,
      ),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDateTime(
        json['createdAt'] ?? json['CreatedAt'],
        DateTime.now().toUtc(),
      ),
      updatedAt: DateFormatter.parseApiDateTime(
        (json['updatedAt'] ?? json['UpdatedAt']) as String?,
      ),
      imageUrl: (json['imageUrl'] ?? json['ImageUrl']) as String?,
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
      if (receivedAt != null)
        'receivedAt': DateFormatter.toApiUtcIsoString(receivedAt!),
      'totalAmount': totalAmount,
      'createdAt': DateFormatter.toApiUtcIsoString(createdAt),
      if (updatedAt != null)
        'updatedAt': DateFormatter.toApiUtcIsoString(updatedAt!),
      if (imageUrl != null) 'imageUrl': imageUrl,
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
    super.imageUrl,
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
      receivedAt: DateFormatter.parseApiDateTime(json['receivedAt'] as String?),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt:
          DateFormatter.parseApiDateTime(
            json['createdAt'] as String?,
            fallback: DateTime.now().toUtc(),
          ) ??
          DateTime.now().toUtc(),
      updatedAt: DateFormatter.parseApiDateTime(json['updatedAt'] as String?),
      imageUrl: json['imageUrl'] as String?,
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
  final DateTime? documentDate;
  final String? documentNumber;
  final bool saveAsDraft;
  final String? imagePath;
  final List<ImportItemModel> items;

  CreateImportRequest({
    required this.importType,
    required this.businessLocationId,
    required this.supplier,
    required this.note,
    this.receivedAt,
    this.documentDate,
    this.documentNumber,
    required this.saveAsDraft,
    this.imagePath,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'importType': importType,
      'businessLocationId': businessLocationId,
      'supplier': supplier,
      'note': note,
      if (receivedAt != null)
        'receivedAt': DateFormatter.toApiUtcIsoString(receivedAt!),
      if (documentDate != null)
        'documentDate': DateFormatter.toApiDateOnly(documentDate!),
      if (documentNumber != null && documentNumber!.isNotEmpty)
        'documentNumber': documentNumber,
      'saveAsDraft': saveAsDraft,
      if (imagePath != null) 'imagePath': imagePath,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class UpdateImportRequest {
  final String importType;
  final String supplier;
  final String note;
  final DateTime? receivedAt;
  final DateTime? documentDate;
  final String? documentNumber;
  final List<ImportItemModel> items;
  final String? imagePath;
  final bool removeImage;

  UpdateImportRequest({
    required this.importType,
    required this.supplier,
    required this.note,
    this.receivedAt,
    this.documentDate,
    this.documentNumber,
    required this.items,
    this.imagePath,
    this.removeImage = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'importType': importType,
      'supplier': supplier,
      'note': note,
      if (receivedAt != null)
        'receivedAt': DateFormatter.toApiUtcIsoString(receivedAt!),
      if (documentDate != null)
        'documentDate': DateFormatter.toApiDateOnly(documentDate!),
      if (documentNumber != null && documentNumber!.isNotEmpty)
        'documentNumber': documentNumber,
      'items': items.map((e) => e.toJson()).toList(),
      'removeImage': removeImage,
      if (imagePath != null) 'imagePath': imagePath,
    };
  }
}

class ConfirmImportRequest {
  final DateTime receivedAt;

  ConfirmImportRequest({required this.receivedAt});

  Map<String, dynamic> toJson() {
    return {'receivedAt': DateFormatter.toApiUtcIsoString(receivedAt)};
  }
}
