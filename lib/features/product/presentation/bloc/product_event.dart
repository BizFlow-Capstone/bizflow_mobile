import 'package:equatable/equatable.dart';

/// Product Events
/// Các sự kiện được phát ra từ UI layers
abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

/// Load products by location
class LoadProductsByLocationRequested extends ProductEvent {
  final String locationId;

  const LoadProductsByLocationRequested({required this.locationId});

  @override
  List<Object?> get props => [locationId];
}

/// Refresh products (pull to refresh)
class RefreshProductsRequested extends ProductEvent {
  final String locationId;

  const RefreshProductsRequested({required this.locationId});

  @override
  List<Object?> get props => [locationId];
}

/// Search products
class SearchProductsRequested extends ProductEvent {
  final String locationId;
  final String query;

  const SearchProductsRequested({
    required this.locationId,
    required this.query,
  });

  @override
  List<Object?> get props => [locationId, query];
}

/// Filter products
class FilterProductsRequested extends ProductEvent {
  final String locationId;
  final String? status;
  final String? category;

  const FilterProductsRequested({
    required this.locationId,
    this.status,
    this.category,
  });

  @override
  List<Object?> get props => [locationId, status, category];
}

/// Sort products
class SortProductsRequested extends ProductEvent {
  final String locationId;
  final String sortBy; // 'name', 'price', 'stock', 'date'

  const SortProductsRequested({required this.locationId, required this.sortBy});

  @override
  List<Object?> get props => [locationId, sortBy];
}

/// Clear filters
class ClearFiltersRequested extends ProductEvent {
  final String locationId;

  const ClearFiltersRequested({required this.locationId});

  @override
  List<Object?> get props => [locationId];
}

/// Add new product
class AddProductRequested extends ProductEvent {
  final String locationId;
  final String productName;
  final String? barcode;
  final String? category;
  final double? costPrice;
  final double? salePrice;
  final int? quantity;
  final String? unit;
  final bool isActive;
  final String? description;
  final String? imagePath;
  final List<Map<String, dynamic>>? priceTiers;

  const AddProductRequested({
    required this.locationId,
    required this.productName,
    this.barcode,
    this.category,
    this.costPrice,
    this.salePrice,
    this.quantity,
    this.unit,
    this.isActive = true,
    this.description,
    this.imagePath,
    this.priceTiers,
  });

  @override
  List<Object?> get props => [
    locationId,
    productName,
    barcode,
    category,
    costPrice,
    salePrice,
    quantity,
    unit,
    isActive,
    description,
    imagePath,
    priceTiers,
  ];
}

/// Update product
class UpdateProductRequested extends ProductEvent {
  final String locationId;
  final String productId;
  final String productName;
  final String? barcode;
  final String? category;
  final double? costPrice;
  final double? salePrice;
  final int? quantity;
  final String? unit;
  final bool isActive;
  final String? description;
  final String? imagePath;
  final List<Map<String, dynamic>>? priceTiers;
  final bool removeImage;

  const UpdateProductRequested({
    required this.locationId,
    required this.productId,
    required this.productName,
    this.barcode,
    this.category,
    this.costPrice,
    this.salePrice,
    this.quantity,
    this.unit,
    this.isActive = true,
    this.description,
    this.imagePath,
    this.priceTiers,
    this.removeImage = false,
  });

  @override
  List<Object?> get props => [
    locationId,
    productId,
    productName,
    barcode,
    category,
    costPrice,
    salePrice,
    quantity,
    unit,
    isActive,
    description,
    imagePath,
    priceTiers,
    removeImage,
  ];
}

/// Load product sale items (price tiers)
class LoadProductSaleItemsRequested extends ProductEvent {
  final String productId;

  const LoadProductSaleItemsRequested({required this.productId});

  @override
  List<Object?> get props => [productId];
}

/// Delete product
class DeleteProductRequested extends ProductEvent {
  final String locationId;
  final String productId;

  const DeleteProductRequested({
    required this.locationId,
    required this.productId,
  });

  @override
  List<Object?> get props => [locationId, productId];
}

/// Update product status
class UpdateProductStatusRequested extends ProductEvent {
  final String locationId;
  final String productId;
  final bool isActive;

  const UpdateProductStatusRequested({
    required this.locationId,
    required this.productId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [locationId, productId, isActive];
}

/// Import inventory
class ImportInventoryRequested extends ProductEvent {
  final String locationId;
  final int quantity;
  final String productId;

  const ImportInventoryRequested({
    required this.locationId,
    required this.quantity,
    required this.productId,
  });

  @override
  List<Object?> get props => [locationId, quantity, productId];
}

/// Load more products (pagination)
class LoadMoreProductsRequested extends ProductEvent {
  final String locationId;

  const LoadMoreProductsRequested({required this.locationId});

  @override
  List<Object?> get props => [locationId];
}
