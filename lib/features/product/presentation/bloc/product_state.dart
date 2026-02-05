import 'package:equatable/equatable.dart';

/// Mock Product Entity for now (no data layer yet)
class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String? barcode;
  final String? category;
  final double? costPrice;
  final double? salePrice;
  final int? quantity;
  final String? unit;
  final bool isActive;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;

  const ProductEntity({
    required this.id,
    required this.name,
    this.barcode,
    this.category,
    this.costPrice,
    this.salePrice,
    this.quantity,
    this.unit,
    this.isActive = true,
    this.description,
    this.imageUrl,
    this.createdAt,
  });

  ProductEntity copyWith({
    String? id,
    String? name,
    String? barcode,
    String? category,
    double? costPrice,
    double? salePrice,
    int? quantity,
    String? unit,
    bool? isActive,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    barcode,
    category,
    costPrice,
    salePrice,
    quantity,
    unit,
    isActive,
    description,
    imageUrl,
    createdAt,
  ];
}

/// Product States
abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ProductInitial extends ProductState {
  const ProductInitial();
}

/// Loading state
class ProductLoading extends ProductState {
  const ProductLoading();
}

/// Products loaded successfully
class ProductsLoaded extends ProductState {
  final List<ProductEntity> products;
  final String locationId;
  final String? searchQuery;
  final String? filterStatus;
  final String? filterCategory;
  final String? sortBy;

  const ProductsLoaded({
    required this.products,
    required this.locationId,
    this.searchQuery,
    this.filterStatus,
    this.filterCategory,
    this.sortBy,
  });

  @override
  List<Object?> get props => [
    products,
    locationId,
    searchQuery,
    filterStatus,
    filterCategory,
    sortBy,
  ];
}

/// Product add in progress
class ProductAddInProgress extends ProductState {
  const ProductAddInProgress();
}

/// Product added successfully
class ProductAddSuccess extends ProductState {
  final ProductEntity product;

  const ProductAddSuccess({required this.product});

  @override
  List<Object?> get props => [product];
}

/// Product update in progress
class ProductUpdateInProgress extends ProductState {
  const ProductUpdateInProgress();
}

/// Product updated successfully
class ProductUpdateSuccess extends ProductState {
  final ProductEntity product;

  const ProductUpdateSuccess({required this.product});

  @override
  List<Object?> get props => [product];
}

/// Product delete in progress
class ProductDeleteInProgress extends ProductState {
  const ProductDeleteInProgress();
}

/// Product deleted successfully
class ProductDeleteSuccess extends ProductState {
  final String productId;

  const ProductDeleteSuccess({required this.productId});

  @override
  List<Object?> get props => [productId];
}

/// Import inventory in progress
class ImportInventoryInProgress extends ProductState {
  const ImportInventoryInProgress();
}

/// Import inventory success
class ImportInventorySuccess extends ProductState {
  final String productId;
  final int quantity;

  const ImportInventorySuccess({
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, quantity];
}

/// Failure state
class ProductFailure extends ProductState {
  final String message;

  const ProductFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
