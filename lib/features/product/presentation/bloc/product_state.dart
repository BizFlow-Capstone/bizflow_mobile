import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entity.dart';

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
  final bool hasReachedMax;
  final int currentPage;

  const ProductsLoaded({
    required this.products,
    required this.locationId,
    this.searchQuery,
    this.filterStatus,
    this.filterCategory,
    this.sortBy,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  ProductsLoaded copyWith({
    List<ProductEntity>? products,
    String? locationId,
    String? searchQuery,
    String? filterStatus,
    String? filterCategory,
    String? sortBy,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return ProductsLoaded(
      products: products ?? this.products,
      locationId: locationId ?? this.locationId,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
      filterCategory: filterCategory ?? this.filterCategory,
      sortBy: sortBy ?? this.sortBy,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
    products,
    locationId,
    searchQuery,
    filterStatus,
    filterCategory,
    sortBy,
    hasReachedMax,
    currentPage,
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

/// Product sale items loaded
class ProductSaleItemsLoaded extends ProductState {
  final List<Map<String, dynamic>> saleItems;

  const ProductSaleItemsLoaded({required this.saleItems});

  @override
  List<Object?> get props => [saleItems];
}

/// Failure state
class ProductFailure extends ProductState {
  final String message;

  const ProductFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
