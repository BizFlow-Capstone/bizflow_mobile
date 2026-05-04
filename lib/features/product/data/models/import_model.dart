// Import Models - Manual JSON serialization (no code generation required)
import '../../../../core/reference/data/reference_item.dart';
import '../../../../shared/utils/date_formatter.dart';

class ImportItemModel {
  final int productId;
  final String? productName;
  final double quantity;
  final String? baseUnit;
  final double costPrice;
  final double? totalPrice;
  final double? currentStock;

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
    double parseDouble(dynamic value, {double fallback = 0.0}) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString().trim()) ?? fallback;
    }

    int parseInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString().trim()) ?? fallback;
    }

    String? parseString(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    return ImportItemModel(
      productId: parseInt(
        json['productId'] ?? json['ProductId'] ?? json['productID'],
      ),
      productName: parseString(json['productName'] ?? json['ProductName']),
      quantity: parseDouble(json['quantity'] ?? json['Quantity']),
      baseUnit: parseString(
        json['baseUnit'] ??
            json['BaseUnit'] ??
            json['unitName'] ??
            json['UnitName'] ??
            json['unit'] ??
            json['Unit'],
      ),
      costPrice: parseDouble(json['costPrice'] ?? json['CostPrice']),
      totalPrice: (() {
        final raw = json['totalPrice'] ?? json['TotalPrice'];
        if (raw == null) return null;
        return parseDouble(raw);
      })(),
      currentStock: (() {
        final raw = json['currentStock'] ?? json['CurrentStock'];
        if (raw == null) return null;
        return parseDouble(raw);
      })(),
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
  final String? statusLabel;
  final int businessLocationId;
  final String businessLocationName;
  final String? supplier;
  final String? note;
  final DateTime? receivedAt;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? imageUrl;
  final String? paymentMethod;

  ImportHistoryItemModel({
    required this.importId,
    required this.importCode,
    required this.importType,
    required this.status,
    this.statusLabel,
    required this.businessLocationId,
    required this.businessLocationName,
    this.supplier,
    this.note,
    this.receivedAt,
    required this.totalAmount,
    required this.createdAt,
    this.updatedAt,
    this.imageUrl,
    this.paymentMethod,
  });

  factory ImportHistoryItemModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value, DateTime fallback) {
      if (value is String) {
        return DateFormatter.parseApiDateTime(value, fallback: fallback) ??
            fallback;
      }
      return fallback;
    }

    final rawStatus = json['status'] ?? json['Status'];
    final rawImportType = json['importType'] ?? json['ImportType'];

    return ImportHistoryItemModel(
      importId: (json['importId'] ?? json['ImportId'] ?? 0) as int,
      importCode: (json['importCode'] ?? json['ImportCode'] ?? '').toString(),
      importType: referenceCodeFromDynamic(rawImportType).trim().toUpperCase(),
      status: referenceCodeFromDynamic(rawStatus).trim().toUpperCase(),
      statusLabel: referenceLabelFromDynamic(rawStatus),
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
      paymentMethod: (() {
        final raw = json['paymentMethod'] ?? json['PaymentMethod'];
        if (raw is String && raw.trim().isNotEmpty) return raw.trim();
        if (raw is Map) return (raw['code'] ?? raw['Code'])?.toString();
        return null;
      })(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'importId': importId,
      'importCode': importCode,
      'importType': importType,
      'status': status,
      if ((statusLabel ?? '').trim().isNotEmpty) 'statusLabel': statusLabel,
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
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    };
  }
}

class ImportDetailModel extends ImportHistoryItemModel {
  final List<ImportItemModel> items;
  final String? documentNumber;

  ImportDetailModel({
    required super.importId,
    required super.importCode,
    required super.importType,
    required super.status,
    super.statusLabel,
    required super.businessLocationId,
    required super.businessLocationName,
    super.supplier,
    super.note,
    super.receivedAt,
    required super.totalAmount,
    required super.createdAt,
    super.updatedAt,
    super.imageUrl,
    super.paymentMethod,
    required this.items,
    this.documentNumber,
  });

  factory ImportDetailModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString().trim()) ?? fallback;
    }

    double parseDouble(dynamic value, {double fallback = 0.0}) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString().trim()) ?? fallback;
    }

    String parseRequiredString(dynamic value) {
      return (value ?? '').toString();
    }

    String? parseNullableString(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    final itemsRaw =
        (json['items'] ??
                json['Items'] ??
                json['importItems'] ??
                json['ImportItems'])
            as List<dynamic>? ??
        [];

    final rawStatus = json['status'] ?? json['Status'];
    final rawImportType = json['importType'] ?? json['ImportType'];

    return ImportDetailModel(
      importId: parseInt(json['importId'] ?? json['ImportId']),
      importCode: parseRequiredString(json['importCode'] ?? json['ImportCode']),
      importType: referenceCodeFromDynamic(rawImportType).trim().toUpperCase(),
      status: referenceCodeFromDynamic(rawStatus).trim().toUpperCase(),
      statusLabel: referenceLabelFromDynamic(rawStatus),
      businessLocationId: parseInt(
        json['businessLocationId'] ?? json['BusinessLocationId'],
      ),
      businessLocationName: parseRequiredString(
        json['businessLocationName'] ?? json['BusinessLocationName'],
      ),
      supplier: parseNullableString(json['supplier'] ?? json['Supplier']),
      note: parseNullableString(json['note'] ?? json['Note']),
      receivedAt: DateFormatter.parseApiDateTime(
        (json['receivedAt'] ?? json['ReceivedAt']) as String?,
      ),
      totalAmount: parseDouble(json['totalAmount'] ?? json['TotalAmount']),
      createdAt:
          DateFormatter.parseApiDateTime(
            (json['createdAt'] ?? json['CreatedAt']) as String?,
            fallback: DateTime.now().toUtc(),
          ) ??
          DateTime.now().toUtc(),
      updatedAt: DateFormatter.parseApiDateTime(
        (json['updatedAt'] ?? json['UpdatedAt']) as String?,
      ),
      imageUrl: parseNullableString(
        json['imageUrl'] ??
            json['ImageUrl'] ??
            json['invoiceImageUrl'] ??
            json['InvoiceImageUrl'] ??
            json['receiptImageUrl'] ??
            json['ReceiptImageUrl'] ??
            json['image'] ??
            json['Image'],
      ),
      items: itemsRaw
          .map((e) => ImportItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      documentNumber: parseNullableString(
        json['documentNumber'] ?? json['DocumentNumber'],
      ),
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
  final String? paymentMethod;

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
    this.paymentMethod,
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
      if (paymentMethod != null && paymentMethod!.isNotEmpty)
        'paymentMethod': paymentMethod,
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
  final String? paymentMethod;
  final String? idempotencyKey;

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
    this.paymentMethod,
    this.idempotencyKey,
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
      if (paymentMethod != null && paymentMethod!.isNotEmpty)
        'paymentMethod': paymentMethod,
    };
  }
}

class ConfirmImportRequest {
  final DateTime receivedAt;
  final String? idempotencyKey;
  final String? paymentMethod;

  ConfirmImportRequest({
    required this.receivedAt,
    this.idempotencyKey,
    this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'receivedAt': DateFormatter.toApiUtcIsoString(receivedAt),
      if (idempotencyKey != null && idempotencyKey!.isNotEmpty)
        'idempotencyKey': idempotencyKey,
      if (paymentMethod != null && paymentMethod!.isNotEmpty)
        'paymentMethod': paymentMethod,
    };
  }
}
