import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_history_entities.dart';
import '../../data/models/business_type_model.dart';

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
  final String? filterBusinessTypeId;
  final String? sortBy;
  final bool hasReachedMax;
  final int currentPage;
  final String? apiMessage; // server feedback message

  const ProductsLoaded({
    required this.products,
    required this.locationId,
    this.searchQuery,
    this.filterStatus,
    this.filterBusinessTypeId,
    this.sortBy,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.apiMessage,
  });

  ProductsLoaded copyWith({
    List<ProductEntity>? products,
    String? locationId,
    String? searchQuery,
    String? filterStatus,
    String? filterBusinessTypeId,
    String? sortBy,
    bool? hasReachedMax,
    int? currentPage,
    String? apiMessage,
  }) {
    return ProductsLoaded(
      products: products ?? this.products,
      locationId: locationId ?? this.locationId,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
      filterBusinessTypeId: filterBusinessTypeId ?? this.filterBusinessTypeId,
      sortBy: sortBy ?? this.sortBy,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      apiMessage: apiMessage, // always overwrite (null clears it)
    );
  }

  @override
  List<Object?> get props => [
    products,
    locationId,
    searchQuery,
    filterStatus,
    filterBusinessTypeId,
    sortBy,
    hasReachedMax,
    currentPage,
    apiMessage,
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

/// Product detail loaded
class ProductDetailLoaded extends ProductState {
  final ProductEntity product;
  final List<ProductSaleItemHistoryEntity> priceHistory;
  final List<ProductStockMovementEntity> stockMovements;
  final int stockMovementsTotalCount;
  final bool isLoadingPriceHistory;
  final bool isLoadingStockMovements;

  const ProductDetailLoaded({
    required this.product,
    this.priceHistory = const [],
    this.stockMovements = const [],
    this.stockMovementsTotalCount = 0,
    this.isLoadingPriceHistory = false,
    this.isLoadingStockMovements = false,
  });

  ProductDetailLoaded copyWith({
    ProductEntity? product,
    List<ProductSaleItemHistoryEntity>? priceHistory,
    List<ProductStockMovementEntity>? stockMovements,
    int? stockMovementsTotalCount,
    bool? isLoadingPriceHistory,
    bool? isLoadingStockMovements,
  }) {
    return ProductDetailLoaded(
      product: product ?? this.product,
      priceHistory: priceHistory ?? this.priceHistory,
      stockMovements: stockMovements ?? this.stockMovements,
      stockMovementsTotalCount:
          stockMovementsTotalCount ?? this.stockMovementsTotalCount,
      isLoadingPriceHistory:
          isLoadingPriceHistory ?? this.isLoadingPriceHistory,
      isLoadingStockMovements:
          isLoadingStockMovements ?? this.isLoadingStockMovements,
    );
  }

  @override
  List<Object?> get props => [
    product,
    priceHistory,
    stockMovements,
    stockMovementsTotalCount,
    isLoadingPriceHistory,
    isLoadingStockMovements,
  ];
}

/// Failure state
class ProductFailure extends ProductState {
  final String message;

  const ProductFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Business types loaded
class BusinessTypesLoaded extends ProductState {
  final List<BusinessTypeDto> businessTypes;

  const BusinessTypesLoaded({required this.businessTypes});

  @override
  List<Object?> get props => [businessTypes];
}
