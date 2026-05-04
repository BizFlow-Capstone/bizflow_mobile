import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entity.dart';
import '../../data/models/business_type_model.dart';

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

/// Reset products state (on logout)
class ResetProducts extends ProductEvent {
  const ResetProducts();
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
  final String? businessTypeId;

  const FilterProductsRequested({
    required this.locationId,
    this.status,
    this.businessTypeId,
  });

  @override
  List<Object?> get props => [locationId, status, businessTypeId];
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

/// Load business types
class LoadBusinessTypesRequested extends ProductEvent {
  const LoadBusinessTypesRequested();
}

/// Add new product
class AddProductRequested extends ProductEvent {
  final String locationId;
  final String productName;
  final String? barcode;
  final String? category;
  final double? costPrice;
  final double? salePrice;
  final double? quantity;
  final String? unit;
  final bool trackInventory;
  final bool isActive;
  final String? description;
  final String? imagePath;
  final List<Map<String, dynamic>>? priceTiers;
  final String? businessTypeId;
  final String? manufacturer;

  const AddProductRequested({
    required this.locationId,
    required this.productName,
    this.barcode,
    this.category,
    this.costPrice,
    this.salePrice,
    this.quantity,
    this.unit,
    this.trackInventory = true,
    this.isActive = true,
    this.description,
    this.imagePath,
    this.priceTiers,
    this.businessTypeId,
    this.manufacturer,
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
    trackInventory,
    isActive,
    description,
    imagePath,
    priceTiers,
    businessTypeId,
    manufacturer,
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
  final double? quantity;
  final String? unit;
  final bool trackInventory;
  final bool isActive;
  final String? description;
  final String? imagePath;
  final List<Map<String, dynamic>>? priceTiers;
  final bool removeImage;
  final String? businessTypeId;
  final String? manufacturer;

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
    this.trackInventory = true,
    this.isActive = true,
    this.description,
    this.imagePath,
    this.priceTiers,
    this.removeImage = false,
    this.businessTypeId,
    this.manufacturer,
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
    trackInventory,
    isActive,
    description,
    imagePath,
    priceTiers,
    removeImage,
    businessTypeId,
    manufacturer,
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

class LoadProductDetailRequested extends ProductEvent {
  final String productId;

  const LoadProductDetailRequested({required this.productId});

  @override
  List<Object?> get props => [productId];
}

/// Apply local price changes immediately for better UX,
/// then server refresh can reconcile exact values.
class ApplyLocalPriceAdjustmentRequested extends ProductEvent {
  final String locationId;
  final List<String> affectedProductIds;
  final double deltaAmount;

  const ApplyLocalPriceAdjustmentRequested({
    required this.locationId,
    required this.affectedProductIds,
    required this.deltaAmount,
  });

  @override
  List<Object?> get props => [locationId, affectedProductIds, deltaAmount];
}

/// Event untuk handle business types dari network sync (SWR background update)
class BusinessTypesNetworkDataReceived extends ProductEvent {
  final List<BusinessTypeDto> businessTypes;

  const BusinessTypesNetworkDataReceived({required this.businessTypes});

  @override
  List<Object?> get props => [businessTypes];
}

/// Event untuk handle products dari network sync (SWR background update)  
class ProductsNetworkDataReceived extends ProductEvent {
  final List<ProductEntity> products;
  final String locationId;

  const ProductsNetworkDataReceived({
    required this.products,
    required this.locationId,
  });

  @override
  List<Object?> get props => [products, locationId];
}

/// Event untuk handle product error dari network sync
class ProductNetworkErrorOccurred extends ProductEvent {
  final dynamic error;

  const ProductNetworkErrorOccurred({required this.error});

  @override
  List<Object?> get props => [error];
}

/// Event untuk handle sale items dari network sync (SWR background update)
class ProductSaleItemsNetworkDataReceived extends ProductEvent {
  final List<Map<String, dynamic>> saleItems;

  const ProductSaleItemsNetworkDataReceived({required this.saleItems});

  @override
  List<Object?> get props => [saleItems];
}

/// Event cho handle product detail từ network sync (SWR background update)
class ProductDetailNetworkDataReceived extends ProductEvent {
  final ProductEntity? product;

  const ProductDetailNetworkDataReceived({required this.product});

  @override
  List<Object?> get props => [product];
}

/// Load selling price policy history for a product
class LoadProductPriceHistoryRequested extends ProductEvent {
  final String productId;

  const LoadProductPriceHistoryRequested({required this.productId});

  @override
  List<Object?> get props => [productId];
}

/// Load stock movement history for a product
class LoadProductStockMovementsRequested extends ProductEvent {
  final String productId;
  final int pageNumber;
  final int pageSize;

  const LoadProductStockMovementsRequested({
    required this.productId,
    this.pageNumber = 1,
    this.pageSize = 10,
  });

  @override
  List<Object?> get props => [productId, pageNumber, pageSize];
}

