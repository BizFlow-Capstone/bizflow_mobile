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

  const LoadProductsByLocationRequested({
    required this.locationId,
  });

  @override
  List<Object?> get props => [locationId];
}

/// Refresh products (pull to refresh)
class RefreshProductsRequested extends ProductEvent {
  final String locationId;

  const RefreshProductsRequested({
    required this.locationId,
  });

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

  const SortProductsRequested({
    required this.locationId,
    required this.sortBy,
  });

  @override
  List<Object?> get props => [locationId, sortBy];
}

/// Clear filters
class ClearFiltersRequested extends ProductEvent {
  final String locationId;

  const ClearFiltersRequested({
    required this.locationId,
  });

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
  ];
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
